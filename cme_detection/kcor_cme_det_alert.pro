;+
; Project     :	MLSO - KCOR
;
; Name        :	KCOR_CME_DET_ALERT
;
; Purpose     :	Generates an alert when a CME is detected
;
; Category    :	KCOR, CME, Detection
;
; Explanation :	This routine handles the actions involved in alerting users
;               that a CME has been detected.  At the moment this involves
;               writing a message to a widget, but future actions could include
;               generating movies and sending emails.
;
; Syntax      :	KCOR_CME_DET_ALERT, ITIME, RSUN
;
; Examples    :	See KCOR_CME_DET_MEASURE
;
; Inputs      :	ITIME   = Current time index into LEADINGEDGE array
;               RSUN    = Solar radii in arcminutes
;
; Opt. Inputs :	None
;
; Outputs     :	None
;
; Opt. Outputs:	None
;
; Keywords    :	None
;
; Calls       :	TAI2UTC
;
; Common      :	KCOR_CME_DETECTION defined in kcor_cme_detection.pro
;
; Restrictions:	None
;
; Side effects:	None
;
; Prev. Hist. :	None
;
; History     :	Version 1, 05-Jan-2017, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;
pro kcor_cme_det_alert, itime, rsun
;
common kcor_cme_detection
;
time = tai2utc(tairef, /time, /truncate, /ccsds)
edge = 60 * (lat[leadingedge[itime]] + 90) / rsun
format = '(F10.2)'
message = 'CME detected at ' + time + ' UT, Rsun ' + ntrim(edge,format) + $
          ', position angle ' + ntrim(angle) + $
          ', initial speed ' + ntrim(speed,format) + ' km/s'
widget_control, wmessage, set_value=message, /append
print, message
;
end
