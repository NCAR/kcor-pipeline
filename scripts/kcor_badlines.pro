; docformat = 'rst'

;+
; Find bad lines in a day's raw images.
;
; :Params:
;   date : in, required, type=string
;     date in the form YYYYMMDD
;
; :Keywords:
;   config_filename : in, required, type=string
;     config filename
;-
pro kcor_badlines, date, config_filename=config_filename
  compile_opt strictarr

  run = kcor_run(date, config_filename=config_filename, mode='badlines')

  mg_log, 'starting bad lines for %d', date, name=run.logger_name, /info
  mg_log, 'bad lines diff threshold: %0.1f', run->epoch('badlines_diff_threshold'), $
          name=run.logger_name, /info

  mg_log, 'raw basedir: %s', run->config('processing/raw_basedir'), $
          name=run.logger_name, /info
  kcor_detect_badlines, run=run

  obj_destroy, run
end
