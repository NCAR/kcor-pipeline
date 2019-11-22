; docformat = 'rst'

function kcor_dutycycle_parsedt, dt
  compile_opt strictarr

  return, long([[strmid(dt, 0, 4)], $
                [strmid(dt, 5, 2)], $
                [strmid(dt, 8, 2)], $
                [strmid(dt, 11, 2)], $
                [strmid(dt, 14, 2)], $
                [strmid(dt, 17, 2)]])
end


pro kcor_dutycycle, start_date, end_date, $
                    database_config_filename=database_config_filename, $
                    database_config_section=database_config_section
  compile_opt strictarr

  cache_filename = 'duty-cycle-info.sav'

  ; if cache .sav file not present, check database
  if (file_test(cache_filename, /regular)) then begin
    restore, filename=cache_filename
    goto, plot_results
  endif

  ; connect to database
  db = mgdbmysql()
  db->connect, config_filename=database_config_filename, $
               config_section=database_config_section
  db->getProperty, host_name=host
  mg_log, 'connected to %s', host, /info

  ; find observing days with >0 KCor images

  query = 'select * from mlso_numfiles where num_kcor_pb_fits>0 and mlso_numfiles.obs_day between ''%s'' and ''%s'''
  days = db->query(query, $
                   start_date, end_date, $
                   status=status, error_message=error_message, sql_statement=sql_cmd)
  n_days = n_elements(days)
  mg_log, 'found %d days between %s and %s', n_days, start_date, end_date, /info

  dts         = kcor_dutycycle_parsedt(days.obs_day)
  dates       = julday(dts[*, 1], dts[*, 2], dts[*, 0], dts[*, 3], dts[*, 4], dts[*, 5])
  n_images    = days.num_kcor_pb_fits

  start_times = dblarr(n_days)
  end_times   = dblarr(n_days)

  for d = 0L, n_days - 1L do begin
    query = 'select min(date_obs) from kcor_img where obs_day=%d and producttype=1'
    mins = db->query(query, $
                     days[d].day_id, $
                     status=status, error_message=error_message, sql_statement=sql_cmd)
    dt = kcor_dutycycle_parsedt(mins.min_date_obs_[0])
    start_times[d] = julday(dt[1], dt[2], dt[0], dt[3], dt[4], dt[5])

    query = 'select max(date_obs) from kcor_img where obs_day=%d and producttype=1'
    mins = db->query(query, $
                     days[d].day_id, $
                     status=status, error_message=error_message, sql_statement=sql_cmd)
    dt = kcor_dutycycle_parsedt(mins.max_date_obs_[0])
    end_times[d] = julday(dt[1], dt[2], dt[0], dt[3], dt[4], dt[5])

    ;mg_log, 'start: %0.5f, end: %0.5f', start_times[d], end_times[d], /debug
  endfor

  ; remove
  ind = where(24.0 * 60.0 * 60.0 * (end_times - start_times) gt 1.0, count)
  mg_log, 'keeping %d dates', count, /info
  dates = dates[ind]
  start_times = start_times[ind]
  end_times = end_times[ind]
  n_images = n_images[ind]

  ; sort by date
  ind = sort(dates)
  dates = dates[ind]
  start_times = start_times[ind]
  end_times = end_times[ind]
  n_images = n_images[ind]

  query = 'select date_obs from kcor_img where date_obs between ''%s'' and ''%s'''
  images = db->query(query, start_date, end_date, $
                     status=status, $
                     error_message=error_message, $
                     sql_statement=sql_cmd)
  mg_log, 'found %d images between %s and %s', $
          n_elements(images), start_date, end_date, /info
  dts    = kcor_dutycycle_parsedt(images.date_obs)
  times  = dts[*, 3] + (dts[*, 4] + dts[*, 5] / 60.0) / 60.0

  ; cache values in .sav file
  save, dates, start_times, end_times, n_images, times, filename=cache_filename

  plot_results:

  ; setup plotting
  use_ps = 1B

  if (keyword_set(use_ps)) then begin
    basename = 'duty-cycle'
    mg_psbegin, filename=basename + '.ps', /color, bits_per_pixel=8, $
                xsize=10.0, ysize=8.0, /inches, /landscape, xoffset=0.0
    charsize = 1.0
    font = 1
  endif else begin
    mg_window, xsize=9, ysize=8, /inches, /free
    charsize = 1.5
    font = 1
  endelse

  mg_decomposed, 1, old_decomposed=odec

  !p.multi = [0, 1, 2]

  !null = label_date(date_format='%M %Y')

  ; plot date/time vs. length of days
  plot, dates, 24.0 * (end_times - start_times), $
        psym=3, font=font, charsize=charsize, title='Length of observing days', $
        xstyle=1, xtitle='dates', xtickformat='label_date', $
        ystyle=1, yrange=[0.0, 12.0], ytitle='hours'

  ; plot date/time vs. % of full data
  n_images_per_day = 4 * 60 * 24
  duty_cycle = 100.0 * n_images / (end_times - start_times) / n_images_per_day
  plot, dates, duty_cycle, $
        psym=3, font=font, charsize=charsize, title='Percentage of day with images', $
        xstyle=1, xtitle='dates', xtickformat='label_date', $
        ystyle=1, yrange=[0.0, 100.0], ytitle='% observing'

  !p.multi = 0

  if (keyword_set(use_ps)) then begin
    mg_psend
  endif

  if (keyword_set(use_ps)) then begin
    basename = 'duty-cycle-histogram'
    mg_psbegin, filename=basename + '.ps', /color, bits_per_pixel=24, $
                xsize=8.0, ysize=10.5, /inches, /portrait
    charsize = 1.0
    font = 1
    axis_color = '000000'x
    fill_color = 'a06020'x
  endif else begin
    mg_window, xsize=9, ysize=12, /inches, /free
    charsize = 2.5
    font = 1
    axis_color = 'ffffff'x
    fill_color = '808080'x
  endelse

  !p.multi = [0, 1, 3]

  nbins = 48

  h = histogram(24.0 * (end_times - start_times), $
                min=0.0, max=12.0, nbins=nbins, $
                locations=bins)
  mg_histplot, bins, h, $
               ticklen=-0.01, font=font, charsize=charsize, $
               /fill, color=fill_color, axis_color=axis_color, $
               xstyle=1, xtitle='hours', $
               ytitle='number of days', $
               title=string(dates[0], dates[-1], $
                            format='("Length of observing day of KCor (time between first and last good image) [", C(CYI04, "-", CMOI02, "-", CDI02), " to ", C(CYI04, "-", CMOI02, "-", CDI02), "]")')

  h = histogram(24.0 * n_images / n_images_per_day, $
                min=0.0, max=12.0, nbins=nbins, $
                locations=bins)
  mg_histplot, bins, h, $
               ticklen=-0.01, font=font, charsize=charsize, $
               /fill, color=fill_color, axis_color=axis_color, $
               xstyle=1, xtitle='hours', $
               ytitle='number of days', $
               title=string(dates[0], dates[-1], $
                            format='("Length of observed day (number of hours taking good images) [", C(CYI04, "-", CMOI02, "-", CDI02), " to ", C(CYI04, "-", CMOI02, "-", CDI02), "]")')

  times = (times - 10.0 + 24.0) mod 24.0
  h = histogram(times, min=6.0, max=20.0, nbins=14*4, locations=bins)
  mg_histplot, bins, h, $
               ticklen=-0.01, font=font, charsize=charsize, $
               /fill, color=fill_color, axis_color=axis_color, $
               xstyle=1, xtitle='time of day (HST)', $
               ytitle='number of images', $
               title=string(dates[0], dates[-1], $
                            format='("Images acquired by time of day [", C(CYI04, "-", CMOI02, "-", CDI02), " to ", C(CYI04, "-", CMOI02, "-", CDI02), "]")')

  !p.multi = 0

  if (keyword_set(use_ps)) then begin
    mg_psend
  endif

  device, decomposed=odec

  ; cleanup
  if (obj_valid(db)) then obj_destroy, db
end


; main-level example program

kcor_dutycycle, '2013-09-30', $
                '2019-12-31', $
                database_config_filename='~/.mysqldb', $
                database_config_section='mgalloy@databases'

restore, filename='duty-cycle-info.sav'
t = mg_table()
caldat, dates, months, days, years, hours, minutes, seconds
dates_string = string(years, format='(I04)') $
                 + string(months, format='(I02)') $
                 + string(days, format='(I02)')
t['date'] = dates_string
t['n_images'] = n_images 
t['length'] = 24.0 * (end_times - start_times)
n_images_per_day = 4 * 60 * 24
t['duty_cycle'] = 100.0 * n_images / (end_times - start_times) / n_images_per_day
t.n_rows_to_print = 1500

end
