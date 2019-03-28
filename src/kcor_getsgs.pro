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

    value = sxpar(header, name, count=count)
    if (count eq 0) then return, keyword_set(float) ? !values.f_nan : 'NULL'

    if (keyword_set(float)) then begin
      value = size(value, /type) eq 7 ? !values.f_nan : float(value)
    endif else begin
      value = size(value, /type) eq 7 $
                ? strtrim(value, 2) $
                : string(value, format='(%"%f")')
      if (value eq 'NaN') then value = 'NULL'
    endelse

    return, value
end
