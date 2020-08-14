; docformat = 'rst'

;+
; Convert a string time in the form HHMMSS to a decimal number of hours into
; day.
;
; :Returns:
;   float
;
; :Params:
;   time : in, required, type=string
;     time in the form "HHMMSS"
;-
function kcor_decimal_time, time
  compile_opt strictarr

  hour = long(strmid(time, 0, 2))
  minute = long(strmid(time, 2, 2))
  second = long(strmid(time, 4, 2))

  return, hour + (minute + second / 60.0) / 60.0
end
