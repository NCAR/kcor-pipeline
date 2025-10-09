; docformat = 'rst'

;+
; Convert a DATE-OBS value like "2018-03-06 17:50:20" to Julian date.
;
; :Returns:
;   double
;
; :Params:
;   date_obs : in, required, type=string
;     DATE-OBS in the form YYYY-MM-DD HH:MM:SS or YYYY-MM-DD
;-
function mlso_dateobs2jd, date_obs
  compile_opt strictarr

  year   = long(strmid(date_obs, 0, 4))
  month  = long(strmid(date_obs, 5, 2))
  day    = long(strmid(date_obs, 8, 2))

  if (strlen(date_obs) gt 10) then begin
    hour   = long(strmid(date_obs, 11, 2))
    minute = long(strmid(date_obs, 14, 2))
    second = long(strmid(date_obs, 17, 2))
  endif else begin
    hour = 0L
    minute = 0L
    second = 0L
  endelse

  return, julday(month, day, year, hour, minute, second)
end


; main-level example program

date_obs = '2018-03-06 17:50:20'
print, date_obs
print, mlso_dateobs2jd(date_obs)

end
