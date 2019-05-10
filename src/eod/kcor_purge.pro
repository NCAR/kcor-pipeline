; docformat = 'rst'

;+
; Wrapper to be called from kcor script to purge a day for reprocessing.
;
; :Params:
;   date : in, required, type=string
;     date to process in the form "YYYYMMDD"
;
; :Keywords:
;    config_filename : in, required, type=string
;      filename of config file
;-
pro kcor_purge, date, config_filename=config_filename
  compile_opt strictarr

  run = kcor_run(date, config_filename=config_filename)
  kcor_reprocess, date, run=run, error=error
  obj_destroy, run
end
