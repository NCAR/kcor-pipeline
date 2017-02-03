; docformat = 'rst'

;+
; Use the first part of the filename to determine the name of the processing
; and raw directory names. Must consider UT midnight boundary.
;
; :Returns:
;   string
;
; :Params:
;   filename : in, required, type=string
;     filename to obtain date from
;
; :Author:
;   sitongia
;-
function kcor_get_date_dir, filename
  compile_opt strictarr

  date_dir = strmid(filename, 0, 8)
  time = strmid(filename, 9, 6)
  hour = long(strmid(filename,9,2))

  ; subtract a day if this is after midnight UT
  if (hour lt 10) then begin
    year  = long(strmid(date_dir, 0, 4))
    month = long(strmid(date_dir, 4, 2))
    day   = long(strmid(date_dir, 6, 2))

    jd = julday(month, day, year)
    jd -= 1
    caldat, jd, nextmonth, nextday, nextyear

    nextyear  = string(nextyear, format='(I4)')
    nextmonth = string(nextmonth, format='(I02)')
    nextday   = string(nextday, format='(I02)')
    date_dir  = string(nextyear) + string(nextmonth) + string(nextday)
  endif
  
  return, date_dir
end


; main-level test program

dir = kcor_get_date_dir('20131222_021234_kcor.fts.gz')
print, dir

end