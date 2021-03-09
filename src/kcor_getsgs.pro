; docformat = 'rst'

;+
; Retrieve an SGS FITS keyword from a FITS header. Returns 'NULL' if the keyword
; is not present or if the value is 'NaN'.
;
; :Returns:
;   string, or float if `FLOAT` is set
;
; :Params:
;   header : in, required, type=string
;     FITS header
;   name : in, required, type=string
;     FITS keyword name
;
; :Keywords:
;   float : in, optional, type=boolean
;     set to return the float value of the FITS keyword
;-
function kcor_getsgs, header, name, float=float
  compile_opt strictarr

    value = fxpar(header, name, count=count, /null)
    type = size(value, /type)
    if (count eq 0 || n_elements(value) eq 0L) then begin
      return, keyword_set(float) ? !values.f_nan : 'NULL'
    endif

    if (keyword_set(float)) then begin
      if (type eq 5) then value = float(value)
      if (type eq 7) then value = !values.f_nan
    endif else begin
      if (type eq 4 || type eq 5) then begin
        value = string(value, format='(%"%f")')
      endif else begin
        value = strtrim(value, 2)
      endelse
    endelse

    return, value
end
