;+
;-------------------------------------------------------------------------------
; kcor_label_hires.pro		IDL procedure
;-------------------------------------------------------------------------------
; :params:
;   date_obs	date: yyyy-mm-dd
;   doy		day-of-year (1-366)
;   time_obs	time: hh:mm:ss
;   dmin, dmax, dexp	display min, max, exponent
;-------------------------------------------------------------------------------
; :author: Andrew L. Stanger   MLSO/HAO/NCAR   cosmo K-coronagraph
; 17 Jun 2015 IDL procedure created.
;-------------------------------------------------------------------------------
; external subroutines:
;   suncir_kcor.pro
;-------------------------------------------------------------------------------
; NOTE: Graphics window must be previously established, with 1024x1024 pixels.
;-------------------------------------------------------------------------------
;-

PRO kcor_label_hires, date_dmy, doy, time_obs, datatype, $
                      xdim, ydim, xcen, ycen, pixrs, $
                      dmin, dmax, dexp, cneg, cpos

;-----------------------
; Color levels for annotation:
;-----------------------

yellow = 250
grey   = 251
blue   = 252
green  = 253
red    = 254
white  = 255

;------.
; title
;-------

xyouts, 4, 990, 'MLSO/HAO/KCOR', color = 251, charsize = 1.5, /device
xyouts, 4, 970, 'K-Coronagraph', color = 254, charsize = 2.0, font=1, /device
xyouts, 4, 950, 'polarized brightness', color=251, charsize=1.5, /device

;------------
; Date & time
;------------

;xyouts, 1018, 995, string (format = '(a2)', day) + ' ' + $
;                   string (format = '(a3)', name_month) +  ' ' + $
;                   string (format = '(a4)', year), /device, alignment = 1.0, $
;		   charsize=1.2, color=251

xyouts, 1018, 995, date_dmy, alignment=1.0, charsize=1.2, color=251, /device
xyouts, 1010, 975, 'DOY ' + string (format = '(i3)', doy), /device, $
                   alignment = 1.0, charsize = 1.2, color = 251
;xyouts, 1018, 955, string (format = '(a2)', hour) + ':' + $
;                   string (format = '(a2)', minute) + ':' + $
;	           string(format = '(a2)', second) + ' UT', /device, $
;                   alignment = 1.0, charsize = 1.2, color = 251

xyouts, 1018, 955, time_obs, alignment=1.0, charsize=1.2, color=251, /device

;-------------------
; Compass directions
;-------------------

xyouts, 505, cpos-24, 'N', color = 254, charsize = 1.5, /device
xyouts, cneg+12, 505, 'E', color = 254, charsize = 1.5, /device 
xyouts, 505, cneg+12, 'S', color = 254, charsize = 1.5, /device 
xyouts, cpos-24, 505, 'W', color = 254, charsize = 1.5, /device 

;----------------
; display scaling
;----------------

datalabel = 'unknown data type'
if (datatype EQ 'science') then $
  datalabel = 'scaling: Intensity ^ ' + $
               strtrim (string (format='(f5.2)', dexp), 2)
if (datatype EQ 'engineering') then $
  datalabel = 'Engineering data'
if (datatype EQ 'calibration') then $
  datalabel = "Calibration data'
if (datatype EQ 'NRGF') then $
  datalabel = 'normalized radially-graded filter applied'

print, 'datatype:  ', datatype
print, 'datalabel: ', datalabel
     
xyouts, 4, 46, 'Level 1 data', color = 251, charsize = 1.2, /device
xyouts, 4, 26, 'min/max: ' + string (format = '(f4.1)', dmin) + ', ' $
                           + string (format = '(f4.1)', dmax), $
	       color = 251, charsize = 1.2, /device
;xyouts, 4, 6, 'Intensity: normalized, radial-graded filter', $
;              color = 251, charsize = 1.2, /device
xyouts, 4, 6, datalabel, color = 251, charsize = 1.2, /device

;--------------------
; photosphere comment
;--------------------

xyouts, 1018, 6, 'circle: photosphere', $
                 color = 251, charsize = 1.2, /device, alignment = 1.0

;--- Image has been shifted to center of array.
;--- Draw circle at photosphere.

;tvcircle, pixrs, 511.5, 511.5, color = 251, /device

;----------------------------------
; Draw polar grid in occulter area.
;----------------------------------

suncir_kcor, xdim, ydim, xcen, ycen, 0, 0, pixrs, 0.0

END
