;+
; :Name: kcorq.pro
;-------------------------------------------------------------------------------
; :Uses: Sort K-coronagraph L0 images according to quality assessment.
;-------------------------------------------------------------------------------
; :Author: Andrew L. Stanger   HAO/NCAR   08 October 2014
;  7 Nov 2014 Put category directories into a "q" sub-directory.
;  7 Nov 2014 use drad=30 (instead of 100) in find_image.pro.
; 18 Nov 2014 use kcor_find_image (replaces find_image).
; 24 Nov 2014 use bmax = 300 for sky brightness threshold.
; 04 Feb 2015 add append keyword for log file.
;-------------------------------------------------------------------------------
; :Params: date [format: 'yyyymmdd']
;          list [format: 'list']
;-------------------------------------------------------------------------------
;-

PRO kcorq, date, list=list, append=append

;--- Establish list of files to process.

np = n_params ()
PRINT, 'np: ', np

IF (np EQ 0) THEN $
BEGIN ;{
   PRINT, "kcorq, 'yyyymmdd', list='list'"
   RETURN
END   ;}

IF (KEYWORD_SET (list)) THEN $
BEGIN ;{
   listfile = list
END  $ ;}
ELSE $
BEGIN ;{
   listfile = 'list.q'
   spawn, 'ls *kcor.fts* > list.q'
END   ;}

;-------------------------------------------------------------------------------
;--- Define mask file name & directory names.
;-------------------------------------------------------------------------------

maskfile = '/hao/acos/sw/idl/kcor/pipe/kcor_mask.img'

;l0_base       = '/home/stanger/data/kcor/raw/'
;l0_base       = '/hao/compdata1/Data/kcor/raw/'

l0_base       = '/hao/mlsodata1/Data/KCor/raw/'

l0_dir        = l0_base + date + '/'
q_dir         = l0_dir + 'q/'

q_dir_cal    = q_dir + 'cal/'
;q_dir_eng    = q_dir + 'eng/'

q_dir_dev    = q_dir + 'dev/'

q_dir_ok     = q_dir + 'ok/'
q_dir_bad    = q_dir + 'bad/'
;q_dir_ugly   = q_dir + 'ugly/'
q_dir_bright = q_dir + 'bright/'
q_dir_cloud  = q_dir + 'cloud/'
q_dir_dark   = q_dir + 'dark/'
q_dir_sat    = q_dir + 'sat/'
q_dir_noise  = q_dir + 'noise/'
q_dir_unk    = q_dir + 'unk/'

;-------------------------------------------------------------------------------
; Create sub-directories for image categories.
;-------------------------------------------------------------------------------

FILE_MKDIR, q_dir
FILE_MKDIR, q_dir_bright
FILE_MKDIR, q_dir_cal
FILE_MKDIR, q_dir_cloud
FILE_MKDIR, q_dir_dark
FILE_MKDIR, q_dir_dev
;FILE_MKDIR, q_dir_eng
FILE_MKDIR, q_dir_sat
FILE_MKDIR, q_dir_noise
FILE_MKDIR, q_dir_unk

FILE_MKDIR, q_dir_ok
FILE_MKDIR, q_dir_bad
;FILE_MKDIR, q_dir_ugly

;-------------------------------------------------------------------------------
; Move to L0 kcor directory.
;-------------------------------------------------------------------------------

CD, current=start_dir			; Save current directory.
CD, l0_dir				; Move to raw (L0) kcor directory.

logfile = date + '_q_' + listfile + '.log'

doview = 0

;-------------------------------------------------------------------------------
; Open log file.
;-------------------------------------------------------------------------------

GET_LUN, ULOG
CLOSE,   ULOG 
IF (keyword_set (append)) THEN $
   OPENW,   ULOG, q_dir + logfile, /append $
ELSE    $
   OPENW,   ULOG, q_dir + logfile

PRINT, "kcorq, '", date, "', list='", list, "'"
PRINT, 'start_dir:    ', start_dir
PRINT, 'l0_dir:       ', l0_dir
PRINT, 'q_dir_ok:     ', q_dir_ok
PRINT, 'q_dir_bad:    ', q_dir_bad
;PRINT, 'q_dir_ugly:   ', q_dir_ugly
PRINT, 'q_dir_bright: ', q_dir_bright
PRINT, 'q_dir_cloud:  ', q_dir_cloud
PRINT, 'q_dir_dark:   ', q_dir_dark
PRINT, 'q_dir_sat:    ', q_dir_sat
PRINT, 'q_dir_noise:  ', q_dir_noise
PRINT, 'q_dir_unk:    ', q_dir_unk

