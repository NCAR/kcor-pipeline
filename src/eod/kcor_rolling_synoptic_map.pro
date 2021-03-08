; docformat = 'rst'

;+
; Create a synoptic plot for the last 28 days.
; 
; :Keywords:
;   database : in, required, type=object
;     database connection
;   run : in, required, type=object]
;     KCor run object
;-
pro kcor_rolling_synoptic_map, database=db, run=run
  compile_opt strictarr

  n_days = 28   ; number of days to include in the plot
  logger_name = run.logger_name

  ;logger_name = run.logger_name
  mg_log, 'producing synoptic plot of last %d days', n_days, $
          name=logger_name, /info

  ; query database for data
  end_date_tokens = long(kcor_decompose_date(run.date))
  end_date = string(end_date_tokens, format='(%"%04d-%02d-%02d")')
  end_date_jd = julday(end_date_tokens[1], $
                       end_date_tokens[2], $
                       end_date_tokens[0], $
                       0, 0, 0)
  start_date_jd = end_date_jd - n_days + 1
  start_date = string(start_date_jd, $
                      format='(C(CYI4.4, "-", CMoI2.2, "-", CDI2.2))')

  query = 'select kcor_sci.* from kcor_sci, mlso_numfiles where kcor_sci.obs_day=mlso_numfiles.day_id and mlso_numfiles.obs_day between ''%s'' and ''%s'''
  raw_data = db->query(query, start_date, end_date, $
                       count=n_rows, error=error, fields=fields)

  if (n_rows gt 0L) then begin
    mg_log, '%d dates between %s and %s', n_rows, start_date, end_date, $
            name=logger_name, /debug
  endif else begin
    mg_log, 'no data found between %s and %s', start_date, end_date, $
            name=logger_name, /warn
    goto, done
  endelse

  ; organize data
  radius = 1.3
  data = raw_data.r13

  dates = raw_data.date_obs
  n_dates = n_elements(dates)

  map = fltarr(n_days, 720) + !values.f_nan
  means = fltarr(n_days) + !values.f_nan
  for r = 0L, n_dates - 1L do begin
    decoded = *data[r]
    if (n_elements(decoded) gt 0L) then begin
      *data[r] = float(*data[r], 0, 720)   ; decode byte data to float
    endif

    date = dates[r]
    date_index = mlso_dateobs2jd(date) - start_date_jd - 10.0/24.0
    date_index = floor(date_index)

    if (ptr_valid(data[r]) && n_elements(*data[r]) gt 0L) then begin
      map[date_index, *] = *data[r]
      means[date_index] = mean(*data[r])
    endif else begin
      map[date_index, *] = !values.f_nan
      means[date_index] = !values.f_nan
    endelse
  endfor

  ; plot data
  set_plot, 'Z'
  device, set_resolution=[(30 * n_days + 50) < 1200, 800]
  original_device = !d.name

  device, get_decomposed=original_decomposed
  tvlct, rgb, /get
  device, decomposed=0

  range = mg_range(map)
  if (range[0] lt 0.0) then begin
    minv = 0.0
    maxv = range[1]

    loadct, 0, /silent
    foreground = 0
    background = 255
  endif else begin
    minv = 0.0
    maxv = range[1]

    loadct, 0, /silent
    foreground = 0
    background = 255
  endelse

  north_up_map = shift(map, 0, -180)
  east_limb = reverse(north_up_map[*, 0:359], 2)
  west_limb = north_up_map[*, 360:*]

  !null = label_date(date_format='%D %M %Z')
  jd_dates = dblarr(n_dates)
  for d = 0L, n_dates - 1L do jd_dates[d] = mlso_dateobs2jd(dates[d])

  charsize = 1.0
  smooth_kernel = [11, 1]

  title = string(start_date, end_date, $
                 format='(%"Synoptic map for r1.3 from %s to %s")')
  erase, background
  mg_image, reverse(east_limb, 1), reverse(jd_dates), $
            xrange=[end_date_jd, start_date_jd], $
            xtyle=1, xtitle='Date (not offset for E limb)', $
            min_value=minv, max_value=maxv, $
            /axes, yticklen=-0.005, xticklen=-0.01, $
            color=foreground, background=background, $
            title=string(title, format='(%"%s (East limb)")'), $
            xtickformat='label_date', $
            position=[0.05, 0.55, 0.97, 0.95], /noerase, $
            yticks=4, ytickname=['S', 'SE', 'E', 'NE', 'N'], yminor=4, $
            smooth_kernel=smooth_kernel, $
            charsize=charsize
  mg_image, reverse(west_limb, 1), reverse(jd_dates), $
            xrange=[end_date_jd, start_date_jd], $
            xstyle=1, xtitle='Date (not offset for W limb)', $
            min_value=minv, max_value=maxv, $
            /axes, yticklen=-0.005, xticklen=-0.01, $
            color=foreground, background=background, $
            title=string(title, format='(%"%s (West limb)")'), $
            xtickformat='label_date', $
            position=[0.05, 0.05, 0.97, 0.45], /noerase, $
            yticks=4, ytickname=['S', 'SW', 'W', 'NW', 'N'], yminor=4, $
            smooth_kernel=smooth_kernel, $
            charsize=charsize

  xyouts, 0.97, 0.485, /normal, alignment=1.0, $
          string(minv, maxv, format='(%"min/max: %0.3g, %0.3g")'), $
          charsize=charsize, color=128

  im = tvrd()

  p_dir = filepath('p', subdir=run.date, root=run->config('processing/raw_basedir'))
  if (~file_test(p_dir, /directory)) then file_mkdir, p_dir

  output_filename = filepath(string(run.date, $
                                    100.0 * 1.3, $
                                    format='(%"%s.kcor.28day.synoptic.r%03d.gif")'), $
                             root=p_dir)
  write_gif, output_filename, im, rgb[*, 0], rgb[*, 1], rgb[*, 2]

  mkhdr, primary_header, map, /extend
  sxdelpar, primary_header, 'DATE'
  sxaddpar, primary_header, 'DATE-OBS', start_date, $
            ' [UTC] start date of synoptic map', after='EXTEND'
  sxaddpar, primary_header, 'DATE-END', end_date, $
            ' [UTC] end date of synoptic map', $
            format='(F0.2)', after='DATE-OBS'
  sxaddpar, primary_header, 'HEIGHT', radius, $
            ' [Rsun] height of annulus +/- 0.02 Rsun', $
            format='(F0.2)', after='DATE-END'

  fits_filename = filepath(string(run.date, $
                                  100.0 * radius, $
                                  format='(%"%s.kcor.28day.synoptic.r%03d.fts")'), $
                           root=p_dir)
  writefits, fits_filename, map, primary_header

  ; clean up
  done:
  if (n_elements(rgb) gt 0L) then tvlct, rgb
  if (n_elements(original_decomposed) gt 0L) then device, decomposed=original_decomposed
  if (n_elements(original_device) gt 0L) then set_plot, original_device

  for d = 0L, n_elements(data) - 1L do begin
    s = raw_data[d]
    ptr_free, s.intensity, s.intensity_stddev, s.r108, s.r13, s.r18, s.r111
  endfor

  mg_log, 'done', name=logger_name, /info
end


; main-level example program

date = '20201105'
config_filename = filepath('kcor.reprocess.cfg', $
                           subdir=['..', '..', 'config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)
db = kcordbmysql()
db->connect, config_filename=run->config('database/config_filename'), $
             config_section=run->config('database/config_section')

kcor_rolling_synoptic_map, database=db, run=run

obj_destroy, [db, run]

end
