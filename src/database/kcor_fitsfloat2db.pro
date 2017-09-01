; docformat = 'rst'

;+
; Convert a nominally float value from a FITS keyword to a string to be inserted
; into the database.
;
; :Returns:
;   string
;
; :Params:
;   value : in, required, type=float/string
;     value to convert
;-
function kcor_fitsfloat2db, value
  compile_opt strictarr
  on_ioerror, io_problem

  if (size(value, /type) eq 7) then begin
    return, strtrim(float(value), 2)
  endif else begin
    return, string(value, format='(%"%f")')
  endelse

  io_problem:
  return, 'NULL'
end