PRINTF, ULOG, "kcorq, '", date, "', list='", list, "'"
PRINTF, ULOG, 'start_dir:    ', start_dir
PRINTF, ULOG, 'l0_dir:       ', l0_dir
PRINTF, ULOG, 'q_dir_ok:     ', q_dir_ok
PRINTF, ULOG, 'q_dir_bad:    ', q_dir_bad
;PRINTF, ULOG, 'q_dir_ugly:   ', q_dir_ugly
PRINTF, ULOG, 'q_dir_bright: ', q_dir_bright
PRINTF, ULOG, 'q_dir_cloud:  ', q_dir_cloud
PRINTF, ULOG, 'q_dir_dark:   ', q_dir_dark
PRINTF, ULOG, 'q_dir_sat:    ', q_dir_sat
PRINTF, ULOG, 'q_dir_noise:  ', q_dir_noise
PRINTF, ULOG, 'q_dir_unk:    ', q_dir_unk

;-------------------------------------------------------------------------------
; Read mask.
;-------------------------------------------------------------------------------

mask = 0
nx = 1024
ny = 1024
mask = fltarr (nx, ny)

GET_LUN,  UMASK
CLOSE,    UMASK
OPENR,    UMASK, maskfile
READU,    UMASK, mask
CLOSE,    UMASK
FREE_LUN, UMASK

;-------------------------------------------------------------------------------
; Set up graphics window & color table.
;-------------------------------------------------------------------------------

set_plot, 'z'
; window, 0, xs=1024, ys=1024, retain=2
device, set_resolution=[1024,1024], decomposed=0, set_colors=256, $
        z_buffering=0
lct,'/hao/acos/sw/colortable/quallab_ver2.lut' ; color table.
lct,'/home/stanger/color/art.lut' ; color table.
lct,'/home/stanger/color/bwyvid.lut' ; color table.
lct,'/home/stanger/color/artvid.lut' ; color table.
lct,'/home/stanger/color/bwy5.lut' ; color table.

tvlct, rlut, glut, blut, /get

;-------------------------------------------------------------------------------
; Define color levels for annotation.
;-------------------------------------------------------------------------------

yellow = 250 
grey   = 251
blue   = 252
green  = 253
red    = 254
white  = 255

PRINT, 'listfile: ', listfile

GET_LUN, ULIST
CLOSE,   ULIST
OPENR,   ULIST, listfile
l0_file = ''
i = 0

;-------------------------------------------------------------------------------
; Image file loop.
;-------------------------------------------------------------------------------

