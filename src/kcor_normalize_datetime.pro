; docformat = 'rst'

;+
; Normalize dates of the form YYYY-MM-DDTHH:MM:SS.
;
; L0 date/times can have MM = 60, which is invalid and, in particular, causes
; MySQL to put a zero value in for the time.
;
; :Returns:
;   string of date in the same form YYYY-MM-DDTHH:MM:SS
;
; :Params:
;   datetime : in, required, type=string
;     date of the form YYYY-MM-DDTHH:MM:SS
;-
function kcor_normalize_datetime, datetime, error=error
  compile_opt strictarr

  error = 0L
  re = '([[:digit:]]{4})-([[:digit:]]{2})-([[:digit:]]{2})T([[:digit:]]{2}):([[:digit:]]{2}):([[:digit:]]{2})'

  tokens = stregex(datetime, re, /extract, /subexpr)
  dt_comp = long(tokens[1:*])
  !null = where(dt_comp eq 0 and [1, 1, 1, 0, 0, 0], n_null)
  if (n_null gt 0) then begin
    error = 1L
    return, ''
  endif

  jd = julday(dt_comp[1], dt_comp[2], dt_comp[0], dt_comp[3], dt_comp[4], dt_comp[5])

  fmt = '(C(CYI, "-", CMOI2.2, "-", CDI2.2, "T", CHI2.2, ":", CMI2.2, ":", CSI2.2))'
  return, string(jd, format=fmt)
end
