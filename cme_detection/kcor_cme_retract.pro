; docformat = 'rst'

;+
; Retract a CME, i.e., add a CME to the retracted list and other associated
; actions.

; :Params:
;   observing_date : in, required, type=string
;     HST date in the form "YYYYMMDD"
;   time : in, required, string
;     UT date/time of CME
;   position_angle : in, required, type=float
;     position angle measured CCW from N
;   list_dir : in, required, type=string
;     directory to write/update list file
;-
pro kcor_cme_retract, observing_date, time, position_angle, list_dir
  compile_opt strictarr

  ; add to retracted CME list file
  kcor_cme_update_list, observing_date, time, position_angle, 'retracted', list_dir

  ; TODO: send email retracting CME
  ; TODO: send JSON alert to alerts dir and alerts FTP URL
end

