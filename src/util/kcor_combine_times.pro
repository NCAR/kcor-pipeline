; docformat = 'rst'

;+
; Join the non-empty strings of an array into a single comma separated string.
;
; :Params:
;   times : in, required, type=strarr
;     an array of times that might have missing entries, i.e., empty strings
;-
function kcor_combine_times, times
  compile_opt strictarr

  time_indices = where(times ne '', count)
  if (count eq 0L) then return, '' else begin
    return, strjoin(times[time_indices], ', ')
  endelse
end