WHILE (NOT EOF (ULIST)) DO $
BEGIN ;{
   i += 1
   READF, ULIST, l0_file

   finfo = FILE_INFO (l0_file)			; Get file information.

   img = readfits (l0_file, hdu, /SILENT)	; Read FITS image & header.

   ;--- Get FITS header size.

   hdusize = SIZE (hdu)

   ;--- Extract keyword parameters from FITS header.

   diffuser = ''
   calpol   = ''
   darkshut = ''
   cover    = ''
   occltrid = ''

   naxis    = SXPAR (hdu, 'NAXIS',    count=qnaxis)
   naxis1   = SXPAR (hdu, 'NAXIS1',   count=qnaxis1)
   naxis2   = SXPAR (hdu, 'NAXIS2',   count=qnaxis2)
   naxis3   = SXPAR (hdu, 'NAXIS3',   count=qnaxis3)
   naxis4   = SXPAR (hdu, 'NAXIS4',   count=qnaxis4)
   np       = naxis1 * naxis2 * naxis3 * naxis4 

   date_obs = SXPAR (hdu, 'DATE-OBS', count=qdate_obs)
   level    = SXPAR (hdu, 'LEVEL',    count=qlevel)

   bzero    = SXPAR (hdu, 'BZERO',    count=qbzero)
   bbscale  = SXPAR (hdu, 'BSCALE',   count=qbbscale)

   datatype = SXPAR (hdu, 'DATATYPE', count=qdatatype)

   diffuser = SXPAR (hdu, 'DIFFUSER', count=qdiffuser)
   calpol   = SXPAR (hdu, 'CALPOL',   count=qcalpol)
   darkshut = SXPAR (hdu, 'DARKSHUT', count=qdarkshut)
   cover    = SXPAR (hdu, 'COVER',    count=qcover)

   occltrid = SXPAR (hdu, 'OCCLTRID', count=qoccltrid)
   
   ;--- Determine occulter size in pixels.

   occulter = strmid (occltrid, 3, 5)	; Extract 5 characters from occltrid.
   IF (occulter EQ '991.6') THEN occulter =  991.6
   IF (occulter EQ '1018.') THEN occulter = 1018.9
   IF (occulter EQ '1006.') THEN occulter = 1006.9

   platescale = 5.643		; arsec/pixel.
   radius_guess = occulter / platescale		; occulter size [pixels].

   PRINTF, ULOG, '>>>>>>> ', l0_file, i, '   ', datatype, ' <<<<<<<'
   PRINT,        '>>>>>>> ', l0_file, i, '   ', datatype, ' <<<<<<<'
;   PRINT,        'file size: ', finfo.size
;   PRINTF, ULOG, 'file size: ', finfo.size

   ;----------------------------------------------------------------------------
   ; Define variables for azimuthal angle "scans".
   ;----------------------------------------------------------------------------

   nray = 36
   acirc = !PI * 2.0 / float (nray)
   dp    = findgen (nray) * acirc
   dpx   = intarr (nray)
   dpy   = intarr (nray)

   ;----------------------------------------------------------------------------
   ; Get FITS image size from image array.
   ;----------------------------------------------------------------------------

   n1 = 1
   n2 = 1
   n3 = 1
   n4 = 1
   imgsize = SIZE (img)			; get size of img array.
   ndim   = imgsize [0]			; # dimensions
   n1     = imgsize [1]			; dimension #1 size X: 1024
   n2     = imgsize [2]			; dimension #2 size Y: 1024
   n3     = imgsize [3]			; dimension #3 size pol state: 4
   n4     = imgsize [4]			; dimension #4 size camera: 2
   dtype  = imgsize [ndim + 1]		; data type
   npix   = imgsize [ndim + 2]		; # pixels
   nelem  = 1
   FOR j=1, ndim DO nelem *= imgsize [j]	; compute # elements in array.
   IF (ndim EQ 4) THEN nelem = n1 * n2 * n3 * n4

   imgmin = min (img)
   imgmax = max (img)

;   PRINTF, ULOG, 'imgmin,imgmax: ', imgmin, imgmax
;   PRINT,        'imgmin,imgmax: ', imgmin, imgmax

;   PRINTF, ULOG, 'size(img): ', imgsize
;   PRINT,        'size(img): ', imgsize
;   PRINTF, ULOG, 'nelem:     ', nelem
;   PRINT,        'nelem:     ', nelem

   ;----------------------------------------------------------------------------
   ; Define array center coordinates.
   ;----------------------------------------------------------------------------

   xdim = naxis1
   ydim = naxis2
   axcen = (xdim / 2.0) - 0.5		; x-axis array center.
   aycen = (ydim / 2.0) - 0.5		; y-axis array center.

   ;----------------------------------------------------------------------------
   ; Extract date items from FITS header parameter (DATE-OBS).
   ;----------------------------------------------------------------------------

   year   = strmid (date_obs, 0, 4)
   month  = strmid (date_obs, 5, 2)
   day    = strmid (date_obs, 8, 2)
   hour   = strmid (date_obs, 11, 2)
   minute = strmid (date_obs, 14, 2)
   second = strmid (date_obs, 17, 2)

   date = string (format='(a4)', year)   + '-' $
        + string (format='(a2)', month)  + '-' $
        + string (format='(a2)', day)    + 'T' $
	+ string (format='(a2)', hour)   + ':' $
	+ string (format='(a2)', minute) + ':' $
	+ string (format='(a2)', second)

   ;----------------------------------------------------------------------------
   ; Find ephemeris data (pangle,bangle ...) using solarsoft routine pb0r.
   ;----------------------------------------------------------------------------

   ephem = pb0r (date, /arcsec)
   pangle = ephem (0) 		; degrees.
   bangle = ephem (1)		; degrees.
   rsun   = ephem (2)		; solar radius (arcsec).

   PRINTF, ULOG, 'pangle, bangle, rsun: ', pangle, bangle, rsun
   PRINT,        'pangle, bangle, rsun: ', pangle, bangle, rsun

   pangle += 180.0		; adjust orientation for Kcor telescope.

   ;----------------------------------------------------------------------------
   ; Verify that image size agrees with FITS header information.
   ;----------------------------------------------------------------------------

   IF (nelem    NE  np)   THEN $
   BEGIN
      PRINTF, ULOG, '*** nelem: ', nelem, 'NE np: ', np
      PRINT,        '*** nelem: ', nelem, 'NE np: ', np
      CONTINUE
   END

   ;----------------------------------------------------------------------------
   ; Verify that image is Level 0.
   ;----------------------------------------------------------------------------

   IF (level    NE 'L0')  THEN $
   BEGIN
      PRINTF, ULOG, '*** not Level 0 data ***'
      PRINT,        '*** not Level 0 data ***'
      CONTINUE
   END

   ;----------------------------------------------------------------------------
   ; An image is assumed to be good unless conditions indicate otherwise.
   ;----------------------------------------------------------------------------

   cal    = 0			; >0 indicates a  "calibration" image.
   eng    = 0			; >0 indicates an "engineerinr' image.
   sci    = 0			; >0 indicates a  "science"     image.

   bad    = 0			; >0 indicates a  'bad'         image.
;   ugly   = 0			; >0 indicates an 'ugly'        image.

   dev    = 0			; >0 indicates a device obscures corona.
   diff   = 0			; >0 indicates diffuser is "mid" or "in".
   calp   = 0			; >0 indicates calpol   is "mid" or "in".
   drks   = 0			; >0 indicates calpol   is "mid" or "in".
   cov    = 0			; >0 indicates dover    is "mid" or "in".

   cloudy = 0			; >0 indicates a cloudy image.

   ;----------------------------------------------------------------------------
   ; Check datatype & mechanism positions.
   ;----------------------------------------------------------------------------

   IF (datatype EQ 'engineering') THEN $
   BEGIN
      eng += 1
;      PRINTF, ULOG, 'datatype:  ', datatype
;      PRINT,        'datatype:  ', datatype
   END

   IF (datatype EQ 'calibration') THEN $
   BEGIN
      cal += 1
;      PRINTF, ULOG, 'datatype:  ', datatype
;      PRINT,        'datatype:  ', datatype
   END

   IF (datatype EQ 'science') THEN $
   BEGIN
      sci += 1
;      PRINTF, ULOG, 'datatype:  ', datatype
;      PRINT,        'datatype:  ', datatype
   END

   ;--- Check diffuser position.

   IF (diffuser NE 'out') THEN $
   BEGIN
      dev  += 1
      diff += 1
      PRINTF, ULOG, '+++ diffuser:  ', diffuser
      PRINT,        '+++ diffuser:  ', diffuser
   END
   IF (qdiffuser NE 1) THEN $
   BEGIN
      PRINTF, ULOG, 'qdiffuser: ', qdiffuser
      PRINT,        'qdiffuser: ', qdiffuser
   END

   ;--- Check calpol position. 

   IF (calpol  NE 'out') THEN $
   BEGIN
      dev  += 1
      calp += 1
      PRINTF, ULOG, '+++ calpol:    ', calpol
      PRINT,        '+++ calpol:    ', calpol
   END
   IF (qcalpol  NE 1) THEN $
   BEGIN
      PRINTF, ULOG, 'qcalpol:   ', qcalpol
      PRINT,        'qcalpol:   ', qcalpol
   END

   ;--- Check darkshut position.

   IF (darkshut NE 'out') THEN $
   BEGIN
      dev  += 1
      drks += 1
      PRINTF, ULOG, '+++ darkshut:  ', darkshut
      PRINT,        '+++ darkshut:  ', darkshut
   END
   IF (qdarkshut NE 1) THEN $
   BEGIN
      PRINTF, ULOG, 'qdarkshut: ', qdarkshut
      PRINT,        'qdarkshut: ', qdarkshut
   END

   ;--- Check cover position.

   IF (cover    NE 'out') THEN $
   BEGIN
      dev += 1
      cov += 1
      PRINTF, ULOG, '+++ cover:     ', cover
      PRINT,        '+++cover:     ', cover
   END
   IF (qcover    NE 1) THEN $
   BEGIN
      PRINTF, ULOG, 'qcover:    ', qcover
      PRINT,        'qcover:    ', qcover
   END

   ;----------------------------------------------------------------------------
   ; Create "raw" pB image.
   ;----------------------------------------------------------------------------

   img = float (img)
   img00 = img (*, *, 0, 0)
   q0 = img (*, *, 0, 0) - img (*, *, 3, 0)	; Q camera 0
   u0 = img (*, *, 1, 0) - img (*, *, 2, 0)	; U camera 0
   pb0 = sqrt (q0*q0 + u0*u0)

   ;----------------------------------------------------------------------------
   ; Cloud test (using rectangular box).
   ; Extract 70x10 pixel rectangle from pb image.
   ; Find average intensity in box.
   ;----------------------------------------------------------------------------

;   cloud = pb0 (480:549, 10:19)
;   cloudave = total (cloud) / 700.0
;   cloudlimit = 43
;   cloudlimit = 85		; 1.0 msec exposure
;   cloudlimit = 95		; 1.1 msec exposure

;   if (cloudave LE 1.0) or (cloudave GE cloudlimit) then $
;   BEGIN
;      cloudy += 1
;      PRINTF, ULOG, 'cloudave: ', cloudave, ' cloudy: ', cloudy
;      PRINT,        'cloudave: ', cloudave, ' cloudy: ', cloudy
;   END

   ;----------------------------------------------------------------------------
   ; Find disc center.
   ;----------------------------------------------------------------------------

   rdisc_pix = 0.0
   IF (cal GT 0 OR dev GT 0 OR cloudy GT 0) THEN $ ; fixed location for center.
   BEGIN
      xcen = axcen - 4
      ycen = aycen - 4
      rdisc_pix = radius_guess
   END  $
   ELSE $					; Locate disc center.
   BEGIN ;{
      center_info = kcor_find_image (img00, chisq=chisq, radius_guess, $
                                     /center_guess)
      xcen = center_info (0)		; x offset
      ycen = center_info (1)		; y offset
      rdisc_pix = center_info (2)	; radius of occulter [pixels]
;      PRINTF, ULOG, 'center_info: ', center_info
;      PRINT,        'center_info: ', center_info
   END  ;}

   PRINTF, ULOG, 'xcen,ycen,rpix:      ', xcen, ycen, rdisc_pix
   PRINT,        'xcen,ycen,rpix:      ', xcen, ycen, rdisc_pix

   ;--- Integer coordinates for disc center.

   ixcen = fix (xcen + 0.5)
   iycen = fix (ycen + 0.5)

;   PRINTF, ULOG, 'ixcen,iycen: ', ixcen, iycen
;   PRINT,        'ixcen,iycen: ', ixcen, iycen

   ;----------------------------------------------------------------------------
   ; Rotate image by P-angle.
   ;----------------------------------------------------------------------------

   IF (CAL GT 0 OR dev GT 0) THEN $
   BEGIN  ;[
      pb0rot = pb0
      GOTO, NEXT
   END  $ ;]
   ELSE $
      pb0rot = rot (pb0, pangle, 1.0, xcen, ycen, cubic=-0.5, missing=0)

   ;----------------------------------------------------------------------------
   ; Bright sky check.
   ;----------------------------------------------------------------------------

   dobright = 1
   IF (dobright GT 0) THEN $
   BEGIN ;{
      PRINT, '~ ~ ~ Bright Sky check ~ ~ ~'
;      bmax  = 77.0
;      rpixb = 296.0

      bmax  = 175.0			; Brightness threshold.
      bmax  = 220.0			; Brightness threshold.
      bmax  = 250.0			; Brightness threshold.
      bmax  = 300.0			; Brightness threshold.
      rpixb = 450			; circle radius [pixels].
      dpx   = fix (cos (dp) * rpixb + axcen + 0.5005)
      dpy   = fix (sin (dp) * rpixb + aycen + 0.5005)

      brightave = total (pb0rot (dpx, dpy)) / nray
      brightpix = where (pb0rot (dpx, dpy) GE bmax)
      nelem = n_elements (brightpix)

      PRINT,        'sky brightness radius, limit:', rpixb, bmax
      PRINT,        'sky brightness image info: '
      PRINT,        pb0rot (dpx, dpy)
      PRINT,        'sky brightness brightpix: '
      PRINT,        brightpix
      PRINT,        'sky brightness average:    ', brightave

      PRINTF, ULOG, 'sky brightness radius, limit: ', rpixb, bmax
      PRINTF, ULOG, 'sky brightness image info: '
      PRINTF, ULOG, pb0rot (dpx, dpy)
      PRINTF, ULOG, 'sky brightness brightpix: '
      PRINTF, ULOg, brightpix
      PRINTF, ULOG, 'sky brightness average:    ', brightave

      ;--- If too many pixels in circle exceed threshold, set bright = 1

      bright = 0
      if (brightpix (0) NE -1) THEN $
      BEGIN ;{
         bsize = SIZE (brightpix)
         PRINT, 'cloud check brightpix: ', brightpix
         PRINT, 'cloud check bsize:     ', bsize
         if (bsize (1) GE (nray / 5)) THEN $
         BEGIN ;{
            bright = 1
            PRINT,        '*** ', rpixb, ' ring bright:', nelem
            PRINTF, ULOG, '*** ', rpixb, ' ring bright:', nelem
         END   ;}
      END   ;}
   END   ;}

   ;----------------------------------------------------------------------------
   ; Saturation check.
   ;----------------------------------------------------------------------------

   chksat = 1
   IF (chksat GT 0) THEN $
   BEGIN ;{
      PRINT, '~ ~ ~ Saturation check ~ ~ ~'
      smax  = 1000.0			; brightness threshold.
      rpixt = 215			; circle radius [pixels].
      dpx   = fix (cos (dp) * rpixt + axcen + 0.5005)
      dpy   = fix (sin (dp) * rpixt + aycen + 0.5005)

      satave = total (pb0rot (dpx, dpy)) / nray
      satpix = where (pb0rot (dpx, dpy) GE smax)
      nelem  = n_elements (satpix)

      PRINT,        'saturation radius, limit: ', rpixt, smax
      PRINT,        'saturation image info: '
      PRINT,        pb0rot (dpx, dpy)
      PRINT,        'saturation average:   ', satave

      PRINTF, ULOG, 'saturation radius, limit: ', rpixt, smax
      PRINTF, ULOG, 'saturation image info: '
      PRINTF, ULOG, pb0rot (dpx, dpy)
      PRINTF, ULOG, 'saturation average:   ', satave

      ;--- if too many pixels are saturated, set sat = 1.

      sat = 0
      if (satpix (0) NE -1) THEN $
      BEGIN ;{
         ssize = size (satpix)
	 PRINT, 'saturation check satpix: ', satpix
	 PRINT, 'saturation check ssize:  ', ssize
	 if (ssize (1) GE (nray / 5)) THEN $
	 BEGIN ;{
	    sat = 1
	    PRINT,        '*** ', rpixt, ' ring saturated:', nelem
	    PRINTF, ULOG, '*** ', rpixt, ' ring saturated:', nelem
	 END   ;}
      END   ;}
   END   ;}

   ;----------------------------------------------------------------------------
   ; Cloud check.
   ;----------------------------------------------------------------------------

   chkcloud = 1
   clo = 0
   chi = 0
   cloud = 0
   IF (chkcloud GT 0) THEN $
   BEGIN ;{
      PRINT, '~ ~ ~ Cloud check ~ ~ ~'
      cmax =  150.0
      cmax = 2200.0			; upper brightness threshold.
      cmin =  200.0			; lower brightness threshold.
      rpixc = 190			; circle radius [pixels].
      dpx  = fix (cos (dp) * rpixc + axcen + 0.5005)
      dpy  = fix (sin (dp) * rpixc + aycen + 0.5005)

      cave = total (pb0rot (dpx, dpy)) / nray
      cloudpixlo = where (pb0rot (dpx, dpy) LE cmin)
      cloudpixhi = where (pb0rot (dpx, dpy) GE cmax)
      nelemlo    = n_elements (cloudpixlo)
      nelemhi    = n_elements (cloudpixhi)

      PRINT,        'cloud cmin, cmax, radius: ', cmin, cmax, rpixc
      PRINTF, ULOG, 'cloud cmin, cmaxm radius: ', cmin, cmax, rpixc

      ;--- If too many pixels are below lower limit, set clo = 1

      IF (cloudpixlo (0) NE -1) THEN $
      BEGIN ;{
         closize = size (cloudpixlo)

         PRINT,        'cloud image info: '
	 PRINT,        pb0rot (dpx, dpy)
	 PRINT,        'cloud cloudpixlo: '
	 PRINT,        cloudpixlo
	 PRINT,        'cloud closize:    ', closize

         PRINTF, ULOG, 'cloud image info: '
	 PRINTF, ULOG, pb0rot (dpx, dpy)
	 PRINTF, ULOG, 'cloud cloudpixlo: '
	 PRINTF, ULOG, cloudpixlo
	 PRINTF, ULOG, 'cloud closize:    ', closize

	 IF (closize (1) GE (nray / 5)) THEN $
	 BEGIN ;{
	    clo = 1
	    PRINT,        '*** ', rpixc, ' ring dark:', nelemlo
	    PRINTF, ULOG, '*** ', rpixc, ' ring dark:', nelemlo
	 END   ;}
      END   ;}

      IF (cloudpixhi (0) NE -1) THEN $
      BEGIN ;{
         chisize = size (cloudpixhi)

         PRINT,        'cloud image info: '
	 PRINT,        pb0rot (dpx, dpy)
	 PRINT,        'cloud check cloudpixhi: '
	 PRINT,        cloudpixhi
	 PRINT,        'cloud check chisize:    ', chisize

         PRINTF, ULOG, 'cloud image info: '
	 PRINTF, ULOG, pb0rot (dpx, dpy)
	 PRINTF, ULOG, 'cloud check cloudpixhi: '
	 PRINTF, ULOG, cloudpixhi
	 PRINTF, ULOG, 'cloud check chisize:    ', chisize

;	 IF (chisize (1) GE (nray / 5) THEN $

	 IF (cave GE cmax) THEN $
	 BEGIN ;{
	    chi = 1
	    PRINT,        '*** ', rpixb, ' ring bright:', nelemhi
	    PRINTF, ULOG, '*** ', rpixb, ' ring bright:', nelemhi
	 END   ;}
      END   ;}

   cloud = clo + chi
   END   ;}

   ;----------------------------------------------------------------------------
   ; Do noise (sobel) test for "good" images.
   ;----------------------------------------------------------------------------

   chknoise = 1
   noise    = 0
   bad = bright + sat + clo + chi
   if ((chknoise GT 0) AND (bad EQ 0)) THEN $
   BEGIN ;{
      PRINT, '~ ~ ~ Sobel check ~ ~ ~'
      nray  = 480
      acirc = !PI * 2.0 / float (nray)
      dp    = findgen (nray) * acirc
      dpx   = intarr (nray)
      dpy   = intarr (nray)

;      noise_diff_limit =  15.0
;      noise_diff_limit =  50.0		; difference threshold.
      noise_diff_limit =  70.0		; difference threshold.
      total_bad_limit  =  80		; total # bad pixel differences.

      PRINT,        'noise_diff_limit, total_bad_limit: ', $
                     noise_diff_limit, total_bad_limit
      PRINTF, ULOG, 'noise_diff_limit, total_bad_limit: ', $
                     noise_diff_limit, total_bad_limit

      ;--- Radius loop.

      total_bad = 0
      rpixbeg = 276
      rpixend = 280
      FOR rpixn = rpixbeg, rpixend, 1 do $
      BEGIN ;{
         dpx = fix (cos (dp) * rpixn + axcen + 0.5005)
	 dpy = fix (sin (dp) * rpixn + aycen + 0.5005)
	 knoise = float (pb0rot (dpx, dpy))
	 kdiff  = abs (knoise (0:nray-2) - knoise (1:nray-1))
	 badpix = where (kdiff GT noise_diff_limit)

	 IF (doview GT 0) THEN $
	 BEGIN ;{
	    set_plot, 'X'
	    window, xsize=512, ysize=512, retain=2
	    tvlct, rlut, glut, blut
	    !p.multi = [0, 1, 2]
            plot, knoise, title = l0_file + ' noise'
	    plot, kdiff,  title = l0_file + ' diff noise'
	    cursor, _x, _y, 3, /normal
	    set_plot, 'Z'
	    device, set_resolution = [xdim, ydim], $
	            set_colors = 256, z_buffering = 0
	 END   ;}

	 ;--- The noise itself is not a reliable test.
	 ;    The difference of the noise works well.
	 
	 IF (badpix (0) NE -1) THEN $
	 BEGIN ;{
	    numbad     = n_elements (badpix)
	    total_bad += numbad

	    PRINT,        'rpixn: ', rpixn, ' noise diff:'
	    PRINT,        fix (kdiff (badpix))
	    PRINT,        'noise diff numbad: ', numbad

	    PRINTF, ULOG, 'rpixn: ', rpixn, ' noise diff: '
	    PRINTF, ULOG, fix (kdiff (badpix))
	    PRINTF, ULOG, 'noise diff numbad: ', numbad

	 END   ;}
      END   ;}

      PRINT,        'noise total bad: ', total_bad
      PRINTF, ULOG, 'noise total bad: ', total_bad
      PRINT,        'noise bad limit: ', total_bad_limit
      PRINTF, ULOG, 'noise bad limit: ', total_bad_limit

      ;--- If noise limit is exceeded, set bad = 1.

      IF (total_bad GE total_bad_limit) THEN $
      BEGIN ;{
         noise = 1
	 PRINT,        '*** noise limit exceeded.'
	 PRINTF, ULOG, '*** noise limit exceeded.'
      END   ;}
   END   ;}

   ;----------------------------------------------------------------------------
   ; Apply mask to restrict field of view (FOV).
   ;----------------------------------------------------------------------------

   NEXT:  $

   IF (cal GT 0 OR dev GT 0) THEN $
   BEGIN ;{
      pb0m = pb0rot
   END $ ;}
   ELSE $
   IF (nx NE xdim OR ny NE ydim) THEN $
   BEGIN ;{
      PRINT,  'Image dimensions incompatible with mask.', nx, ny, xdim, ydim
      PRINTF, ULOG, $
              'Image dimensions incompatible with mask.', nx, ny, xdim, ydim
      pb0m = pb0rot 
   END $  ;} 
   ELSE $
   BEGIN ;{
      pb0m = pb0rot * mask 
   END   ;}

   ;----------------------------------------------------------------------------
   ; Intensity scaling.
   ;----------------------------------------------------------------------------

   power = 0.9
   power = 0.8
   power = 0.5
   pb0s = pb0m ^ power		; apply exponential power.

   imin = min (pb0s)
   imax = max (pb0s)

;   imin = 10
;   imax = 3000 ^ power

   PRINT, 'imin/imax: ', imin, imax

   ;--- Scale pixel intensities.

;   IF ((cal EQ 0 AND dev EQ 0) OR (imax GT 250.0)) THEN $
;      pb0sb = bytscl (pb0s, min=imin, max=imax, top=250) $;linear scaling:0-250
;   ELSE $
;      pb0sb = byte (pb0s)

      pb0sb = bytscl (pb0s, min=imin, max=imax, top=250)  ;linear scaling:0-250

   ;----------------------------------------------------------------------------
   ; Display image.
   ;----------------------------------------------------------------------------

   tv, pb0sb

;   PRINT, '!D.N_COLORS: ', !D.N_COLORS

   rsunpix = rsun / platescale		; 1.0 Rsun [pixels]
   irsunpix = FIX (rsunpix + 0.5)	; 1.0 Rsun [integer pixels]
   PRINT, 'rdisc_pix, rsunpix: ', rdisc_pix, rsunpix

   ;----------------------------------------------------------------------------
   ; Annotate image.
   ; Skip annotation (except file name) for calibration images.
   ;----------------------------------------------------------------------------

   IF (cal EQ 0 AND dev EQ 0) THEN $
   BEGIN
      ;--- Draw circle a 1.0 Rsun.

      tvcircle, rdisc_pix, axcen, aycen, grey, /device, /fill  ; occulter disc 
;      tvcircle, rsunpix, axcen, aycen,   0, /device, /fill    ; 1.0 Rsun circle
      tvcircle, rsunpix, axcen, aycen, yellow, /device        ; 1.0 Rsun circle
;      tvcircle, rdisc_pix, axcen, aycen, red, /device	     ; occulter edge
      tvcircle, rsunpix*3.0, axcen, aycen, grey, /device    ; 3.0 Rsun circle


      ;--- Draw "+" at sun center.

      plots, [ixcen-5, ixcen+5], [iycen, iycen], color=yellow, /device
      plots, [ixcen, ixcen], [iycen-5, iycen+5], color=yellow, /device

      IF (dev EQ 0) THEN $
         xyouts, 490, 1010, 'NORTH', color=green, charsize=1.0, /device
   END

   ;----------------------------------------------------------------------------
   ; Create GIF file name, draw circle (as needed).
   ;----------------------------------------------------------------------------

   fitsloc = STRPOS (l0_file, '.fts')
   gif_file = 'kcor.gif'			; default gif file name.

;   xyouts, 4, ydim-20, gif_file, color=red, charsize=1.5, /device
;   save = tvrd ()

   ;--- Write GIF image.

;   IF (eng GT 0) THEN $			; Engineering
;   BEGIN   ;{
;      gif_file = strmid (l0_file, 0, fitsloc) + '_e.gif' 
;      gif_path = q_dir_eng + gif_file
;   END   $ ;}

;   ELSE	 $
   IF (cal GT 0) THEN $			; Calibration
   BEGIN   ;{
      gif_file = strmid (l0_file, 0, fitsloc) + '_c.gif' 
      gif_path = q_dir_cal + gif_file
   END   $ ;}

   ELSE  $
   IF (dev GT 0) THEN $			; Device obscuration
   BEGIN   ;{
      gif_file = strmid (l0_file, 0, fitsloc) + '_m.gif' 
      gif_path = q_dir_dev + gif_file
   END   $ ;}

   ELSE  $
   IF (bright GT 0) THEN $		; Bright image.
   BEGIN   ;{
      tvcircle, rpixb,        axcen, aycen, red,    /device   ; bright   circle
      gif_file = strmid (l0_file, 0, fitsloc) + '_b.gif' 
      gif_path = q_dir_bright + gif_file
   END   $ ;}

   ELSE  $
   IF (clo    GT 0) THEN $		; Dark image.
   BEGIN   ;{
      tvcircle, rpixc,        axcen, aycen, green,  /device   ; cloud    circle
      gif_file = strmid (l0_file, 0, fitsloc) + '_d.gif' 
      gif_path = q_dir_dark + gif_file
   END   $ ;}

   ELSE  $
   IF (chi    GT 0) THEN $		; Cloudy image.
   BEGIN   ;{
      tvcircle, rpixc,        axcen, aycen, green,  /device   ; cloud    circle
      gif_file = strmid (l0_file, 0, fitsloc) + '_o.gif' 
      gif_path = q_dir_cloud + gif_file
   END   $ ;}

   ELSE  $
   IF (sat    GT 0) THEN $		; Saturation.
   BEGIN   ;{
      tvcircle, rpixt,        axcen, aycen, blue,   /device   ; sat      circle
      gif_file = strmid (l0_file, 0, fitsloc) + '_t.gif' 
      gif_path = q_dir_sat   + gif_file
   END   $ ;}

   ELSE  $
   IF (noise  GT 0) THEN $		; Sobel difference.
   BEGIN   ;{
      tvcircle, rpixn,        axcen, aycen, yellow, /device   ; noise    circle
      gif_file = strmid (l0_file, 0, fitsloc) + '_n.gif' 
      gif_path = q_dir_noise + gif_file
   END   $ ;}

   ELSE  $				; Good image.
   BEGIN ;{
      gif_file = strmid (l0_file, 0, fitsloc) + '_g.gif'
      gif_path = q_dir_ok + gif_file
   END   ;}

   ;----------------------------------------------------------------------------
   ; Write GIF file.
   ;----------------------------------------------------------------------------

   xyouts, 4, ydim-20, gif_file, color=red, charsize=1.5, /device
   save = tvrd ()
   write_gif, gif_path, save, rlut, glut, blut
   PRINT,        'gif_file: ', gif_file
   PRINTF, ULOG, 'gif_file: ', gif_file

END   ;}
;-------------------------------------------------------------------------------
; End of image loop.
;-------------------------------------------------------------------------------

PRINT,        '>>>>>>> end... kcorq <<<<<<<'
PRINTF, ULOG, '>>>>>>> end... kcorq <<<<<<<'
PRINTF, ULOG, '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -'

CD, start_dir
SET_PLOT, 'X'

CLOSE,    ULIST
FREE_LUN, ULIST
CLOSE,    ULOG
FREE_LUN, ULOG 

END
