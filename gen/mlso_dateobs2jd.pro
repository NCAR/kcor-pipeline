; docformat = 'rst'

;+
; Convert a DATE-OBS value like "2018-03-06 17:50:20" to Julian date.
;
; :Returns:
;   double
;
; :Params:
;   date_obs : in, required, type=string
;     DATE-OBS in the form YYYY-MM-DD HH:MM:SS
;-
function mlso_dateobs2jd, date_obs
  compile_opt strictarr

  year   = strmid(date_obs, 0, 4)
  month  = strmid(date_obs, 5, 2)
  day    = strmid(date_obs, 8, 2)

  hour   = strmid(date_obs, 11, 2)
  minute = strmid(date_obs, 14, 2)
  second = strmid(date_obs, 17, 2)

  return, julday(month, day, year, hour, minute, second)
end


; main-level example program

date_obs = '2018-03-06 17:50:20'
print, date_obs
print, mlso_dateobs2jd(date_obs)

end
