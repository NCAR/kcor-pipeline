;+
;-------------------------------------------------------------------------------
; NAME		fvp_kcor.pro
;-------------------------------------------------------------------------------
; PURPOSE	Display a kcor FITS image & report cursor position.
;
; SYNTAX	fvp_kcor, fits_image, /gif, cm='colormap.lut', $
;                         wmin=0, wmax=1.0, wexp=0.6
;
;		fits_image	filename of Spartan WLC FITS image.
;		gif		write displayed image as a GIF file.
;		cm		pathname of ASCII colormap file.
;				Each line has the syntax: index red green blue
;				where index = 0, 1, 2, ... 255,
;				and red/green/blue are in the range [0:255].
;		wmin		display minimum value [default: 0.0].
;		wmax		display maximum value [default: 1.2].
;		wexp		display exponent      default:  0.7].
;		nolabel		If set, do NOT display the position # label.
;
; EXAMPLES	fvp_kcor, '19981101.1234.mk3.cpb.fts'
; 		fvp_kcor, '19981101.1234.mk3.rpb.fts',$
;                         cm='/home/stanger/color/bwy.lut'
; 		fvp_kcor, '19981101.1234.mk3.rpb.fts', /gif
;
; EXTERNAL
; PROCEDURES
;		readfits		read FITS image
;		headfits		read FITS header
;		fxpar			read FITS keyword parameter
;
;		fitsdisp_kcor.pro 	display kcor image
;		fits_annotate_kcor.pro	annotate kcor image
;		mouse_pos_lab.pro	mouse position + label procedure
;
; HISTORY	Andrew L. Stanger   HAO/NCAR   17 Nov 2001
; 17 Nov 2015 [ALS] Adapted from fvp.pro for kcor.
;-------------------------------------------------------------------------------
;-

PRO fvp_kcor, fits_name, gif=gif, cm=cm, wmin=wmin, wmax=wmax, wexp=wexp, $
              text=text, nolabel=nolabel

disp_label = 1				; Set display label option variable.

;------------------
; Load color table.
;------------------

IF (KEYWORD_SET (cm))  THEN 		$
BEGIN
   PRINT, 'cm: ', cm
   dirend = -1

   ;---------------------------------------
   ; Find index of last "/" in cm pathname.
   ;---------------------------------------

   FOR i = 0, strlen (cm) - 1 DO		$
   BEGIN
      dirloc = STRPOS (cm, '/', i)
      IF (dirloc GE 0)  THEN dirend = dirloc
   END

   IF (dirend NE -1)  THEN		$
   BEGIN
      PRINT, 'dirend: ', dirend
      coldir = STRMID (cm, 0, dirend)	; Directory containing color map.
      PRINT, 'coldir: ', coldir
      ccm = STRMID (cm, dirend+1, strlen (cm) - dirend - 1)	; color map file
      PRINT, 'ccm: ', ccm
   END

   ;-----------------------------------------------------------------
   ; If cm does not contain a directory, use default color directory.
   ;-----------------------------------------------------------------

   IF (dirend EQ -1)  THEN		$
      lct, '/home/cordyn/color/' + cm + '.lut'	$	; Use default directory.
   ELSE					$
   lct, cm					; Load specified colormap.
END					$
ELSE   lct, '/hao/acos/sw/colortable/quallab.lut' ; Load blue-white colormap.
 
;-----------------------
; Read color map arrays.
;-----------------------

redlut   = bytarr (256)
greenlut = bytarr (256)
bluelut  = bytarr (256)
tvlct, redlut, greenlut, bluelut, /GET	; Fetch RGB color look-up tables.

;-------------------------
; Default variable values.
;-------------------------

xb = 160 		; x-axis border [pixels]
yb =  80		; y-axis border [pixels]
xdim_prev = 0		; x-dimension previous image.
ydim_prev = 0		; y-dimension previous image.

   ;--------------------------
   ; Read FITS image & header.
   ;--------------------------

   ftspos   = STRPOS (fits_name, '.fts')
   basename = STRMID (fits_name, 0, ftspos)
   print, 'basename: ', basename

   ;--------------------------------
   ; Open text file and write title.
   ;--------------------------------

   IF (KEYWORD_SET (text)) THEN	$
   BEGIN
      pfile = basename + '.pos'
      CLOSE,  21
      OPENW,  21, pfile
      PRINTF, 21, fits_name, '   Position Measurement[s]'
      CLOSE,  21
   END

   ;--------------------------
   ; Read FITS image & header.
   ;--------------------------

   hdu = headfits (fits_name)

   ;---------------------------------
   ; Extract information from header.
   ;---------------------------------

   xdim     = fxpar (hdu, 'NAXIS1')
   ydim     = fxpar (hdu, 'NAXIS2')
   xcen     = fxpar (hdu, 'CRPIX1') + xb - 1
   ycen     = fxpar (hdu, 'CRPIX2') + yb - 1
   roll     = fxpar (hdu, 'INST_ROT', count=qinst_rot)
   cdelt1   = fxpar (hdu, 'CDELT1',   count=qcdelt1)
   rsun     = fxpar (hdu, 'RSUN_OBS', count=qrsun)
   if (qrsun eq 0L) then rsun = fxpar (hdu, 'RSUN', count=qrsun)

   pixrs    = rsun / cdelt1	; pixels/Rsun.

   print, 'pixrs   : ', pixrs

   ;-------------------------------------------
   ; Resize window [if image size has changed].
   ;-------------------------------------------

   if (xdim NE xdim_prev OR ydim NE ydim_prev)  THEN	$
       WINDOW, xsize=xdim+xb, ys=ydim+yb, retain=2

   print, 'xdim + xb: ', xdim + xb
   print, 'ydim + yb: ', ydim + yb

   xdim_prev = xdim
   ydim_prev = ydim

   ;----------------
   ; Annotate image.
   ;----------------

;   fits_annotate_kcor, hdu, xdim, ydim, xb, yb

   ;---------------
   ; Display image.
   ;---------------

   fitsdisp_kcor, fits_name, xdim_prev, ydim_prev, xb, yb, $
                  gif=gif, wmin=wmin, wmax=wmax, wexp=wexp

   ;------------------------------------------------------------------
   ; Use mouse to extract radius & position angle for cursor position.
   ;------------------------------------------------------------------

   IF (KEYWORD_SET (nolabel)) THEN			 $
     mouse_pos_lab, xdim, ydim, xcen, ycen, pixrs, roll, $
		    pos=1, pfile=pfile			 $
   ELSE	$
     mouse_pos_lab, xdim, ydim, xcen, ycen, pixrs, roll, $
		    pos=1, pfile=pfile, /disp_label

   ;---------------------------------------------------------------
   ; Write displayed image to a GIF file (if "gif" keyword is set).
   ;---------------------------------------------------------------

   IF (KEYWORD_SET (gif))  THEN		$
   BEGIN
      gif_file = basename + '.gif'
      img_gif = TVRD ()
      WRITE_GIF, gif_file, img_gif, redlut, greenlut, bluelut
   END

END

