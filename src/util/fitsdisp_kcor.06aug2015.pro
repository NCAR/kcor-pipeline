;+
; NAME		fitsdisp_kcor.pro
;
; PURPOSE	Display a FITS image.
;
; SYNTAX	fitsdisp_kcor, fits_name
;
; EXAMPLE	fitsdisp_kcor, '20150412_181124_kcor.fts'
;		fitsdisp_kcor, '20150412_181124.kcor.fts', /gif
;
; EXTERNAL
; PROCEDURES	fits_annotate_kcor.pro
;
; HISTORY	Andrew L. Stanger   HAO/NCAR   14 September 2001
;-

PRO fitsdisp_kcor, fits_name, xdim_prev, ydim_prev, $
                   wmin=wmin, wmax=wmax, wexp=wexp, gif=gif

  xb = 160		; X-axis border for annotation.
  yb =  88		; Y-axis border for annotation.

  ftspos   = STRPOS (fits_name, '.fts')
  basename = STRMID (fits_name, 0, ftspos)

;  print, 'basename: ', basename

  ;---------------------------
  ; Read image from FITS file.
  ;---------------------------

  img = readfits (fits_name, hdu, /noscale, /silent)
 
  fimg = float (img) * 0.001		; kcor img = pB * 1000.0

  ;---------------------------------
  ; Extract information from header.
  ;---------------------------------

  xdim     = fxpar (hdu, 'NAXIS1')
  ydim     = fxpar (hdu, 'NAXIS2')
  telescop = fxpar (hdu, 'TELESCOP')
  instrume = fxpar (hdu, 'INSTRUME')
  dateobs  = fxpar (hdu, 'DATE-OBS')
  rsun     = fxpar (hdu, 'RSUN')

  srsun    = STRING (rsun, FORMAT='(F7.2)')

;  bunit    = fxpar (hdu, 'BUNIT')
;  datamin  = fxpar (hdu, 'DATAMIN')
;  datamax  = fxpar (hdu, 'DATAMAX')
;  dispmin  = fxpar (hdu, 'DISPMIN')
;  dispmax  = fxpar (hdu, 'DISPMAX')

  dmin = MIN (fimg)
  dmax = MAX (fimg)
  dmin = 0.0
  dmax = 1.2
  dexp = 0.7
  print, 'min/max (fimg): ', min (fimg), max (fimg)

  IF (KEYWORD_SET (wmin)) THEN dmin = wmin
  IF (KEYWORD_SET (wmax)) THEN dmax = wmax
  IF (KEYWORD_SET (wexp)) THEN dexp = wexp

  ;---------------------------------
  ; Resize window if it has changed.
  ;---------------------------------

  if (xdim NE xdim_prev OR ydim NE ydim_prev)  THEN	$
      window, xsize=xdim+xb, ys=ydim+yb, retain=2

  xdim_prev = xdim
  ydim_prev = ydim

  ;------------------------------
  ; "Erase" left annotation area.
  ;------------------------------

;  print, 'xdim + xb: ', xdim + xb
;  print, 'ydim + yb: ', ydim + yb

  leftborder   = BYTARR (xb,        yb + ydim + yb)
  bottomborder = BYTARR (xb + xdim, yb            )
  leftborder [*, *]   = 255
  bottomborder [*, *] = 255
  TV, leftborder
  TV, bottomborder

  ;----------------
  ; Annotate image.
  ;----------------

  fits_annotate_kcor, hdu, xdim, ydim, xb, yb, dmin, dmax, dexp

  ;---------------
  ; Display image.
  ;---------------

  TV, BYTSCL (fimg ^ dexp, min=dmin, max=dmax, top=249), xb, yb

  ;---------------------------------------------------------------
  ; Write displayed image as a GIF file (if "gif" keyword is set).
  ;---------------------------------------------------------------

  IF (KEYWORD_SET (gif))  THEN		$
  BEGIN  ;{
     gif_file = basename + '.gif'
     img_gif = TVRD ()
     WRITE_GIF, gif_file, img_gif, red, green, blue
  ENDIF  ;}

  RETURN

END

