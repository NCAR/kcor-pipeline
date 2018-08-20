;+
; NAME		fitsdisp_comp.pro
;
; PURPOSE	Display a FITS image.
;
; KEYWORDS
;		xdim_prev	previous x dimension
;		ydim_prev	previous y dimension
;		wmin		display minimum
;		wmax		display maximum
;		wexp		display exponent
;		gif		if set, create a GIF file.
;		ext		FITS extension number: 1,2,3...
;
; SYNTAX	fitsdisp_comp, fits_name
;
; EXAMPLE	fitsdisp_comp, '20150412_181124_kcor.fts'
;		fitsdisp_comp, '20150412_181124.kcor.fts', /gif
;
; EXTERNAL
; PROCEDURES	fits_annotate_comp.pro
;
; HISTORY	Andrew L. Stanger   HAO/NCAR   13 July 2015
;-

PRO fitsdisp_comp, fits_name, xdim_prev, ydim_prev, $
                   wmin=wmin, wmax=wmax, wexp=wexp, gif=gif, ext=ext

  fext = 1
  if (KEYWORD_SET (ext)) THEN fext = ext

  xb = 160		; X-axis border for annotation.
  yb =  88		; Y-axis border for annotation.

  ftspos   = STRPOS (fits_name, '.fts')
  basename = STRMID (fits_name, 0, ftspos)

;  print, 'basename: ', basename

  ;---------------------------
  ; Read image from FITS file.
  ;---------------------------

  hdu = headfits (fits_name)
  img = readfits (fits_name, hduext, exten_no=fext, /silent)
 
  fimg = float (img) * 0.001		; comp img = pB * 1000.0

  ;---------------------------------
  ; Extract information from header.
  ;---------------------------------

  telescop = fxpar (hdu, 'TELESCOP')
  instrume = fxpar (hdu, 'INSTRUME')
  dateobs  = fxpar (hdu, 'DATE-OBS')
  crpix1   = fxpar (hdu, 'CRPIX1')
  crpix2   = fxpar (hdu, 'CRPIX2')
  cdelt1   = fxpar (hdu, 'CDELT1')
  cdelt2   = fxpar (hdu, 'CDELT2')
  oradius  = fxpar (hdu, 'ORADIUS')
  fradius  = fxpar (hdu, 'FRADIUS')
  frpix1   = fxpar (hdu, 'FRPIX1')
  frpix2   = fxpar (hdu, 'FRPIX2')

  rsun     = fxpar (hdu, 'RSUN_OBS', count=n_rsun)
  if (n_rsun eq 0L) then rsun = fxpar (hdu, 'RSUN', count=n_rsun)

  srsun    = STRING (rsun, FORMAT='(F7.2)')

;  bunit    = fxpar (hdu, 'BUNIT')

  xdim     = fxpar (hduext, 'NAXIS1')
  ydim     = fxpar (hduext, 'NAXIS2')
  datamin  = fxpar (hduext, 'DATAMIN')
  datamax  = fxpar (hduext, 'DATAMAX')
  waveleng = fxpar (hduext, 'WAVELENG')

;  dispmin  = fxpar (hdu, 'DISPMIN')
;  dispmax  = fxpar (hdu, 'DISPMAX')

  dmin = MIN (fimg)
  dmax = MAX (fimg)
  dexp = 1.0
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

  fits_annotate_comp, hdu, xdim, ydim, xb, yb, dmin, dmax, dexp

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

