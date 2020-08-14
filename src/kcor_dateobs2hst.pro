; docformat = 'rst'

;+
; Convert a DATE-OBS keyword value to an HST time.
;
; :Returns:
;   time in the form "HHMMSS"
;
; :Params:
;   dateobs : in, required, type=string
;     DATE-OBS value in the form "YYYY-MM-DDTHH:MM:SS" such as
;     '2020-08-14T02:21:55'
;-
function kcor_dateobs2hst, dateobs
  compile_opt strictarr

  hour = strmid(dateobs, 11, 2)
  minute = strmid(dateobs, 14, 2)
  second = strmid(dateobs, 17, 2)

  return, kcor_ut2hst(hour + minute + second)
end
