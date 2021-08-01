; docformat = 'rst'

;+
; Produce plot of the lag in the realtime pipeline, i.e., the time between the
; data observation and when the calibrated product hits the website (also, shows
; when the data was processed).
;
; :Keywords:
;   run : in, required, type=object
;     KCor run object
;-
pro kcor_realtime_lag, run=run
  compile_opt strictarr

  if (run->config('realtime/reprocess')) then begin
    mg_log, 'reprocessing, skipping realtime lag check', name=run.logger_name, /info
    goto, done
  endif

  obs_day_num = mlso_obsday_insert(run.date, $
                                   run=run, $
                                   log_name='kcor/eod', $
                                   database=db, $
                                   status=status)

  product_type = db->query('select * from mlso_producttype where producttype = "pB"', $
                           status=status)
  product_type = product_type[0].producttype_id

  files = db->query('select * from kcor_img where obs_day=%d and producttype=%d', $
                    obs_day_num, product_type, $
                    status=status, count=n_files)
  obj_destroy, db
  if (n_files eq 0L) then goto, done

  l2_dir = filepath('level2', $
                    subdir=run.date, $
                    root=run->config('processing/raw_basedir'))

  creation_time = dblarr(n_files)
  process_time = dblarr(n_files)
  web_time = dblarr(n_files)

  for f = 0L, n_files - 1L do begin
    filename = filepath(files[f].file_name + '.gz', $
                        subdir=[], $
                        root=l2_dir)
    header = headfits(filename)
    date_obs = sxpar(header, 'DATE-OBS')
    date_dp = sxpar(header, 'DATE_DP')
    date_web = files[f].dt_created

    ; print, date_obs, date_dp, date_web, format='(%"%s   %s   %s")'

    creation_time[f] = kcor_dateobs2julian(date_obs)
    process_time[f]  = kcor_dateobs2julian(date_dp)
    web_time[f]      = kcor_dateobs2julian(date_web) - mg_utoffset() / 24.0
    ; print, date_obs, $
    ;        24.0 * 60.0 * (process_time[f] - creation_time[f]), $
    ;        24.0 * 60.0 * (web_time[f] - creation_time[f]), $
    ;        format='(%"date-obs: %s, process lag: %0.1f min, web lag: %0.1f min")'
  endfor

  process_lag = process_time - creation_time
  web_lag = web_time - creation_time

  original_device = !d.name

  set_plot, 'Z'
  device, get_decomposed=original_decomposed
  tvlct, original_rgb, /get
  device, set_resolution=[700, 400], $
          decomposed=0, $
          set_colors=256, $
          z_buffering=0
  loadct, 0, /silent

  date_parts = long(kcor_decompose_date(run.date))
  start_hour = 6    ; local time
  end_hour   = 18   ; local time
  start_time = julday(date_parts[1], date_parts[2], date_parts[0], start_hour, 0, 0) + 10.0D / 24.0D
  end_time = julday(date_parts[1], date_parts[2], date_parts[0], end_hour, 0, 0) + 10.0D / 24.0D
  n_hours = ceil(24.0 * max([web_lag, process_lag], /nan))
  !null = label_date(date_format='%H:%I')
  plot, creation_time, 24.0 * 60.0 * (web_time - creation_time), $
        psym=4, symsize=0.25, $
        color=0, background=255, $
        xstyle=1, xrange=[start_time, end_time], xticks=(end_hour - start_hour) / 2, xminor=2, $
        xtickformat='label_date', xtitle='Observation time [UT]', $
        yrange=[0.0, 60.0 * n_hours], ystyle=1, yticks=n_hours, yminor=6, $
        ytitle='Lag [minutes]', $
        title='Lag from data observation'
  oplot, creation_time, 24.0 * 60.0 * (process_lag), $
         psym=3, symsize=0.25, color=128

  im = tvrd()

  lag_basename = string(run.date, format='(%"%s.kcor.rt-lag.gif")')
  raw_basedir = run->config('processing/raw_basedir')
  p_dir = filepath('p', subdir=run.date, root=raw_basedir)
  if (~file_test(p_dir, /directory)) then file_mkdir, p_dir
  lag_filename = filepath(lag_basename, root=p_dir)
  write_gif, lag_filename, im

  done:
  if (n_elements(original_rgb) gt 0L) then tvlct, original_rgb
  if (n_elements(original_decomposed) gt 0L) then device, decomposed=original_decomposed
  if (n_elements(original_device) gt 0L) then set_plot, original_device
end


; main-level example program
; .compile ../database/mlso_obsday_insert
; .compile ../kcor_dateobs2julian
; .compile ../../lib/mysql/mgdbmysql__define

date = '20210714'
config_filename = filepath('kcor.production.cfg', $
                           subdir=['..', '..', 'config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)
kcor_realtime_lag, run=run
obj_destroy, run

end
