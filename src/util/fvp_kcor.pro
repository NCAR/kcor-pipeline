;+
; NAME		fvp_kcor.pro
;
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
;-
pro fvp_kcor, fits_name, gif=gif, cm=cm, wmin=wmin, wmax=wmax, wexp=wexp, $
              text=text, nolabel=nolabel

  disp_label = 1   ; set display label option variable.

  ; load color table
  if (n_elements(cm) gt 0) then begin
    print, 'cm: ', cm
    dirend = -1

    ; find index of last "/" in cm pathname
    dirend = strpos(cm, '/', /reverse_search)

    if (dirend ne -1) then begin
      print, 'dirend: ', dirend
      coldir = strmid(cm, 0, dirend)   ; directory containing color map
      print, 'coldir: ', coldir
      ccm = strmid(cm, dirend+1, strlen(cm) - dirend - 1)   ; color map file
      print, 'ccm: ', ccm
    endif

    ; if cm does not contain a directory, use default color directory
    if (dirend eq -1) then begin
      cm = filepath(cm + '.lut', $
                    subdir=['..', '..', 'resources'], $
                    root=mg_src_root())
    endif

    ; load specified colormap
    lct, cm
  endif else loadct, 0, /silent   ; load B-W color table if CM not specified
 
  ; read color map arrays
  redlut   = bytarr(256)
  greenlut = bytarr(256)
  bluelut  = bytarr(256)
  tvlct, redlut, greenlut, bluelut, /get   ; fetch RGB color look-up tables

  ; default variable values
  xb = 160        ; x-axis border [pixels]
  yb =  80        ; y-axis border [pixels]
  xdim_prev = 0   ; x-dimension previous image
  ydim_prev = 0   ; y-dimension previous image

  ; read FITS image & header
  ftspos   = strpos(fits_name, '.fts')
  basename = strmid(fits_name, 0, ftspos)
  print, 'basename: ', basename

  ; open text file and write title
  if (keyword_set(text)) then begin
    pfile = basename + '.pos'
    CLOSE,  21
    OPENW,  21, pfile
    PRINTF, 21, fits_name, '   Position Measurement[s]'
    CLOSE,  21
  endif

  ; read FITS image & header
  hdu = headfits(fits_name)

  ; extract information from header
  xdim     = fxpar(hdu, 'NAXIS1')
  ydim     = fxpar(hdu, 'NAXIS2')
  xcen     = fxpar(hdu, 'CRPIX1') + xb - 1
  ycen     = fxpar(hdu, 'CRPIX2') + yb - 1
  roll     = fxpar(hdu, 'INST_ROT', count=qinst_rot)
  cdelt1   = fxpar(hdu, 'CDELT1',   count=qcdelt1)
  rsun     = fxpar(hdu, 'RSUN_OBS', count=qrsun)
  if (qrsun eq 0L) then rsun = fxpar(hdu, 'RSUN', count=qrsun)

  pixrs    = rsun / cdelt1   ; pixels/Rsun
  print, 'pixrs   : ', pixrs

  ; resize window [if image size has changed]
  if (xdim ne xdim_prev or ydim ne ydim_prev) then begin
    window, xsize=xdim + xb, ys=ydim + yb, retain=2
  endif

  print, 'xdim + xb: ', xdim + xb
  print, 'ydim + yb: ', ydim + yb

  xdim_prev = xdim
  ydim_prev = ydim

  ; annotate image
;   fits_annotate_kcor, hdu, xdim, ydim, xb, yb

  ; display image
  fitsdisp_kcor, fits_name, xdim_prev, ydim_prev, xb, yb, $
                 gif=gif, wmin=wmin, wmax=wmax, wexp=wexp

  ; use mouse to extract radius & position angle for cursor position
  mouse_pos_lab, xdim, ydim, xcen, ycen, pixrs, roll, $
                 pos=1, pfile=pfile, disp_label=keyword_set(nolabel) eq 0B

  ; write displayed image to a GIF file (if "gif" keyword is set)
  if (keyword_set(gif)) then begin
    gif_file = basename + '.gif'
    img_gif = tvrd()
    write_gif, gif_file, img_gif, redlut, greenlut, bluelut
  endif
end
