;+
;-------------------------------------------------------------------------------
; NAME		fvs_kcor.pro
;-------------------------------------------------------------------------------
; PURPOSE	Display FITS images.
;
; SYNTAX	fvs_kcor, 'list', cm='color.lut', /gif
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
; EXAMPLES	fvs_kcor, 'list'
;		fvs_kcor, 'list', /gif
;		fvs_kcor, 'list', cm='/home/stanger/color/bwcp'
;		fvs_kcor, 'list', wmin=0.0, wmax=1.2, wexp=0.7
;
; EXTERNAL
; PROCEDURES	fitsdisp_kcor.pro
;		fits_annotate_kcor.pro
;
; HISTORY	Andrew L. Stanger   HAO/NCAR   14 September 2001
; 30 Jun 2015 adapted for kcor from "fvs.pro".
; 23 Nov 2015 add xb & yb parameters to 'fitsdisp_kcor' call.
;-------------------------------------------------------------------------------
;-

PRO fvs_kcor, fits_list, cm=cm, wmin=wmin, wmax=wmax, wexp=wexp, gif=gif
;{

;--- Load color map.

;loadct, 3					; standard RSI color table #3.
;lct, '/home/stanger/color/sunsetcp.lut'	; Load color table.
;lct, '/home/stanger/color/bwy.lut'		; Load default color map.

lct, '/home/stanger/color/quallab.lut'

IF (KEYWORD_SET (cm))  THEN	$
   lct, cm

red   = bytarr (256)
green = bytarr (256)
blue  = bytarr (256)
tvlct, red, green, blue, /GET		; Fetch RGB color look-up tables.

dmin = 0.0
dmax = 1.2
dexp = 0.7

IF (KEYWORD_SET (wmin)) THEN dmin = wmin
IF (KEYWORD_SET (wmax)) THEN dmax = wmax
IF (KEYWORD_SET (wexp)) THEN dexp = wexp

PRINT, 'Position the cursor in the image window.'
PRINT, 'Pressing the LEFT   mouse button displays the NEXT     image.'
PRINT, 'Pressing the RIGHT  mouse button displays the PREVIOUS image.
PRINT, 'Pressing the MIDDLE mouse button terminates the program.'

CLOSE, 11
fits_name = ''
xb        = 160 
yb        =  88
xdim_prev = 0
ydim_prev = 0
floc      = LONG (0)

;--- Count the number to images files.

nimg = FILE_LINES (fits_list)
fpos = LONARR (nimg)

;--- Image list loop.

index = 0
OPENR, UF, fits_list, /GET_LUN
WHILE (NOT EOF (UF)) DO  $
BEGIN  ;{

   POINT_LUN, -UF, floc
   fpos [index] = floc

   ;--- Read FITS image header & pixel data.

   READF, UF, fits_name                          ; Get file name.
   PRINT, 'fits_name: ', fits_name

   hdu = headfits (fits_name)
   xdim = fxpar (hdu, 'NAXIS1')
   ydim = fxpar (hdu, 'NAXIS2')

   ; window_state: 1 = window open, 0 = window closed.

  print, 'index: ', index
  if (index EQ 0) THEN $
  BEGIN ;{
    DEVICE, window_state = wstat
;    IF (wstat [0] EQ 0)  THEN window, xs=xb+xdim, ys=yb+ydim, retain=2
    window, xs=xb+xdim, ys=yb+ydim, retain=2
    sidebar = BYTARR (xb,        yb + ydim)
    bottom  = BYTARR (xb + xdim, yb       )
    sidebar (*, *) = 255
    bottom  (*, *) = 255
    tv, sidebar
    tv, bottom
    print, '--- erasing annotation area.'
;  print, 'pause'
;  PAUSE
  END    ;}

   ;--- Display FITS image in IDL window.

   fitsdisp_kcor, fits_name, xdim_prev, ydim_prev, xb, yb, $
                  wmin=dmin, wmax=dmax, wexp=dexp, gif=gif

   ;---------------------------------------------
   ; Use mouse button to control image list flow
   ;---------------------------------------------
   ;   Left   mouse button = forward.
   ;   Middle mouse button = quit.
   ;   Right  mouse button = backwards.
   ;---------------------------------------------

   CURSOR, wx, wy

   print, '!mouse.button, index: ', !mouse.button, index

   IF (!mouse.button EQ 1) THEN			$
   BEGIN ;{
      index = index + 1
      IF (index GE nimg)  THEN index = 0
   ENDIF ;}

   IF (!mouse.button EQ 2) THEN GOTO, FINISH

   IF (!mouse.button EQ 4)  THEN		$
   BEGIN  ;{
      index = index - 1
      IF (index LT 0)  THEN index = 0 
      POINT_LUN, UF, fpos [index]
   ENDIF ;}

ENDWHILE    ;}

FINISH: FREE_LUN, UF

END   ;}

