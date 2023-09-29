; docformat = 'rst'

;+
; Update "YYYYMMDD.kcor.cme.TYPE.txt" in `list_dir`.
;
; List files look like::
;
;     19:49:29  109.50 deg
;
; :Params:
;   observing_date : in, required, type=string
;     HST date in the form "YYYYMMDD"
;   time : in, required, type=string
;     UT date/time of CME
;   position_angle : in, required, type=float
;     position angle measured CCW from N
;   type : in, required, type=string
;     list type to add to, e.g., "toretract" or "retracted"
;   list_dir : in, required, type=string
;     directory to write/update list file
;-
pro kcor_cme_update_list, observing_date, time, position_angle, type, list_dir
  compile_opt strictarr

  if (~file_test(list_dir, /directory)) then file_mkdir, list_dir

  basename = string(observing_date, type, format='(%"%s.kcor.cme.%s.txt")')
  filename = filepath(basename, root=list_dir)

  openu, lun, filename, /get_lun, /append
  printf, lun, time, position_angle, format='(%"%s  %0.2f deg")'
  free_lun, lun
end

