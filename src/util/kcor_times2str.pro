; docformat = 'rst'

;+
; Create nicely formatted strings for a given decimal hour time. Could give a
; time at 24:00:00 or later, meaning the next day.
;
; :Returns:
;   string/strarr
;
; :Params:
;   times : in, required, type=fltarr
;     decimal times in 0.0 to 24.0
;
; :Author:
;   MLSO Software Team
;-
function kcor_times2str, times
  compile_opt strictarr

  _times = double(times)

  hours = floor(_times)
  minutes = floor(60 * (_times - hours))
  seconds = round(60 * 60 * (_times - hours - minutes / 60.0D))

  hours = string(hours, format='(%"%02d")')
  minutes = string(minutes, format='(%"%02d")')
  seconds = string(seconds, format='(%"%02d")')

  seconds_toobig = where(seconds ge 60L, seconds_count)
  if (seconds_count gt 0L) then begin
    seconds[seconds_toobig] -= 60L
    minutes[seconds_toobig] += 1L
  endif

  minutes_toobig = where(minutes ge 60L, minutes_count)
  if (minutes_count ge 60L) then begin
    minutes[minutes_toobig] -= 60L
    hours[minutes_toobig] += 1L
  endif

  return, hours + ':' + minutes + ':' + seconds
end
