;+
; :Name: kcorqs.pro
;-------------------------------------------------------------------------------
; :Uses: Sort K-coronagraph L0 images according to quality assessment.
;-------------------------------------------------------------------------------
; :Author: Andrew L. Stanger   HAO/NCAR   08 October 2014
;  7 Nov 2014 Put category directories into a "q" sub-directory.
;  7 Nov 2014 use drad=30 (instead of 100) in find_image.pro.
; 18 Nov 2014 use kcor_find_image (replaces find_image).
; 24 Nov 2014 use bmax = 300 for sky brightness threshold.
; 04 Feb 2015 add append keyword for log file.
; 11 Feb 2015 Revised log output, removing all but essential information.
; 12 Feb 2015 Add TIC & TOC to get elapsed time.
; 02 Mar 2015 Modify to generate files containing lists of kcor L0 FITS files
;             which are labeled according to quality assessment.
; 03 Apr 2015 Do NOT create category sub-directories unles gif keyword is set.
; 06 Apr 2015 Do NOT delete list files.
; 07 Apr 2015 Move okf file to date directory (instead of copy).
;-------------------------------------------------------------------------------
; :Params: date [format: 'yyyymmdd']
;          list [format: 'list']
;-------------------------------------------------------------------------------
;-

PRO kcorqs, date, list=list, append=append, gif=gif

;--- Store initial system time.

;TIC, /PROFILER

TIC

;--- Establish list of files to process.

np = n_params ()
;PRINT, 'np: ', np

IF (np EQ 0) THEN $
BEGIN ;{
   PRINT, "kcorqs, 'yyyymmdd', list='list'"
   RETURN
END   ;}

IF (KEYWORD_SET (list)) THEN $
BEGIN ;{
   listfile = list
END  $ ;}
ELSE $
BEGIN  ;{
   listfile = 'list.q'
   spawn, 'ls *kcor.fts* > list.q'
END   ;}

;-------------------------------------------------------------------------------
;--- Define mask file name & directory names.
;-------------------------------------------------------------------------------

maskfile = '/hao/acos/sw/idl/kcor/pipe/kcor_mask.img'
log_file  = date + '_qs_' + listfile + '.log'

raw_dir  = '/hao/mlsodata1/Data/KCor/work/'	; base directory.
date_dir = raw_dir + date + '/'			; L0 fits files.
q_dir    = date_dir + 'q/'			; Quality directory.

cal_list  = 'cal.ls'
dev_list  = 'dev.ls'
brt_list  = 'brt.ls'
drk_list  = 'drk.ls'
cld_list  = 'cld.ls'
nsy_list  = 'nsy.ls'
sat_list  = 'sat.ls'
oka_list  = 'oka.ls'				; ok files: all or cumulative.

log_qpath = q_dir + log_file
cal_qpath = q_dir + cal_list
dev_qpath = q_dir + dev_list
brt_qpath = q_dir + brt_list
drk_qpath = q_dir + drk_list
cld_qpath = q_dir + cld_list
nsy_qpath = q_dir + nsy_list
sat_qpath = q_dir + sat_list
oka_qpath = q_dir + oka_list

okf_list  = 'list_okf'			; ok files for one invocation.
okf_qpath = q_dir    + okf_list		; ok fits file list in q    directory.
okf_dpath = date_dir + okf_list		; ok fits file list in date directory.

;--- Sub-directory names.

q_ok     = 'ok'
q_bad    = 'bad'
q_bright = 'bright'
q_cal    = 'cal'
q_cloud  = 'cloud'
q_dark   = 'dark'
q_dev    = 'dev'
q_noise  = 'noise'
q_sat    = 'sat'

q_dir_ok     = q_dir + 'ok/'				; ok   quality images.
q_dir_bad    = q_dir + 'bad/'				; bad  quality images.
q_dir_bright = q_dir + 'bright/'			; bright       images.
q_dir_cal    = q_dir + 'cal/'				; calibration images.
q_dir_cloud  = q_dir + 'cloud/'				; cloudy       images.
q_dir_dark   = q_dir + 'dark/'				; dark         images.
q_dir_dev    = q_dir + 'dev/'				; device images.
q_dir_noise  = q_dir + 'noise/'				; noisy        images.
q_dir_sat    = q_dir + 'sat/'				; saturated    images.

