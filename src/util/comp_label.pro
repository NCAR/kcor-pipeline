;+
;-------------------------------------------------------------------------------
; comp_label.pro		IDL procedure
;-------------------------------------------------------------------------------
; :params:
;   date_dmy		date: yyyy-mm-dd
;   doy			day-of-year (1-366)
;   time_obs		time: hh:mm:ss
;   datatype		data type: data, dark, flat
;   wave                wavelenth: 1074, 1083
;   xdim, ydim  	image dimensions
;   xcen, ycen  	occulting center
;   pixrs       	pixels/Rsun
;   dmin, dmax, dexp	display min, max, exponent
;   cneg, cpos		pixel distance at Rsun left right of center
;-------------------------------------------------------------------------------
; :author: Andrew L. Stanger   MLSO/HAO/NCAR   cosmo comp 
; 29 Jun 2015 IDL procedure created.
;-------------------------------------------------------------------------------
; external subroutines:
;   kcor_suncir.pro
;-------------------------------------------------------------------------------
; NOTE: Graphics window must be previously established, with 1024x1024 pixels.
;-------------------------------------------------------------------------------
;-

PRO comp_label, date_dmy, doy, time_obs, datatype, wave, $
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

xyouts, 4, 600, 'HAO/MLSO',  color = 251, charsize = 1.2, /device
;xyouts, 4, 580, 'CoMP',      color = 254, charsize = 1.8, font=1, /device
xyouts, 4, 580, 'CoMP',      color = 254, charsize = 1.2, /device
xyouts, 4, 560, 'intensity', color=251, charsize=1.2, /device
xyouts, 4, 540, wave,        color=251, charsize=1.2, /device

;------------
; Date & time
;------------

;xyouts, 612, 590, string (format = '(a2)', day) + ' ' + $
;                   string (format = '(a3)', name_month) +  ' ' + $
;                   string (format = '(a4)', year), /device, alignment = 1.0, $
;		   charsize=1.2, color=251

xyouts, 612, 600, date_dmy, alignment=1.0, charsize=1.2, color=251, /device
xyouts, 604, 580, 'DOY ' + string (format = '(i3)', doy), /device, $
                   alignment = 1.0, charsize = 1.2, color = 251
;xyouts, 612, 560, string (format = '(a2)', hour) + ':' + $
;                   string (format = '(a2)', minute) + ':' + $
;	           string(format = '(a2)', second) + ' UT', /device, $
;                   alignment = 1.0, charsize = 1.2, color = 251

xyouts, 612, 560, time_obs, alignment=1.0, charsize=1.2, color=251, /device

;-------------------
; Compass directions
;-------------------

xyouts, 304, cpos-30, 'N', color = 254, charsize = 1.5, /device
xyouts, cneg+18, 302, 'E', color = 254, charsize = 1.5, /device 
xyouts, 304, cneg+16, 'S', color = 254, charsize = 1.5, /device 
xyouts, cpos-30, 302, 'W', color = 254, charsize = 1.5, /device 

;----------------
; display scaling
;----------------

datalabel = 'unknown data type'
if (datatype EQ 'DATA') then $
  datalabel = 'scaling: Intensity ^ ' + $
               strtrim (string (format='(f5.2)', dexp), 2)
if (datatype EQ 'DARK') then $
  datalabel = 'dark'
if (datatype EQ 'FLAT') then $
  datalabel = 'diffuser'

print, 'datatype:  ', datatype
print, 'datalabel: ', datalabel
     
xyouts, 4, 46, 'Level 1.5 data', color = 251, charsize = 1.2, /device
xyouts, 4, 26, 'min/max:' + string (format = '(f4.1)', dmin) + ', ' $
                           + string (format = '(f4.1)', dmax), $
	       color = 251, charsize = 1.2, /device
;xyouts, 4, 6, 'Intensity: normalized, radial-graded filter', $
;              color = 251, charsize = 1.2, /device
xyouts, 4, 6, datalabel, color = 251, charsize = 1.2, /device

;--------------------
; photosphere comment
;--------------------

xyouts, 612, 6, 'circle: photosphere', $
                 color = 251, charsize = 1.2, /device, alignment = 1.0

;--- Image has been shifted to center of array.
;--- Draw circle at photosphere.

;tvcircle, pixrs, xcen, ycen, color = 251, /device

;----------------------------------
; Draw polar grid in occulter area.
;----------------------------------

suncir_comp, xdim, ydim, xcen, ycen, 0, 0, pixrs, 0.0

END
