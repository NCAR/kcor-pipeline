; docformat = 'rst'

;+
; Decompose a time string into hours, minutes, seconds.
;
; :Returns:
;   `strarr(3)`
;
; :Params:
;   time : in, required, type=string
;     time in the form "110425"
;-
function kcor_decompose_time, time
  compile_opt strictarr

  hours = strmid(time, 0, 2)
  minutes = strmid(time, 2, 2)
  seconds = strmid(time, 4, 2)

  result = [hours, minutes, seconds]
  if (n_elements(time) gt 1L) then begin
    result = transpose(reform(result, n_elements(time), 3))
  endif

  return, result
end
