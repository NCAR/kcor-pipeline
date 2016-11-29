;+
; :Description:
;    Generate a string containing today's date.
;
;
;
;
;
; :Author: sitongia
;-
function datecal

  month_name = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', $
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
  today = SYSTIME(/UTC)
  month = strmid(today,4,3)
  month = where(month EQ month_name, count) + 1
  if count eq 0 then begin
    print, 'WARNING! demod: month string wrong'
  endif
  month = month[0]
  month = string(month)
  month = strmid(month,10,2)
  day = strmid(today,8,2)
  year = strmid(today,20,4)
  datecal = year + '-' + month + '-' + day
  ; Change spaces to zeros
  for n=0,strlen(datecal) do begin
    char = strmid(datecal,n,1)
    if (char EQ ' ') then strput,datecal,'0',n
  endfor
  
  return, datecal
end