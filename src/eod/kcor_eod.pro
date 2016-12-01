; docformat = 'rst'

;+
; Main end-of-day routine.
;
; :Params:
;   date : in, required, type=date
;     date in the form 'YYYYMMDD' to produce calibration for
;
; :Keywords:
;   config_filename : in, required, type=string
;     filename of configuration file
;-
pro kcor_eod, date, config_filename=config_filename
  compile_opt strictarr

  run = kcor_run(date, config_filename=config_filename)

  ; TODO: kcorp
  ; TODO: kcor_plotcen
  ; TODO: dokcor_catalog

  ; put results in database
  kcor_cal_insert, date, run=run
  kcor_dp_insert, date, run=run
  kcor_eng_insert, date, run=run
  kcor_hw_insert, date, run=run
  kcor_img_insert, date, run=run
  kcor_mission_insert, date, run=run

  obj_destroy, run
end
