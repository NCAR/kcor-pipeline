; docformat = 'rst'

;+
; Generate a string containing today's date.
;
; :Author:
;   mgalloy
;-
function kcor_datecal
  compile_opt strictarr

  return, string(systime(/utc, /julian), $
                 format='(C(CYI4.4, "-", CMOI2.2, "-", CDI2.2))')
end