;q_dir_unk    = q_dir + 'unk/'				; unknown      images.
;q_dir_eng    = q_dir + 'eng/'				; engineering images.
;q_dir_ugly   = q_dir + 'ugly/'				; ugly quality images.

;-------------------------------------------------------------------------------
; Create sub-directories for image categories.
;-------------------------------------------------------------------------------

FILE_MKDIR, q_dir

IF (KEYWORD_SET (gif)) THEN $
BEGIN ;{
   FILE_MKDIR, q_dir_ok
   FILE_MKDIR, q_dir_bad
   FILE_MKDIR, q_dir_bright
   FILE_MKDIR, q_dir_cal
   FILE_MKDIR, q_dir_cloud
   FILE_MKDIR, q_dir_dark
   FILE_MKDIR, q_dir_dev
   FILE_MKDIR, q_dir_noise
   FILE_MKDIR, q_dir_sat

   ;FILE_MKDIR, q_dir_unk
   ;FILE_MKDIR, q_dir_eng
   ;FILE_MKDIR, q_dir_ugly
END   ;}

;-------------------------------------------------------------------------------
; Move to 'date' directory.
;-------------------------------------------------------------------------------

CD, current=start_dir			; Save current directory.
CD, date_dir				; Move to date directory.

doview = 0

;-------------------------------------------------------------------------------
; Open log file.
;-------------------------------------------------------------------------------

OPENW, UOKF, okf_qpath, /GET_LUN		; Open NEW file for writing.

IF (keyword_set (append)) THEN $		; Open to write in append mode.
BEGIN ;{					
   OPENW, ULOG, log_qpath, /append, /GET_LUN
   OPENW, UOKA, oka_qpath, /append, /GET_LUN

   OPENW, UBRT, brt_qpath, /append, /GET_LUN
   OPENW, UCAL, cal_qpath, /append, /GET_LUN
   OPENW, UCLD, cld_qpath, /append, /GET_LUN
   OPENW, UDEV, dev_qpath, /append, /GET_LUN
   OPENW, UDRK, drk_qpath, /append, /GET_LUN
   OPENW, UNSY, nsy_qpath, /append, /GET_LUN
   OPENW, USAT, sat_qpath, /append, /GET_LUN
END  $ ;}
ELSE $						; Open NEW file for writing.
BEGIN ;{
   OPENW, ULOG, log_qpath, /GET_LUN
   OPENW, UOKA, oka_qpath, /GET_LUN

   OPENW, UBRT, brt_qpath, /GET_LUN
   OPENW, UCAL, cal_qpath, /GET_LUN
   OPENW, UCLD, cld_qpath, /GET_LUN
   OPENW, UDEV, dev_qpath, /GET_LUN
   OPENW, UDRK, drk_qpath, /GET_LUN
   OPENW, UNSY, nsy_qpath, /GET_LUN
   OPENW, USAT, sat_qpath, /GET_LUN
END   ;}

;--- Print information.

PRINT, "kcorqs, '", date, "', list='", list, "'"
PRINT, 'start_dir:    ', start_dir
PRINT, 'raw_dir:      ', raw_dir

PRINTF, ULOG, "kcorqs, '", date, "', list='", list, "'"
PRINTF, ULOG, 'start_dir:    ', start_dir
PRINTF, ULOG, 'raw_dir:      ', raw_dir

IF (KEYWORD_SET (gif)) THEN $
BEGIN ;{
   PRINT, 'q_dir_ok:     ', q_dir_ok
   PRINT, 'q_dir_bad:    ', q_dir_bad
   PRINT, 'q_dir_bright: ', q_dir_bright
   PRINT, 'q_dir_cal:    ', q_dir_cal
   PRINT, 'q_dir_cloud:  ', q_dir_cloud
   PRINT, 'q_dir_dark:   ', q_dir_dark
   PRINT, 'q_dir_noise:  ', q_dir_noise
   PRINT, 'q_dir_sat:    ', q_dir_sat

   PRINTF, ULOG, 'q_dir_ok:     ', q_dir_ok
   PRINTF, ULOG, 'q_dir_bad:    ', q_dir_bad
   PRINTF, ULOG, 'q_dir_bright: ', q_dir_bright
   PRINTF, ULOG, 'q_dir_cal:    ', q_dir_cal
   PRINTF, ULOG, 'q_dir_cloud:  ', q_dir_cloud
   PRINTF, ULOG, 'q_dir_dark:   ', q_dir_dark
   PRINTF, ULOG, 'q_dir_noise:  ', q_dir_noise
   PRINTF, ULOG, 'q_dir_sat:    ', q_dir_sat

   ;PRINT, 'q_dir_unk:    ', q_dir_unk
   ;PRINTF, ULOG, 'q_dir_unk:    ', q_dir_unk
   ;PRINT, 'q_dir_ugly:   ', q_dir_ugly
   ;PRINTF, ULOG, 'q_dir_ugly:   ', q_dir_ugly
END   ;}

