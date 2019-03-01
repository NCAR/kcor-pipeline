; docformat = 'rst'

function kcor_dutycycle_parsedt, dt
  compile_opt strictarr

  return, long([strmid(dt, 0, 4), $
                strmid(dt, 5, 2), $
                strmid(dt, 8, 2), $
                strmid(dt, 11, 2), $
                strmid(dt, 14, 2), $
                strmid(dt, 17, 2)])
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
  dates       = julday(dts[1], dts[2], dts[0], dts[3], dts[4], dts[5])
  n_images    = days.num_kcor_pb_fits

  start_times = fltarr(n_days)
  end_times   = fltarr(n_days)


  for d = 0L, n_days - 1L do begin
    query = 'select min(date_obs) from kcor_img where obs_day=%d'
    mins = db->query(query, $
                     days[d].day_id, $
                     status=status, error_message=error_message, sql_statement=sql_cmd)
    dt = kcor_dutycycle_parsedt(mins.min_date_obs_[0])
    start_times[d] = julday(dt[1], dt[2], dt[0], dt[3], dt[4], dt[5])

    query = 'select max(date_obs) from kcor_img where obs_day=%d'
    mins = db->query(query, $
                     days[d].day_id, $
                     status=status, error_message=error_message, sql_statement=sql_cmd)
    dt = kcor_dutycycle_parsedt(mins.max_date_obs_[0])
    end_times[d] = julday(dt[1], dt[2], dt[0], dt[3], dt[4], dt[5])
  endfor

  ; cache values in .sav file
  save, dates, start_times, end_times, n_images, filename=cache_filename

  plot_results:

  ; setup plotting
  mg_window, xsize=5, ysize=4, /inches
  !p.multi = [0, 2, 1]

  ; plot date/time vs. length of days
  plot, dates, end_times - start_times, psym=3

  ; plot date/time vs. % of full data
  n_images_per_day = 4 * 60 * 24
  duty_cycle = n_images * (end_times - start_times) / n_images_per_day
  plot, dates, duty_cycle, psym=3

  !p.multi = 0

  ; cleanup
  if (obj_valid(db)) then obj_destroy, db
end


; main-level example program

kcor_dutycycle, '2013-09-30', $
                '2019-12-31', $
                database_config_filename='~/.mysqldb', $
                database_config_section='mgalloy@databases'

end
