; docformat = 'rst'

;+
; Wrapper to call `kcor_archive_l1`.
;
; :Params:
;   date : in, required, type=string
;     date in the form 'YYYYMMDD'
;
; :Keywords:
;   config_filename : in, required, type=string
;     filename of config file
;-
pro kcor_archive_l1_wrapper, date, config_filename=config_filename
  compile_opt strictarr

  run = kcor_run(date, config_filename=config_filename)
  kcor_archive_l1, run=run
  obj_destroy, run
end
