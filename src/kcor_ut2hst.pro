; docformat = 'rst'

;+
; Convert UT to HST time.
;
; :Returns:
;   string in the form "HHMMSS"
;
; :Params:
;   time : in, required, type=string
;     UT time as string in the form "HHMMSS"
;-
function kcor_ut2hst, time
  compile_opt strictarr

  hour   = strmid(time, 0, 2)
  minute = strmid(time, 2, 2)
  second = strmid(time, 4, 2)

  return, string((long(hour) - 10L + 24L) mod 24, minute, second, $
                 format='(%"%02d%s%s")')
end


; main-level example program

time = '133430'
help, time
hst = kcor_ut2hst(time)
help, hst

end

