; docformat = 'rst'

;+
; Wrapper to be called from kcor script to remove the raw directory for a day.
;
; :Params:
;   date : in, required, type=string
;     date to process in the form "YYYYMMDD"
;
; :Keywords:
;    config_filename : in, required, type=string
;      filename of config file
;-
pro kcor_remove, date, config_filename=config_filename
  compile_opt strictarr

  run = kcor_run(date, config_filename=config_filename)

  ; TODO: do steps for issue #101, 2nd part
  ; - remove level1 dir in raw dir

  obj_destroy, run
end
