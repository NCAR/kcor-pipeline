; docformat = 'rst'

;+
; Simulate an SGS DIMV value using a model. This is only valid for dates from
; 20130930 to 20131009.
;
; :Returns:
;   float
;
; :Params:
;   date_obs : in, required, type=string
;     date/time to simulate SGS DIMV for in the form "2013-11-23T20:10:07"
;-
function kcor_simulate_sgsdimv, date_obs
  compile_opt strictarr
  on_error, 2

  sdate = kcor_parse_dateobs(date_obs)

  ; only valid from 20130930 to 20131009
  if (sdate.year ne 2013 || (sdate.month lt 9) || (sdate.month gt 10) $
        || (sdate.month eq 9 && sdate.day lt 30) $
        || (sdate.month eq 10 && sdate.day gt 9)) then begin
    message, string(date_obs, format='(%"this routine not valid for date %s")')
  endif

  ; TODO: actually calculate
  dimv = 3.5

  return, dimv
end
