;+
;-------------------------------------------------------------------------------
; NAME		fitsdisp_kcor.pro
;-------------------------------------------------------------------------------
; PURPOSE	Display a FITS image.
;
; SYNTAX
; fitsdisp_kcor, fits_name, xdim_prev, ydim_prev, xb, yb
; fitsdisp_kcor, fits_name, xdim_prev, ydim_prev, xb, yb, /gif
; fitsdisp_kcor, fits_name, xdim_prev, ydim_prev, xb, yb, wmin=1.0
; fitsdisp_kcor, fits_name, xdim_prev, ydim_prev, xb, yb, wmax=250.0
;
; EXTERNAL
; PROCEDURES	fits_annotate_kcor.pro
;
; HISTORY	Andrew L. Stanger   HAO/NCAR   14 September 2001
; 26 Sep 2001 {ALS] wide format (no colorbar BELOW image).
; 17 Nov 2015 [ALS] Adapt for kcor.
;-------------------------------------------------------------------------------
;-

PRO fitsdisp_kcor, fits_name, xdim_prev, ydim_prev, xb, yb, $
	           gif=gif, wmin=wmin, wmax=wmax, wexp=wexp

print, '>>> fitsdisp_kcor'
;   xb = 160		; X-axis border for annotation.
;   yb =   0		; Y-axis border for annotation.

   ftspos   = STRPOS (fits_name, '.fts')
   basename = STRMID (fits_name, 0, ftspos)

;   print, 'basename: ', basename

   img = readfits (fits_name, hdu, /noscale)

   ;---------------------------------
   ; Extract information from header.
   ;---------------------------------

   xdim     = fxpar (hdu, 'NAXIS1')
   ydim     = fxpar (hdu, 'NAXIS2')

   ;-------------------------
   ; "Erase" annotation area.
   ;-------------------------

   print, '### fitsdisp_kcor: erasing annotation area.'
   leftborder   = BYTARR (xb,        yb + ydim)
   bottomborder = BYTARR (xb + xdim, yb       )
   leftborder   [*, *] = 255
   bottomborder [*, *] = 255
   TV, leftborder
   TV, bottomborder

   ;---------------------------------
   ; Resize window if it has changed.
   ;---------------------------------

;   if (xdim NE xdim_prev OR ydim NE ydim_prev)  THEN	$
;       window, xsize=xdim+xb, ys=ydim+yb

;   print, 'xdim + xb: ', xdim + xb
;   print, 'ydim + yb: ', ydim + yb

   xdim_prev = xdim
   ydim_prev = ydim

   ;----------------
   ; Annotate image.
   ;----------------

;   fits_annotate_kcor, hdu, xdim, ydim, xb, yb, wmin=wmin, wmax=wmax, wexp=wexp

   ;----------------------------------
   ; Get information from FITS header.
   ;----------------------------------

;   orbit_id = fxpar (hdu, 'ORBIT-ID')
;   image_id = fxpar (hdu, 'IMAGE-ID')

   bitpix   = fxpar (hdu, 'BITPIX',   count=qbitpix)
   telescop = fxpar (hdu, 'TELESCOP', count=qtelescop)
   instrume = fxpar (hdu, 'INSTRUME', count=qinstrume)
   date_obs = fxpar (hdu, 'DATE-OBS', count=qdate_obs)
   time_obs = fxpar (hdu, 'TIME-OBS', count=qtime_obs)
   rsun     = fxpar (hdu, 'RSUN',     count=qrsun)
   bunit    = fxpar (hdu, 'BUNIT',    count=qbunit)
   bzero    = fxpar (hdu, 'BZERO',    count=qbzero)
   bscale   = fxpar (hdu, 'BSCALE',   count=qbscale)
   datamin  = fxpar (hdu, 'DATAMIN',  count=qdatamin)
   datamax  = fxpar (hdu, 'DATAMAX',  count=qdatamax)
   dispmin  = fxpar (hdu, 'DISPMIN',  count=qdispmin)
   dispmax  = fxpar (hdu, 'DISPMAX',  count=qdispmax)
   dispexp  = fxpar (hdu, 'DISPEXP',  count=qdispexp)

   telescop = STRTRIM (telescop, 2)
   srsun    = STRING (rsun, FORMAT='(F7.2)')

   if (bitpix EQ 16 AND bscale EQ 1.0) then bscale = 0.001 ; =1.0 < 15 Jul 2015.
   if (bscale NE 1.0) then $
      img = img * bscale + bzero

   ;----------------------------
   ; Default display parameters.
   ;----------------------------

   dmin = 0.0
   dmax = 1.2
   dexp = 0.7

   ;---------------
   ; Display image.
   ;---------------

   if (qdispmin NE 0) then dmin = dispmin	; display min from header.
   if (qdispmax NE 0) then dmax = dispmax	; display max from header.
   if (qdispexp NE 0) then dexp = dispexp	; display exponent from header.

   IF (KEYWORD_SET (wmin)) THEN dmin = wmin	; display min from keyword
   IF (KEYWORD_SET (wmax)) THEN dmax = wmax	; display max from keyword
   IF (KEYWORD_SET (wexp)) THEN dexp = wexp	; display exponent from keyword

   TV, BYTSCL (img^dexp, min=dmin, max=dmax, top=249), xb, yb

   ;----------------
   ; Annotate image.
   ;----------------

   fits_annotate_kcor, hdu, xdim, ydim, xb, yb, wmin=wmin, wmax=wmax, wexp=wexp

   RETURN

END
