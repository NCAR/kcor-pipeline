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
function kcor_normalize_datetime, datetime
  compile_opt strictarr

  re = '([[:digit:]]{4})-([[:digit:]]{2})-([[:digit:]]{2})T([[:digit:]]{2}):([[:digit:]]{2}):([[:digit:]]{2})'

  tokens = long(stregex(datetime, re, /extract, /subexpr))

  jd = julday(tokens[2], tokens[3], tokens[1], tokens[4], tokens[5], tokens[6])

  fmt = '(C(CYI, "-", CMOI2.2, "-", CDI2.2, "T", CHI2.2, ":", CMI2.2, ":", CSI2.2))'
  return, string(jd, format=fmt)
end