;-------------------------------------------------------------------------------
;--- Initialize count variables.
;-------------------------------------------------------------------------------

nokf = 0

nbrt = 0
ncal = 0
ncld = 0
ndev = 0
ndrk = 0
nnsy = 0
nsat = 0

;-------------------------------------------------------------------------------
; Read mask.
;-------------------------------------------------------------------------------

mask = 0
nx   = 1024
ny   = 1024
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

;lct,'/hao/acos/sw/colortable/quallab_ver2.lut' ; color table.
;lct,'/home/stanger/color/art.lut' ; color table.
;lct,'/home/stanger/color/bwyvid.lut' ; color table.
;lct,'/home/stanger/color/artvid.lut' ; color table.

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

;-------------------------------------------------------------------------------
; Open file containing a list of kcor L0 FITS files.
;-------------------------------------------------------------------------------

;PRINT,        'listfile: ', listfile
;PRINTF, ULOG, 'listfile: ', listfile

GET_LUN, ULIST
CLOSE,   ULIST
OPENR,   ULIST, listfile
l0_file = ''
num_img = 0

;-------------------------------------------------------------------------------
; Image file loop.
;-------------------------------------------------------------------------------

WHILE (NOT EOF (ULIST)) DO $
BEGIN ;{
   num_img += 1
   READF, ULIST, l0_file
   img = readfits (l0_file, hdu, /SILENT)	; Read FITS image & header.

   ;--- Get FITS header size.

;   finfo = FILE_INFO (l0_file)			; Get file information.
;   hdusize = SIZE (hdu)

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

;   PRINT,        '>>>>>>> ', l0_file, i, '  ', datatype, ' <<<<<<<'
;   PRINTF, ULOG, '>>>>>>> ', l0_file, i, '  ', datatype, ' <<<<<<<'

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
   ndim    = imgsize [0]		; # dimensions
   n1      = imgsize [1]		; dimension #1 size X: 1024
   n2      = imgsize [2]		; dimension #2 size Y: 1024
   n3      = imgsize [3]		; dimension #3 size pol state: 4
   n4      = imgsize [4]		; dimension #4 size camera: 2
   dtype   = imgsize [ndim + 1]		; data type
   npix    = imgsize [ndim + 2]		; # pixels
   nelem   = 1
   FOR j=1, ndim DO nelem *= imgsize [j]	; compute # elements in array.
   IF (ndim EQ 4) THEN nelem = n1 * n2 * n3 * n4

;   imgmin = min (img)
;   imgmax = max (img)

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

   year   = strmid (date_obs,  0, 4)
   month  = strmid (date_obs,  5, 2)
   day    = strmid (date_obs,  8, 2)
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

;   PRINT,        'pangle, bangle, rsun: ', pangle, bangle, rsun
;   PRINTF, ULOG, 'pangle, bangle, rsun: ', pangle, bangle, rsun

   pangle += 180.0		; adjust orientation for Kcor telescope.

   ;----------------------------------------------------------------------------
   ; Verify that image size agrees with FITS header information.
   ;----------------------------------------------------------------------------

   IF (nelem    NE  np)   THEN $
   BEGIN
      PRINT,        '*** nelem: ', nelem, 'NE np: ', np
      PRINTF, ULOG, '*** nelem: ', nelem, 'NE np: ', np
      CONTINUE
   END

   ;----------------------------------------------------------------------------
   ; Verify that image is Level 0.
   ;----------------------------------------------------------------------------

   IF (level    NE 'L0')  THEN $
   BEGIN
      PRINT,        '*** not Level 0 data ***'
      PRINTF, ULOG, '*** not Level 0 data ***'
      CONTINUE
   END

   ;----------------------------------------------------------------------------
   ; An image is assumed to be good unless conditions indicate otherwise.
   ;----------------------------------------------------------------------------

   cal    = 0			; >0 indicates a  "calibration" image.
   eng    = 0			; >0 indicates an "engineering' image.
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
   ; Check datatype.
   ;----------------------------------------------------------------------------

   IF (datatype EQ 'calibration') THEN  cal += 1
   IF (datatype EQ 'engineering') THEN  eng += 1
   IF (datatype EQ 'science')     THEN  sci += 1

   ;----------------------------------------------------------------------------
   ; Check mechanism positions.
   ;----------------------------------------------------------------------------

   ;--- Check diffuser position.

   IF (diffuser NE 'out') THEN $
   BEGIN
      dev  += 1
      diff += 1
      PRINT,        '+ + + ', l0_file, '       diffuser: ', diffuser
      PRINTF, ULOG, '+ + + ', l0_file, '       diffuser: ', diffuser
   END

   IF (qdiffuser NE 1) THEN $
   BEGIN
      PRINT,        'qdiffuser: ', qdiffuser
      PRINTF, ULOG, 'qdiffuser: ', qdiffuser
   END

   ;--- Check calpol position. 

   IF (calpol  NE 'out') THEN $
   BEGIN
      dev  += 1
      calp += 1
      PRINT,        '+ + + ', l0_file, '       calpol:   ', calpol
      PRINTF, ULOG, '+ + + ', l0_file, '       calpol:   ', calpol
   END

   IF (qcalpol  NE 1) THEN $
   BEGIN
      PRINT,        'qcalpol:   ', qcalpol
      PRINTF, ULOG, 'qcalpol:   ', qcalpol
   END

   ;--- Check dark shutter position.

   IF (darkshut NE 'out') THEN $
   BEGIN
      dev  += 1
      drks += 1
      PRINT,        '+ + + ', l0_file, '       darkshut: ', darkshut
      PRINTF, ULOG, '+ + + ', l0_file, '       darkshut: ', darkshut
   END

   IF (qdarkshut NE 1) THEN $
   BEGIN
      PRINT,        'qdarkshut: ', qdarkshut
      PRINTF, ULOG, 'qdarkshut: ', qdarkshut
   END

   ;--- Check cover position.

   IF (cover    NE 'out') THEN $
   BEGIN
      dev += 1
      cov += 1
      PRINT,        '+ + + ', l0_file, '       cover:    ', cover
      PRINTF, ULOG, '+ + + ', l0_file, '       cover:    ', cover
   END

   IF (qcover    NE 1) THEN $
   BEGIN
      PRINT,        'qcover:    ', qcover
      PRINTF, ULOG, 'qcover:    ', qcover
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

;   PRINTF, ULOG, 'xcen,ycen,rpix:      ', xcen, ycen, rdisc_pix
;   PRINT,        'xcen,ycen,rpix:      ', xcen, ycen, rdisc_pix

   ;--- Integer coordinates for disc center.

   ixcen = fix (xcen + 0.5)
   iycen = fix (ycen + 0.5)

;   PRINTF, ULOG, 'ixcen,iycen: ', ixcen, iycen
;   PRINT,        'ixcen,iycen: ', ixcen, iycen

   ;----------------------------------------------------------------------------
   ; Rotate image by P-angle.
   ; (No rotation for calibration or device-obscured images.)
   ;----------------------------------------------------------------------------

   IF (CAL GT 0 OR dev GT 0) THEN $
   BEGIN  ;{		
      pb0rot = pb0
      GOTO, NEXT
   END  $ ;}
   ELSE $
      pb0rot = rot (pb0, pangle, 1.0, xcen, ycen, cubic=-0.5, missing=0)

   ;----------------------------------------------------------------------------
   ; Bright sky check.
   ;----------------------------------------------------------------------------

   dobright = 1
   IF (dobright GT 0) THEN $
   BEGIN ;{
;      PRINT,        '~ ~ ~ Bright Sky check ~ ~ ~'
;      PRINTF, ULOG, '~ ~ ~ Bright Sky check ~ ~ ~'
;      bmax  = 77.0
;      rpixb = 296.0

;      bmax  = 175.0			; Brightness threshold.
;      bmax  = 220.0			; Brightness threshold.
;      bmax  = 250.0			; Brightness threshold.

      bmax  = 300.0			; Brightness threshold.
      rpixb = 450			; circle radius [pixels].
      dpx   = fix (cos (dp) * rpixb + axcen + 0.5005)
      dpy   = fix (sin (dp) * rpixb + aycen + 0.5005)

      brightave = total (pb0rot (dpx, dpy)) / nray
      brightpix = where (pb0rot (dpx, dpy) GE bmax)
      nelem = n_elements (brightpix)

      ;--- If too many pixels in circle exceed threshold, set bright = 1.

      bright = 0
      if (brightpix (0) NE -1) THEN $
      BEGIN ;{
;         PRINT, 'cloud check brightpix: ', brightpix
;         PRINT, 'cloud check bsize:     ', bsize
         bsize = SIZE (brightpix)
         if (bsize (1) GE (nray / 5)) THEN $
         BEGIN ;{
            bright = 1
;            PRINT,        'sky brightness radius, limit:', rpixb, bmax
;            PRINT,        'sky brightness image info: '
;            PRINT,        pb0rot (dpx, dpy)
;            PRINT,        'sky brightness brightpix: '
;            PRINT,        brightpix
;            PRINT,        'sky brightness average:    ', brightave
;
;            PRINTF, ULOG, 'sky brightness radius, limit: ', rpixb, bmax
;            PRINTF, ULOG, 'sky brightness image info: '
;            PRINTF, ULOG, pb0rot (dpx, dpy)
;            PRINTF, ULOG, 'sky brightness brightpix: '
;            PRINTF, ULOg, brightpix
;            PRINTF, ULOG, 'sky brightness average:    ', brightave

;            PRINT,        '* * * ', l0_file, '  ', $
;	                  rpixb, ' ring bright:   ', nelem
;            PRINTF, ULOG, '* * * ', l0_file, '  ', $
;	                  rpixb, ' ring bright:   ', nelem
         END   ;}
      END   ;}
   END   ;}

   ;----------------------------------------------------------------------------
   ; Saturation check.
   ;----------------------------------------------------------------------------

   chksat = 1
   IF (chksat GT 0) THEN $
   BEGIN ;{
;      PRINT, '~ ~ ~ Saturation check ~ ~ ~'
      smax  = 1000.0			; brightness threshold.
      rpixt = 215			; circle radius [pixels].
      dpx   = fix (cos (dp) * rpixt + axcen + 0.5005)
      dpy   = fix (sin (dp) * rpixt + aycen + 0.5005)

      satave = total (pb0rot (dpx, dpy)) / nray
      satpix = where (pb0rot (dpx, dpy) GE smax)
      nelem  = n_elements (satpix)

      ;--- if too many pixels are saturated, set sat = 1.

      sat = 0
      if (satpix (0) NE -1) THEN $
      BEGIN ;{
;          PRINT, 'saturation check satpix: ', satpix
;          PRINT, 'saturation check ssize:  ', ssize
         ssize = size (satpix)
	 if (ssize (1) GE (nray / 5)) THEN $
	 BEGIN ;{
	    sat = 1
;            PRINT,        'saturation radius, limit: ', rpixt, smax
;            PRINT,        'saturation image info: '
;            PRINT,        pb0rot (dpx, dpy)
;            PRINT,        'saturation average:   ', satave
;
;            PRINTF, ULOG, 'saturation radius, limit: ', rpixt, smax
;            PRINTF, ULOG, 'saturation image info: '
;            PRINTF, ULOG, pb0rot (dpx, dpy)
;            PRINTF, ULOG, 'saturation average:   ', satave

;	    PRINT,        '* * * ', l0_file, '  ', $
;	                  rpixt, ' ring saturated:', nelem
;	    PRINTF, ULOG, '* * * ', l0_file, '  ', $
;	                  rpixt, ' ring saturated:', nelem
	 END   ;}
      END   ;}
   END   ;}

   ;----------------------------------------------------------------------------
   ; Cloud check.
   ;----------------------------------------------------------------------------

   chkcloud = 1
   clo      = 0
   chi      = 0
   cloud    = 0
   IF (chkcloud GT 0) THEN $
   BEGIN ;{
;      PRINT, '~ ~ ~ Cloud check ~ ~ ~'
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

      ;--- If too many pixels are below lower limit, set clo = 1

      IF (cloudpixlo (0) NE -1) THEN $
      BEGIN ;{
         closize = size (cloudpixlo)

	 IF (closize (1) GE (nray / 5)) THEN $
	 BEGIN ;{
	    clo = 1
;            PRINT,        'cloud cmin, cmax, radius: ', cmin, cmax, rpixc
;            PRINT,        'cloud image info: '
;            PRINT,        pb0rot (dpx, dpy)
;            PRINT,        'cloud cloudpixlo: '
;            PRINT,        cloudpixlo
;            PRINT,        'cloud closize:    ', closize
;
;            PRINTF, ULOG, 'cloud cmin, cmaxm radius: ', cmin, cmax, rpixc
;            PRINTF, ULOG, 'cloud image info: '
;            PRINTF, ULOG, pb0rot (dpx, dpy)
;            PRINTF, ULOG, 'cloud cloudpixlo: '
;            PRINTF, ULOG, cloudpixlo
;            PRINTF, ULOG, 'cloud closize:    ', closize

;	    PRINT,        '* * * ', l0_file, '  ', $
;	                  rpixc, ' ring dark:     ', nelemlo
;	    PRINTF, ULOG, '* * * ', l0_file, '  ', $
;	                  rpixc, ' ring dark:     ', nelemlo
	 END   ;}
      END   ;}

      IF (cloudpixhi (0) NE -1) THEN $
      BEGIN ;{
         chisize = size (cloudpixhi)
;	 IF (chisize (1) GE (nray / 5) THEN $

	 IF (cave GE cmax) THEN $
	 BEGIN ;{
	    chi = 1
;            PRINT,        'cloud image info: '
;            PRINT,        pb0rot (dpx, dpy)
;            PRINT,        'cloud check cloudpixhi: '
;            PRINT,        cloudpixhi
;            PRINT,        'cloud check chisize:    ', chisize
;
;            PRINTF, ULOG, 'cloud image info: '
;            PRINTF, ULOG, pb0rot (dpx, dpy)
;            PRINTF, ULOG, 'cloud check cloudpixhi: '
;            PRINTF, ULOG, cloudpixhi
;            PRINTF, ULOG, 'cloud check chisize:    ', chisize

;	    PRINT,        '* * * ', l0_file, '  ', $
;	                  rpixb, ' ring bright:   ', nelemhi
;	    PRINTF, ULOG, '* * * ', l0_file, '  ', $
;	                  rpixb, ' ring bright:   ', nelemhi
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
;      PRINT, '~ ~ ~ Sobel check ~ ~ ~'
      nray  = 480
      acirc = !PI * 2.0 / float (nray)
      dp    = findgen (nray) * acirc
      dpx   = intarr (nray)
      dpy   = intarr (nray)

;      noise_diff_limit =  15.0
;      noise_diff_limit =  50.0		; difference threshold.

      noise_diff_limit =  70.0		; difference threshold.
      total_bad_limit  =  80		; total # bad pixel differences.

;      PRINT,        'noise_diff_limit, total_bad_limit: ', $
;                     noise_diff_limit, total_bad_limit
;      PRINTF, ULOG, 'noise_diff_limit, total_bad_limit: ', $
;                     noise_diff_limit, total_bad_limit

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

;            PRINT,        'rpixn: ', rpixn, ' noise diff:'
;            PRINT,        fix (kdiff (badpix))
;            PRINT,        'noise diff numbad: ', numbad
;
;            PRINTF, ULOG, 'rpixn: ', rpixn, ' noise diff: '
;            PRINTF, ULOG, fix (kdiff (badpix))
;            PRINTF, ULOG, 'noise diff numbad: ', numbad

	 END   ;}
      END   ;}

;      PRINT,        'noise total bad: ', total_bad
;      PRINTF, ULOG, 'noise total bad: ', total_bad
;      PRINT,        'noise bad limit: ', total_bad_limit
;      PRINTF, ULOG, 'noise bad limit: ', total_bad_limit

      ;--- If noise limit is exceeded, set bad = 1.

      IF (total_bad GE total_bad_limit) THEN $
      BEGIN ;{
         noise = 1
;	 PRINT,        '* * * ', l0_file, $
;	               '       noise limit exceeded:', total_bad_limit
;	 PRINTF, ULOG, '* * * ', l0_file, $
;	               '       noise limit exceeded:',  total_bad_limit
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

;   PRINT,        'imin/imax: ', imin, imax
;   PRINTF, ULOG, 'imin/imax: ', imin, imax

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

;   PRINT, 'rdisc_pix, rsunpix: ', rdisc_pix, rsunpix

   ;----------------------------------------------------------------------------
   ; Annotate image.
   ; Skip annotation (except file name) for calibration images.
   ;----------------------------------------------------------------------------

   IF (cal EQ 0 AND dev EQ 0) THEN $
   BEGIN
      ;--- Draw circle a 1.0 Rsun.

;      tvcircle, rsunpix, axcen, aycen,     0, /device, /fill ; 1.0 Rsun circle
;      tvcircle, rdisc_pix, axcen, aycen, red, /device	      ; occulter edge

      tvcircle, rdisc_pix, axcen, aycen, grey, /device, /fill ; occulter disc 
      tvcircle, rsunpix, axcen, aycen, yellow, /device        ; 1.0 Rsun circle
      tvcircle, rsunpix*3.0, axcen, aycen, grey, /device      ; 3.0 Rsun circle

      ;--- Draw "+" at sun center.

      plots, [ixcen-5, ixcen+5], [iycen, iycen], color=yellow, /device
      plots, [ixcen, ixcen], [iycen-5, iycen+5], color=yellow, /device

      IF (dev EQ 0) THEN $
         xyouts, 490, 1010, 'NORTH', color=green, charsize=1.0, /device
   END

   ;----------------------------------------------------------------------------
   ; Create GIF file name, draw circle (as needed).
   ;----------------------------------------------------------------------------

   fitsloc  = STRPOS (l0_file, '.fts')
   gif_file = 'kcor.gif'			; default gif file name.
   qual     = 'unk'

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
      qual = q_cal
      ncal += 1
      PRINTF, UCAL, l0_file
   END   $ ;}

   ELSE  $
   IF (dev GT 0) THEN $			; Device obscuration
   BEGIN   ;{
      gif_file = strmid (l0_file, 0, fitsloc) + '_m.gif' 
      gif_path = q_dir_dev + gif_file
      qual = q_dev
      ndev += 1
      PRINTF, UDEV, l0_file
   END   $ ;}

   ELSE  $
   IF (bright GT 0) THEN $		; Bright image.
   BEGIN   ;{
      tvcircle, rpixb,        axcen, aycen, red,    /device   ; bright   circle
      gif_file = strmid (l0_file, 0, fitsloc) + '_b.gif' 
      gif_path = q_dir_bright + gif_file
      qual = q_bright
      nbrt += 1
      PRINTF, UBRT, l0_file
   END   $ ;}

   ELSE  $
   IF (clo    GT 0) THEN $		; Dark image.
   BEGIN   ;{
      tvcircle, rpixc,        axcen, aycen, green,  /device   ; cloud    circle
      gif_file = strmid (l0_file, 0, fitsloc) + '_d.gif' 
      gif_path = q_dir_dark + gif_file
      qual = q_dark
      ndrk += 1
      PRINTF, UDRK, l0_file
   END   $ ;}

   ELSE  $
   IF (chi    GT 0) THEN $		; Cloudy image.
   BEGIN   ;{
      tvcircle, rpixc,        axcen, aycen, green,  /device   ; cloud    circle
      gif_file = strmid (l0_file, 0, fitsloc) + '_o.gif' 
      gif_path = q_dir_cloud + gif_file
      qual = q_cloud
      ncld += 1
      PRINTF, UCLD, l0_file
   END   $ ;}

   ELSE  $
   IF (sat    GT 0) THEN $		; Saturation.
   BEGIN   ;{
      tvcircle, rpixt,        axcen, aycen, blue,   /device   ; sat      circle
      gif_file = strmid (l0_file, 0, fitsloc) + '_t.gif' 
      gif_path = q_dir_sat   + gif_file
      qual = q_sat
      nsat += 1
      PRINTF, USAT, l0_file
   END   $ ;}

   ELSE  $
   IF (noise  GT 0) THEN $		; Noisy.
   BEGIN   ;{
      tvcircle, rpixn,        axcen, aycen, yellow, /device   ; noise    circle
      gif_file = strmid (l0_file, 0, fitsloc) + '_n.gif' 
      gif_path = q_dir_noise + gif_file
      qual = q_noise
      nnsy += 1
      PRINTF, UNSY, l0_file
   END   $ ;}

   ELSE  $				; Good image.
   BEGIN ;{
      gif_file = strmid (l0_file, 0, fitsloc) + '_g.gif'
      gif_path = q_dir_ok + gif_file
      qual = q_ok
      nokf += 1
      PRINTF, UOKF, l0_file
      PRINTF, UOKA, l0_file
   END   ;}

   ;----------------------------------------------------------------------------
   ; Write GIF file.
   ;----------------------------------------------------------------------------

   IF (KEYWORD_SET (gif)) THEN $
   BEGIN ;{
      xyouts, 4, ydim-20, gif_file, color=red, charsize=1.5, /device
      save = tvrd ()
      write_gif, gif_path, save, rlut, glut, blut

;      PRINT,        'gif_file: ', gif_file
;      PRINTF, ULOG, 'gif_file: ', gif_file
   END   ;}

   istring = string (format='(i5)', num_img)
   PRINT,        '>>>>> ', l0_file, istring, '  ', datatype, ' <<<<< ', qual
   PRINTF, ULOG, '>>>>> ', l0_file, istring, '  ', datatype, ' <<<<< ', qual

END   ;}

;-------------------------------------------------------------------------------
; End of image loop.
;-------------------------------------------------------------------------------

CLOSE, UCAL
CLOSE, UDEV
CLOSE, UBRT
CLOSE, UDRK
CLOSE, UCLD
CLOSE, USAT
CLOSE, UNSY
CLOSE, UOKF
CLOSE, UOKA

FREE_LUN, UCAL
FREE_LUN, UDEV
FREE_LUN, UBRT
FREE_LUN, UDRK
FREE_LUN, UCLD
FREE_LUN, USAT
FREE_LUN, UNSY
FREE_LUN, UOKF
FREE_LUN, UOKA

;--- Delete empty files.

;IF (ncal EQ 0) THEN FILE_DELETE, cal_qpath ELSE PRINTF, ULOG, 'ncal: ', ncal
;IF (ndev EQ 0) THEN FILE_DELETE, dev_qpath ELSE PRINTF, ULOG, 'ndev: ', ndev
;IF (nbrt EQ 0) THEN FILE_DELETE, brt_qpath ELSE PRINTF, ULOG, 'nbrt: ', nbrt
;IF (ndrk EQ 0) THEN FILE_DELETE, drk_qpath ELSE PRINTF, ULOG, 'ndrk: ', ndrk
;IF (ncld EQ 0) THEN FILE_DELETE, cld_qpath ELSE PRINTF, ULOG, 'ncld: ', ncld
;IF (nsat EQ 0) THEN FILE_DELETE, sat_qpath ELSE PRINTF, ULOG, 'nsat: ', nsat
;IF (nnsy EQ 0) THEN FILE_DELETE, nsy_qpath ELSE PRINTF, ULOG, 'nssy: ', nnsy
;IF (nokf EQ 0) THEN FILE_DELETE, okf_qpath ELSE PRINTF, ULOG, 'nokf: ', nokf

;--- Move 'okf_list' to 'date' directory.

;IF (FILE_TEST (okf_qpath)) THEN FILE_COPY, okf_qpath, okf_dpath, /overwrite
IF (FILE_TEST (okf_qpath)) THEN $
BEGIN
   PRINTF, ULOG, okf_qpath, ' --> ', okf_dpath
   FILE_MOVE, okf_qpath, okf_dpath, /overwrite
END

PRINT,        'nimg: ', num_img
PRINTF, ULOG, 'nimg: ', num_img

CD, start_dir
SET_PLOT, 'X'

;--- Get system time & compute elapsed time since "TIC" command.

qtime = TOC ()
PRINTF, ULOG, 'elapsed time: ', qtime
PRINTF, ULOG, qtime / num_img, ' sec/image'

PRINT,        '===== end ... kcorqs ====='
PRINTF, ULOG, '===== end ... kcorqs ====='
PRINTF, ULOG, '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -'

CLOSE,    ULIST
FREE_LUN, ULIST
CLOSE,    ULOG
FREE_LUN, ULOG 

END
