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
pro kcor_find_badlines, date, config_filename=config_filename
  compile_opt strictarr

  run = kcor_run(date, config_filename=config_filename, mode='badlines')
  kcor_detect_badlines, run=run
  kcor_median_rowcol_image, run=run
  obj_destroy, run
end
