;+
;-------------------------------------------------------------------------------
; NAME		kcor_review.pro
;-------------------------------------------------------------------------------
; PURPOSE	Display FITS images & review bad images.
;		Two list files are created: 'fitsg.ls' & fitsb.ls'.
;
; SYNTAX	kcor_review, 'list', cm='color.lut', /gif
;
;		list	file containing a list of kcor FITS images.
;		cm	pathname of an ASCII colormap file.
;			Each line has the syntax: index red green blue
;			where index = 0, 1, 2, ... 255,
;			and red/green/blue are in the range [0:255].
;		wmin	display minimum value.
;		wmax	display maximum value.
;		wexp	scaling exponent
;		gif	write out the displayed image as a GIF file.
;
;
; EXAMPLES	kcor_review, 'list'
;		kcor_review, 'list', /gif
;		kcor_review, 'list', cm='/home/stanger/color/bwcp'
;		kcor_review, 'list', wmin=0.0, wmax=1.2, wexp=0.7
;
; EXTERNAL
; PROCEDURES	fitsdisp_kcor.pro
;		fits_annotate_kcor.pro
;
; HISTORY	Andrew L. Stanger  HAO/NCAR   14 September 2001
; 30 Jun 2015 adapted for kcor from "fvs.pro".
; 02 Jul 2015 change dexp from 0.7 to 0.5.
; 10 Jul 2015 add 'okb.ls': file containing "bad" images.
; 23 Nov 2015 add xb & yb parameters in fitsdisp_kcor call.
;-------------------------------------------------------------------------------
;-

PRO kcor_review, fits_list, cm=cm, wmin=wmin, wmax=wmax, wexp=wexp, gif=gif
;{

;--- Load color map.

;loadct, 3					; standard RSI color table #3.
;lct, '/home/stanger/color/sunsetcp.lut'	; Load color table.
;lct, '/home/stanger/color/bwy.lut'		; Load default color map.

lct, '/home/stanger/color/quallab.lut'

IF (KEYWORD_SET (cm))  THEN	$
  lct, cm

red  = bytarr (256)
green = bytarr (256)
blue  = bytarr (256)
tvlct, red, green, blue, /GET		; Fetch RGB color look-up tables.

dmin = 0.0
dmax = 1.2
dexp = 0.7
;dexp = 0.5

IF (KEYWORD_SET (wmin)) THEN dmin = wmin
IF (KEYWORD_SET (wmax)) THEN dmax = wmax
IF (KEYWORD_SET (wexp)) THEN dexp = wexp

PRINT, 'Position the cursor in the image window.'
PRINT, 'Pressing the LEFT   mouse button adds image to keep list.'
PRINT, 'Pressing the MIDDLE mouse button terminates program.'
PRINT, 'Pressing the RIGHT  mouse button adds image to toss list..

CLOSE, 11
fits_name = ''
xb      = 160 
yb      =  88
xdim_prev = 0
ydim_prev = 0
floc    = LONG (0)

;--- Count the number to images files.

nimg = FILE_LINES (fits_list)
fpos = LONARR (nimg)
if (nimg LE 0) THEN GOTO, FINISH

fits_keep = 'fkeep.ls'
fits_bad  = 'ftoss.ls'
OPENW, UK, fits_keep, /GET_LUN
OPENW, UT, fits_bad,  /GET_LUN

;--- Image list loop.

index     =  0
index_max = -1
OPENR, UF, fits_list, /GET_LUN
WHILE (NOT EOF (UF)) DO  $
BEGIN  ;{

  POINT_LUN, -UF, floc				; Get  file pointer position.
  fpos [index] = floc				; Save file pointer position.

  ;--- Read FITS image header & pixel data.

  READF, UF, fits_name                         ; Get file name.
  PRINT, 'fits_name: ', fits_name

  hdu  = headfits (fits_name)
  xdim = fxpar (hdu, 'NAXIS1')
  ydim = fxpar (hdu, 'NAXIS2')

  ; window_state: 1 = window open, 0 = window closed.

  if (index EQ 0) THEN $
  BEGIN ;{
   DEVICE, window_state = wstat
   IF (wstat [0] EQ 0)  THEN window, xs=xb+xdim, ys=yb+ydim, retain=2
   sidebar = BYTARR (xb,        yb + ydim)
   bottom  = BYTARR (xb + xdim, yb       )
   sidebar (*, *) = 255
   bottom (*, *)  = 255
   tv, sidebar
   tv, bottom
;  print, 'pause'
;  PAUSE
  END   ;}

  ;--- Display FITS image in IDL window.

  fitsdisp_kcor, fits_name, xdim_prev, ydim_prev, xb, yb, $
                 wmin=dmin, wmax=dmax, wexp=dexp, gif=gif

  ;---------------------------------------------
  ; Use mouse button to control image list flow.
  ;---------------------------------------------
  ; Left   mouse button = forward & include current image in   output list.
  ; Middle mouse button = terminate program.
  ; Right  mouse button = forward & omit    current image from output list.
  ;---------------------------------------------

  CURSOR, wx, wy, /DOWN

  print, '!mouse.button, index, index_max: ', !mouse.button, index, index_max

  ;---------------------------------------------------
  ; Left mouse button pushed:  Add image to keep list.
  ;---------------------------------------------------

  IF (!mouse.button EQ 1) THEN			$
  BEGIN ;{
;    IF (index GT index_max) THEN PRINTF, UK, fits_name ; add image to keep file.
    PRINTF, UK, fits_name	; add image to keep file.
    index = index + 1
;    IF (index GE nimg)  THEN index = 0
    
  ENDIF ;}

  ;----------------------------------------------------
  ; Right mouse button pushed:  Add image to toss list.
  ;----------------------------------------------------

  IF (!mouse.button EQ 4) THEN			$
  BEGIN ;{
    index = index + 1
    print, 'reject'
    PRINTF, UT, fits_name	; add image to bad file.
  ENDIF ;}					$

  ;-------------------------------------------
  ; Middle mouse button pushed: exit program.
  ;-------------------------------------------

  IF (!mouse.button EQ 2)  THEN		$
  BEGIN  ;{
;    index = index - 1
;    IF (index LT 0)  THEN index = 0 
;    POINT_LUN, UF, fpos [index]		; Set file pointer to previous position.
    goto, FINISH
  ENDIF ;}

  IF (index GT index_max)  THEN index_max = index - 1

ENDWHILE   ;}

FINISH: $
FREE_LUN, UF
FREE_LUN, UK
FREE_LUN, UT

END  ;}

