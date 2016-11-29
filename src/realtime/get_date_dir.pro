;+
; :Description:
;    Use the first part of the filename to determine the name of the
;    processing and raw directory names.  Must consider UT midnight boundary.
;
; :Params:
;    filename
;
;
;
; :Author: sitongia
;-
function get_date_dir, filename

;  result = strsplit(filename,'_',/EXTRACT)
;  date_dir = result[0]
;  time = result[1]
  
  date_dir = strmid(filename,0,8)
  time = strmid(filename,9,6)
  hour = fix(strmid(filename,9,2))
    
  ; Subtract a day if this is after midnight UT
  if hour lt 10 then begin
    year = fix(strmid(date_dir,0,4))
    month = fix(strmid(date_dir,4,2))
    day = fix(strmid(date_dir,6,2))
    jd = julday(month, day, year)
    jd -= 1
    caldat, jd, nextmonth, nextday, nextyear
    nextyear = string(nextyear, FORMAT='(I4)')
    nextmonth = string(nextmonth, FORMAT='(I02)')
    nextday = string(nextday, FORMAT='(I02)')
    date_dir = string(nextyear) + string(nextmonth) + string(nextday)
  endif
  
  return, date_dir
end

; Test
dir = get_date_dir('20131222_021234_kcor.fts.gz')
print, dir
end