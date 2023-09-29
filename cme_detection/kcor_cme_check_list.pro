; docformat = 'rst'

;+
; Check "YYYYMMDD.kcor.cme.TYPE.txt" in `list_dir` if CME has already been
; reported.
;
; :Returns:
;   1B if already present, 0B if not
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
function kcor_cme_check_list, observing_date, time, position_angle, type, list_dir
  compile_opt strictarr

  if (n_elements(list_dir) eq 0L) then return, 0B
  if (~file_test(list_dir, /directory)) then return, 0B

  basename = string(observing_date, type, format='(%"%s.kcor.cme.%s.txt")')
  filename = filepath(basename, root=list_dir)

  n_lines = file_lines(filename)
  openr, lun, filename, /get_lun
  current_list = strarr(n_lines)
  readf, lun, current_list
  free_lun, lun

  pa_string = string(position_angle, format='%0.2f')
  for c = 0L, n_lines - 1L do begin
    tokens = strsplit(current_list[c], count=count, /extract)
    if ((tokens[0] eq time) && (tokens[1] eq pa_string)) then return, 1B
  endfor

  return, 0B
end

