; docformat = 'rst'

;+
; Convert a DATE-OBS keyword value to a Julian date/time.
;
; :Returns:
;   Julian time as double
;
; :Params:
;   dateobs : in, required, type=string
;     DATE-OBS value in the form "YYYY-MM-DDTHH:MM:SS" such as
;     '2020-08-14T02:21:55'
;-
function kcor_dateobs2julian, dateobs
  compile_opt strictarr

  year   = long(strmid(dateobs, 0, 4))
  month  = long(strmid(dateobs, 5, 2))
  day    = long(strmid(dateobs, 8, 2))
  hour   = long(strmid(dateobs, 11, 2))
  minute = long(strmid(dateobs, 14, 2))
  second = long(strmid(dateobs, 17, 2))

  if (year eq 0L) then return, !values.f_nan

  return, julday(month, day, year, hour, minute, second)
end
