; docformat = 'rst'

;+
; Sort K-coronagraph L0 images according to quality assessment.
;
; :Author:
;   Andrew L. Stanger   HAO/NCAR   08 October 2014
;
; :History:
;    7 Nov 2014 Put category directories into a "q" sub-directory.
;    7 Nov 2014 use drad=30 (instead of 100) in find_image.pro.
;   18 Nov 2014 use kcor_find_image (replaces find_image).
;   24 Nov 2014 use bmax = 300 for sky brightness threshold.
;   04 Feb 2015 add append keyword for log file.
;   11 Feb 2015 Revised log output, removing all but essential information.
;   12 Feb 2015 Add TIC & TOC to get elapsed time.
;   02 Mar 2015 Modify to generate files containing lists of kcor L0 FITS files
;               which are labeled according to quality assessment.
;   03 Apr 2015 Do NOT create category sub-directories unles gif keyword is set.
;   06 Apr 2015 Do NOT delete list files.
;   07 Apr 2015 Move okf file to date directory (instead of copy).
;   10 Apr 2015 Copy calibration images to /hao/mlsodata1/Data/KCor/cal/yyyymmdd.
;   13 Apr 2015 change log file name: 'yyyymmdd_qsc_*.log'
;   15 Apr 2015 Add exposure time to log.
;               Replace "dark" quality category with "dim" to distinguish between
;               a dim coronal image and a dark current image.
;   27 Apr 2015 Fixed the summary labels.  The drk & cov needed to be swapped.
;   12 Jan 2016 Fix path names for gif sub-directories.
;   26 Jan 2016 Color table location: /hao/acos/sw/idl/color.
;
; :Params:
;   date : in, required, type=string
;     format: 'yyyymmdd'
;
; :Keywords:
;   append : in, optional, type=boolean
;     if set, append log information to existing log file
;   gif : in, optional, type=boolean
;     if set, produce raw GIF images
;   list : in, required, type=strarr
;     list of files to process
;   run : in, required, type=object
;     `kcor_run` object
;-
pro kcorqsc, date, list=list, append=append, gif=gif, run=run
  compile_opt strictarr

  ; store initial system time
  tic

  maskfile = filepath('kcor_mask.img', root=mg_src_root())

  cal_path  = run.cal_basedir   ; calibration base directory.

  ; L0 fits files.
  date_dir   = filepath(date, root=run.raw_basedir)
  date_path  = date_dir

  ; calibration date directory.
  cdate_dir  = filepath(date, root=cal_path)
  cdate_path = cdate_dir + '/'

  q_dir      = date_path + 'q'		; Quality directory.
  q_path     = q_dir + '/'

  cal_list  = 'cal.ls'
  dev_list  = 'dev.ls'
  brt_list  = 'brt.ls'
  dim_list  = 'dim.ls'
  cld_list  = 'cld.ls'
  nsy_list  = 'nsy.ls'
  sat_list  = 'sat.ls'
  oka_list  = 'oka.ls'   ; ok files: all or cumulative.

  cal_qpath = q_path + cal_list
  dev_qpath = q_path + dev_list
  brt_qpath = q_path + brt_list
  dim_qpath = q_path + dim_list
  cld_qpath = q_path + cld_list
  nsy_qpath = q_path + nsy_list
  sat_qpath = q_path + sat_list
  oka_qpath = q_path + oka_list

  okf_list  = 'list_okf'			 ; ok files for one invocation.
  okf_qpath = filepath(okf_list, root=q_path)    ; ok fits file list in q    directory.
  okf_dpath = filepath(okf_list, root=date_path) ; ok fits file list in date directory.

  ;--- Sub-directory names.

  q_ok  = 'ok'
  q_bad = 'bad'
  q_brt = 'brt'
  q_cal = 'cal'
  q_cld = 'cld'
  q_dim = 'dim'
  q_dev = 'dev'
  q_nsy = 'nsy'
  q_sat = 'sat'

  q_dir_ok  = q_path + q_ok  + '/'   ; ok quality images
  q_dir_bad = q_path + q_bad + '/'   ; bad quality images
  q_dir_brt = q_path + q_brt + '/'   ; bright images
  q_dir_cal = q_path + q_cal + '/'   ; calibration images
  q_dir_cld = q_path + q_cld + '/'   ; cloudy images
  q_dir_dim = q_path + q_dim + '/'   ; dim images
  q_dir_dev = q_path + q_dev + '/'   ; device images
  q_dir_nsy = q_path + q_nsy + '/'   ; noisy images
  q_dir_sat = q_path + q_sat + '/'   ; saturated images

  ;q_dir_unk    = q_path + 'unk/'    ; unknown images
  ;q_dir_eng    = q_path + 'eng/'    ; engineering images
  ;q_dir_ugly   = q_path + 'ugly/'   ; ugly quality images

  ; create sub-directories for image categories
  file_mkdir, q_dir
  file_mkdir, cdate_dir

  if (keyword_set(gif)) then begin
    file_mkdir, q_dir_ok
    file_mkdir, q_dir_bad
    file_mkdir, q_dir_brt
    file_mkdir, q_dir_cal
    file_mkdir, q_dir_cld
    file_mkdir, q_dir_dim
    file_mkdir, q_dir_dev
    file_mkdir, q_dir_nsy
    file_mkdir, q_dir_sat

    ;file_mkdir, q_dir_unk
    ;file_mkdir, q_dir_eng
    ;file_mkdir, q_dir_ugly
  endif

  ; move to 'date' directory
  cd, current=start_dir   ; save current directory
  cd, date_dir            ; move to date directory

  doview = 0

  ; open log file
  openw, uokf, okf_qpath, /get_lun   ; open new file for writing

  ; open to write in append mode
  if (keyword_set(append)) then begin
    openw, uoka, oka_qpath, /append, /get_lun

    openw, ubrt, brt_qpath, /append, /get_lun
    openw, ucal, cal_qpath, /append, /get_lun
    openw, ucld, cld_qpath, /append, /get_lun
    openw, udev, dev_qpath, /append, /get_lun
    openw, udim, dim_qpath, /append, /get_lun
    openw, unsy, nsy_qpath, /append, /get_lun
    openw, usat, sat_qpath, /append, /get_lun
  endif else begin   ; open NEW file for writing
    openw, uoka, oka_qpath, /get_lun

    openw, ubrt, brt_qpath, /get_lun
    openw, ucal, cal_qpath, /get_lun
    openw, ucld, cld_qpath, /get_lun
    openw, udev, dev_qpath, /get_lun
    openw, udim, dim_qpath, /get_lun
    openw, unsy, nsy_qpath, /get_lun
    openw, usat, sat_qpath, /get_lun
  endelse

  ; print information
  mg_log, 'starting quality for %s', date, name='kcor/rt', /info

  if (keyword_set(gif)) then begin
    mg_log, 'q_dir_ok: %s', q_dir_ok, name='kcor/rt', /debug
    mg_log, 'q_dir_bad: %s', q_dir_bad, name='kcor/rt', /debug
    mg_log, 'q_dir_brt: %s', q_dir_brt, name='kcor/rt', /debug
    mg_log, 'q_dir_cal: %s', q_dir_cal, name='kcor/rt', /debug
    mg_log, 'q_dir_cld: %s', q_dir_cld, name='kcor/rt', /debug
    mg_log, 'q_dir_dim: %s', q_dir_dim, name='kcor/rt', /debug
    mg_log, 'q_dir_nsy: %s', q_dir_nsy, name='kcor/rt', /debug
    mg_log, 'q_dir_sat: %s', q_dir_sat, name='kcor/rt', /debug
  endif

  ; initialize count variables
  nokf = 0

  nbrt = 0
  ncal = 0
  ncld = 0
  ndev = 0
  ndim = 0
  nnsy = 0
  nsat = 0

  ; read mask
  mask = 0
  nx   = 1024
  ny   = 1024
  mask = fltarr(nx, ny)

  openr, umask, maskfile, /get_lun
  readu, umask, mask
  free_lun, umask

  ; set up graphics window & color table
  set_plot, 'z'
  ; window, 0, xs=1024, ys=1024, retain=2

  device, set_resolution=[1024, 1024], decomposed=0, set_colors=256, $
          z_buffering=0

  ;lct, '/hao/acos/sw/idl/color/quallab_ver2.lut'   ; color table.
  ;lct, '/hao/acos/sw/idl/color/art.lut'            ; color table.
  ;lct, '/hao/acos/sw/idl/color/bwyvid.lut'         ; color table.
  ;lct, '/hao/acos/sw/idl/color/artvid.lut'         ; color table.

  lct, '/hao/acos/sw/idl/color/bwy5.lut'   ; color table.

  tvlct, rlut, glut, blut, /get

  ; define color levels for annotation
  yellow = 250 
  grey   = 251
  blue   = 252
  green  = 253
  red    = 254
  white  = 255

  ; open file containing a list of kcor L0 FITS files
  header = 'file name                datatype    exp  cov drk dif pol angle  qual'
  mg_log, header, name='kcor/rt', /debug

  get_lun, ulist
  close,   ulist
  openr,   ulist, listfile
  l0_file = ''
  num_img = 0

  ; image file loop
  while (not eof(ulist)) do begin
    num_img += 1
    readf, ulist, l0_file
    img = readfits(l0_file, hdu, /silent)   ; read fits image & header

    ; get FITS header size

    ; finfo = file_info(l0_file)   ; get file information
    ; hdusize = size(hdu)

    ; extract keyword parameters from FITS header
    diffuser = ''
    calpol   = ''
    darkshut = ''
    cover    = ''
    occltrid = ''

    naxis    = sxpar(hdu, 'NAXIS',    count=qnaxis)
    naxis1   = sxpar(hdu, 'NAXIS1',   count=qnaxis1)
    naxis2   = sxpar(hdu, 'NAXIS2',   count=qnaxis2)
    naxis3   = sxpar(hdu, 'NAXIS3',   count=qnaxis3)
    naxis4   = sxpar(hdu, 'NAXIS4',   count=qnaxis4)
    np       = naxis1 * naxis2 * naxis3 * naxis4 

    date_obs = sxpar(hdu, 'DATE-OBS', count=qdate_obs)
    level    = sxpar(hdu, 'LEVEL',    count=qlevel)

    bzero    = sxpar(hdu, 'BZERO',    count=qbzero)
    bbscale  = sxpar(hdu, 'BSCALE',   count=qbbscale)

    datatype = sxpar(hdu, 'DATATYPE', count=qdatatype)

    diffuser = sxpar(hdu, 'DIFFUSER', count=qdiffuser)
    calpol   = sxpar(hdu, 'CALPOL',   count=qcalpol)
    calpang  = sxpar(hdu, 'CALPANG',  count=qcalpang)
    darkshut = sxpar(hdu, 'DARKSHUT', count=qdarkshut)
    exptime  = sxpar(hdu, 'EXPTIME',  count=qexptime)
    cover    = sxpar(hdu, 'COVER',    count=qcover)

    occltrid = sxpar(hdu, 'OCCLTRID', count=qoccltrid)

    ; determine occulter size in pixels

    occulter = strmid(occltrid, 3, 5)   ; extract 5 characters from occltrid
    if (occulter eq '991.6') then occulter =  991.6
    if (occulter eq '1018.') then occulter = 1018.9
    if (occulter eq '1006.') then occulter = 1006.9

    platescale = 5.643   ; arsec/pixel
    radius_guess = occulter / platescale   ; occulter size [pixels]

    ; define variables for azimuthal angle "scans"
    nray  = 36
    acirc = !pi * 2.0 / float(nray)
    dp    = findgen(nray) * acirc
    dpx   = intarr(nray)
    dpy   = intarr(nray)

    ; get FITS image size from image array

    n1 = 1
    n2 = 1
    n3 = 1
    n4 = 1
    imgsize = size(img)            ; get size of img array
    ndim    = imgsize [0]          ; # dimensions
    n1      = imgsize [1]          ; dimension #1 size X: 1024
    n2      = imgsize [2]          ; dimension #2 size Y: 1024
    n3      = imgsize [3]          ; dimension #3 size pol state: 4
    n4      = imgsize [4]          ; dimension #4 size camera: 2
    dtype   = imgsize [ndim + 1]   ; data type
    npix    = imgsize [ndim + 2]   ; # pixels
    nelem   = 1
    for j = 1, ndim do nelem *= imgsize[j]   ; compute # elements in array
    if (ndim eq 4) then nelem = n1 * n2 * n3 * n4

    ; imgmin = min(img)
    ; imgmax = max(img)

    ; define array center coordinates
    xdim = naxis1
    ydim = naxis2
    axcen = xdim / 2.0 - 0.5   ; x-axis array center
    aycen = ydim / 2.0 - 0.5   ; y-axis array center

    ; extract date items from FITS header parameter (DATE-OBS)
    year   = strmid(date_obs,  0, 4)
    month  = strmid(date_obs,  5, 2)
    day    = strmid(date_obs,  8, 2)
    hour   = strmid(date_obs, 11, 2)
    minute = strmid(date_obs, 14, 2)
    second = strmid(date_obs, 17, 2)

    date = string(year, month, day, hour, minute, second, $
                  format='(%"%s-%s-%sT%s:%s:%s")')

    ; find ephemeris data (pangle,bangle ...) using solarsoft routine pb0r
    ephem = pb0r(date, /arcsec)
    pangle = ephem[0]   ; degrees
    bangle = ephem[1]   ; degrees
    rsun   = ephem[2]   ; solar radius (arcsec)

    pangle += 180.0   ; adjust orientation for Kcor telescope

    ; verify that image size agrees with FITS header information
    if (nelem ne np)   then begin
      mg_log, 'nelem: %d, ne np: %d', nelem, np, name='kcor/rt', /warn
      continue
    endif

    ; verify that image is Level 0
    if (level ne 'l0')  then begin
      mg_log, 'not level 0 data', name='kcor/rt', /warn
      continue
    endif

    ; an image is assumed to be good unless conditions indicate otherwise
    cal    = 0   ; >0 indicates a  "calibration" image
    eng    = 0   ; >0 indicates an "engineering' image
    sci    = 0   ; >0 indicates a  "science"     image

    bad    = 0   ; >0 indicates a  'bad'         image
    ; ugly   = 0   ; >0 indicates an 'ugly'        image

    dev    = 0   ; >0 indicates a device obscures corona
    diff   = 0   ; >0 indicates diffuser is "mid" or "in"
    calp   = 0   ; >0 indicates calpol   is "mid" or "in"
    drks   = 0   ; >0 indicates calpol   is "mid" or "in"
    cov    = 0   ; >0 indicates dover    is "mid" or "in"

    cloudy = 0   ; >0 indicates a cloudy image

    ; check datatype
    if (datatype eq 'calibration') then  cal += 1
    if (datatype eq 'engineering') then  eng += 1
    if (datatype eq 'science')     then  sci += 1

    ; check mechanism positions

    ; check diffuser position

    if (diffuser ne 'out') then begin
      dev  += 1
      diff += 1
    endif

    if (qdiffuser ne 1) then begin
      ; print,        'qdiffuser: ', qdiffuser
      ; printf, ulog, 'qdiffuser: ', qdiffuser
    endif

    ; check calpol position
    if (calpol  ne 'out') then begin
      dev  += 1
      calp += 1
      ; calpang_str = string (format='(f7.2)', calpang)
      ; PRINT,        '+ + + ', l0_file, '                     calpol:   ', $
      ; calpol, calpang_str
      ; PRINTF, ULOG, '+ + + ', l0_file, '                     calpol:   ', $
      ; calpol, calpang_str
    endif

    if (qcalpol  ne 1) then begin
      ; print,        'qcalpol:   ', qcalpol
      ; printf, ulog, 'qcalpol:   ', qcalpol
    endif

    ; check dark shutter position
    if (darkshut ne 'out') then begin
      dev  += 1
      drks += 1
      ; print,        '+ + + ', l0_file, '                     darkshut: ', darkshut
      ; printf, ulog, '+ + + ', l0_file, '                     darkshut: ', darkshut
    endif

    if (qdarkshut ne 1) then begin
      ; print,        'qdarkshut: ', qdarkshut
      ; printf, ulog, 'qdarkshut: ', qdarkshut
    endif

    ; check cover position
    if (cover    ne 'out') then begin
      dev += 1
      cov += 1
      ; print,        '+ + + ', l0_file, '                     cover:    ', cover
      ; printf, ulog, '+ + + ', l0_file, '                     cover:    ', cover
    endif

    if (qcover    ne 1) then begin
      ; print,        'qcover:    ', qcover
      ; printf, ulog, 'qcover:    ', qcover
    endif

    ; create "raw" pB image
    img = float(img)
    img00 = img[*, *, 0, 0]
    q0 = img[*, *, 0, 0] - img[*, *, 3, 0]   ; Q camera 0
    u0 = img[*, *, 1, 0] - img[*, *, 2, 0]   ; U camera 0
    pb0 = sqrt(q0 * q0 + u0 * u0)

    ;----------------------------------------------------------------------------
    ; Cloud test (using rectangular box).
    ; Extract 70x10 pixel rectangle from pb image.
    ; Find average intensity in box.
    ;----------------------------------------------------------------------------

    ; cloud = pb0[480:549, 10:19]
    ; cloudave = total(cloud) / 700.0
    ; cloudlimit = 43
    ; cloudlimit = 85   ; 1.0 msec exposure
    ; cloudlimit = 95   ; 1.1 msec exposure

    ; if ((cloudave le 1.0) or (cloudave ge cloudlimit)) then begin
    ;   cloudy += 1
    ;   printf, ulog, 'cloudave: ', cloudave, ' cloudy: ', cloudy
    ;   print,        'cloudave: ', cloudave, ' cloudy: ', cloudy
    ; end

    ; find disc center
    rdisc_pix = 0.0
    if (cal gt 0 or dev gt 0 or cloudy gt 0) then begin  ; fixed location for center
      xcen = axcen - 4
      ycen = aycen - 4
      rdisc_pix = radius_guess
    end else begin   ; locate disc center
      center_info = kcor_find_image(img00, radius_guess, chisq=chisq, $
                                    /center_guess)
      xcen = center_info[0]        ; x offset
      ycen = center_info[1]        ; y offset
      rdisc_pix = center_info[2]   ; radius of occulter [pixels]
      ; printf, ulog, 'center_info: ', center_info
      ; print,        'center_info: ', center_info
    endelse

    ; printf, ulog, 'xcen,ycen,rpix:      ', xcen, ycen, rdisc_pix
    ; print,        'xcen,ycen,rpix:      ', xcen, ycen, rdisc_pix

    ; integer coordinates for disc center

    ixcen = fix(xcen + 0.5)
    iycen = fix(ycen + 0.5)

    ; printf, ulog, 'ixcen,iycen: ', ixcen, iycen
    ; print,        'ixcen,iycen: ', ixcen, iycen

    ; rotate image by P-angle
    ; (No rotation for calibration or device-obscured images.)

    if (cal gt 0 or dev gt 0) then begin
      pb0rot = pb0
      goto, next
    endif else begin
      pb0rot = rot(pb0, pangle, 1.0, xcen, ycen, cubic=-0.5, missing=0)
    endelse

    ; bright sky check
    dobright = 1
    if (dobright gt 0) then begin
      ; print,        '~ ~ ~ bright sky check ~ ~ ~'
      ; printf, ulog, '~ ~ ~ bright sky check ~ ~ ~'
      ; bmax  = 77.0
      ; rpixb = 296.0

      ; bmax  = 175.0   ; brightness threshold
      ; bmax  = 220.0   ; brightness threshold
      ; bmax  = 250.0   ; brightness threshold

      bmax  = 300.0     ; brightness threshold
      rpixb = 450       ; circle radius [pixels]
      dpx   = fix(cos(dp) * rpixb + axcen + 0.5005)
      dpy   = fix(sin(dp) * rpixb + aycen + 0.5005)

      brightave = total(pb0rot[dpx, dpy]) / nray
      brightpix = where(pb0rot[dpx, dpy] ge bmax)
      nelem = n_elements(brightpix)

      ; if too many pixels in circle exceed threshold, set bright = 1

      bright = 0
      if (brightpix (0) NE -1) THEN BEGIN
        ; print, 'cloud check brightpix: ', brightpix
        ; print, 'cloud check bsize:     ', bsize
        bsize = size(brightpix)
        if (bsize[1] ge (nray / 5)) then begin
          bright = 1
          ; print,        'sky brightness radius, limit:', rpixb, bmax
          ; print,        'sky brightness image info: '
          ; print,        pb0rot[dpx, dpy]
          ; print,        'sky brightness brightpix: '
          ; print,        brightpix
          ; print,        'sky brightness average:    ', brightave
          ;
          ; printf, ulog, 'sky brightness radius, limit: ', rpixb, bmax
          ; printf, ulog, 'sky brightness image info: '
          ; printf, ulog, pb0rot[dpx, dpy]
          ; printf, ulog, 'sky brightness brightpix: '
          ; printf, ulog, brightpix
          ; printf, ulog, 'sky brightness average:    ', brightave

          ; print,        '* * * ', l0_file, '  ', rpixb, ' ring bright:   ', nelem
          ; printf, ulog, '* * * ', l0_file, '  ', rpixb, ' ring bright:   ', nelem
        endif
      endif
    endif

    ; saturation check
    chksat = 1
    if (chksat gt 0) then begin
      ; print, '~ ~ ~ saturation check ~ ~ ~'
      smax  = 1000.0   ; brightness threshold.
      rpixt = 215      ; circle radius [pixels].
      dpx   = fix(cos(dp) * rpixt + axcen + 0.5005)
      dpy   = fix(sin(dp) * rpixt + aycen + 0.5005)

      satave = total(pb0rot[dpx, dpy]) / nray
      satpix = where(pb0rot[dpx, dpy] ge smax)
      nelem  = n_elements(satpix)

      ;--- if too many pixels are saturated, set sat = 1.

      sat = 0
      if (satpix (0) ne -1) then begin
        ; print, 'saturation check satpix: ', satpix
        ; print, 'saturation check ssize:  ', ssize
        ssize = size(satpix)
        if (ssize (1) ge (nray / 5)) then begin
          sat = 1
          ; print,        'saturation radius, limit: ', rpixt, smax
          ; print,        'saturation image info: '
          ; print,        pb0rot[dpx, dpy]
          ; print,        'saturation average:   ', satave
          ;
          ; printf, ulog, 'saturation radius, limit: ', rpixt, smax
          ; printf, ulog, 'saturation image info: '
          ; printf, ulog, pb0rot[dpx, dpy]
          ; printf, ulog, 'saturation average:   ', satave

          ; PRINT,        '* * * ', l0_file, '  ', rpixt, ' ring saturated:', nelem
          ; PRINTF, ULOG, '* * * ', l0_file, '  ', rpixt, ' ring saturated:', nelem
        endif
      endif
    endif

    ; cloud check
    chkcloud = 1
    clo      = 0
    chi      = 0
    cloud    = 0
    if (chkcloud gt 0) then begin
      ; print, '~ ~ ~ cloud check ~ ~ ~'
      cmax =  150.0
      cmax = 2200.0   ; upper brightness threshold
      cmin =  200.0   ; lower brightness threshold
      rpixc = 190     ; circle radius [pixels]
      dpx  = fix(cos(dp) * rpixc + axcen + 0.5005)
      dpy  = fix(sin(dp) * rpixc + aycen + 0.5005)

      cave = total(pb0rot[dpx, dpy]) / nray
      cloudpixlo = where(pb0rot[dpx, dpy] le cmin)
      cloudpixhi = where(pb0rot[dpx, dpy] ge cmax)
      nelemlo    = n_elements(cloudpixlo)
      nelemhi    = n_elements(cloudpixhi)

      ; if too many pixels are below lower limit, set clo = 1
      if (cloudpixlo (0) ne -1) then begin
        closize = size (cloudpixlo)

        if (closize (1) ge (nray / 5)) then begin
          clo = 1
          ; print,        'cloud cmin, cmax, radius: ', cmin, cmax, rpixc
          ; print,        'cloud image info: '
          ; print,        pb0rot[dpx, dpy]
          ; print,        'cloud cloudpixlo: '
          ; print,        cloudpixlo
          ; print,        'cloud closize:    ', closize
          ;
          ; printf, ulog, 'cloud cmin, cmaxm radius: ', cmin, cmax, rpixc
          ; printf, ulog, 'cloud image info: '
          ; printf, ulog, pb0rot[dpx, dpy]
          ; printf, ulog, 'cloud cloudpixlo: '
          ; printf, ulog, cloudpixlo
          ; printf, ulog, 'cloud closize:    ', closize

          ; print,        '* * * ', l0_file, '  ', rpixc, ' ring dim:     ', nelemlo
          ; printf, ulog, '* * * ', l0_file, '  ', rpixc, ' ring dim:     ', nelemlo
        endif
      endif

      if (cloudpixhi (0) ne -1) then begin
        chisize = size(cloudpixhi)
        ; if (chisize (1) ge (nray / 5) then $

        if (cave ge cmax) then begin
          chi = 1
          ; print,        'cloud image info: '
          ; print,        pb0rot (dpx, dpy)
          ; print,        'cloud check cloudpixhi: '
          ; print,        cloudpixhi
          ; print,        'cloud check chisize:    ', chisize
          ;
          ; printf, ulog, 'cloud image info: '
          ; printf, ulog, pb0rot[dpx, dpy]
          ; printf, ulog, 'cloud check cloudpixhi: '
          ; printf, ulog, cloudpixhi
          ; printf, ulog, 'cloud check chisize:    ', chisize

          ; print,        '* * * ', l0_file, '  ', rpixb, ' ring bright:   ', nelemhi
          ; printf, ulog, '* * * ', l0_file, '  ', rpixb, ' ring bright:   ', nelemhi
        endif
      endif

      cloud = clo + chi
    endif

    ; do noise (sobel) test for "good" images
    chknoise = 1
    noise    = 0
    bad = bright + sat + clo + chi
    if ((chknoise gt 0) and (bad eq 0)) then begin
      ; print, '~ ~ ~ Sobel check ~ ~ ~'
      nray  = 480
      acirc = !PI * 2.0 / float (nray)
      dp    = findgen(nray) * acirc
      dpx   = intarr(nray)
      dpy   = intarr(nray)

      ; noise_diff_limit =  15.0
      ; noise_diff_limit =  50.0   ; difference threshold

      noise_diff_limit =  70.0   ; difference threshold
      total_bad_limit  =  80     ; total # bad pixel differences

      ; print,        'noise_diff_limit, total_bad_limit: ', $
      ;                noise_diff_limit, total_bad_limit
      ; printf, ulog, 'noise_diff_limit, total_bad_limit: ', $
      ;                noise_diff_limit, total_bad_limit

      ; radius loop
      total_bad = 0
      rpixbeg = 276
      rpixend = 280
      for rpixn = rpixbeg, rpixend, 1 do begin
        dpx = fix(cos(dp) * rpixn + axcen + 0.5005)
        dpy = fix(sin(dp) * rpixn + aycen + 0.5005)
        knoise = float(pb0rot[dpx, dpy])
        kdiff  = abs(knoise[0:nray - 2] - knoise[1:nray - 1])
        badpix = where(kdiff gt noise_diff_limit)

        if (doview gt 0) then begin
          set_plot, 'X'
          window, xsize=512, ysize=512, retain=2
          tvlct, rlut, glut, blut
          !p.multi = [0, 1, 2]
          plot, knoise, title = l0_file + ' noise'
          plot, kdiff,  title = l0_file + ' diff noise'
          cursor, _x, _y, 3, /normal
          set_plot, 'Z'
          device, set_resolution = [xdim, ydim], set_colors=256, z_buffering=0
        endif

        ; The noise itself is not a reliable test. The difference of the noise
        ; works well.
        if (badpix[0] ne -1) then begin
          numbad     = n_elements(badpix)
          total_bad += numbad

          ; print,        'rpixn: ', rpixn, ' noise diff:'
          ; print,        fix(kdiff[badpix])
          ; print,        'noise diff numbad: ', numbad
          ;
          ; printf, ulog, 'rpixn: ', rpixn, ' noise diff: '
          ; printf, ulog, fix(kdiff[badpix])
          ; printf, ulog, 'noise diff numbad: ', numbad

        endif
      endfor

      ; print,        'noise total bad: ', total_bad
      ; printf, ulog, 'noise total bad: ', total_bad
      ; print,        'noise bad limit: ', total_bad_limit
      ; printf, ulog, 'noise bad limit: ', total_bad_limit

      ; if noise limit is exceeded, set bad = 1

      if (total_bad ge total_bad_limit) then begin
        noise = 1
        ; print,        '* * * ', l0_file, $
        ;               '       noise limit exceeded:', total_bad_limit
        ; printf, ulog, '* * * ', l0_file, $
        ;               '       noise limit exceeded:',  total_bad_limit
      endif
    endif

    ; apply mask to restrict field of view (FOV)

    next:

    if (cal gt 0 or dev gt 0) then begin
      pb0m = pb0rot
    end else if (nx ne xdim or ny ne ydim) then begin
      mg_log, 'image dimensions incompatible with mask: %d, %d, %d, %d', $
              nx, ny, xdim, ydim, name='kcor/rt', /warn
      pb0m = pb0rot 
    endif else begin
      pb0m = pb0rot * mask 
    endelse

    ; intensity scaling
    power = 0.9
    power = 0.8
    power = 0.5
    pb0s = pb0m ^ power   ; apply exponential power

    imin = min(pb0s)
    imax = max(pb0s)

    ; imin = 10
    ; imax = 3000 ^ power

    ; print,        'imin/imax: ', imin, imax
    ; printf, ulog, 'imin/imax: ', imin, imax

    ; scale pixel intensities

    ; if ((cal eq 0 and dev eq 0) or (imax gt 250.0)) then $
    ;    pb0sb = bytscl(pb0s, min=imin, max=imax, top=250) $;linear scaling:0-250
    ; else $
    ;    pb0sb = byte(pb0s)

    pb0sb = bytscl(pb0s, min=imin, max=imax, top=250)   ; linear scaling:0-250

    ; display image
    tv, pb0sb

    ; print, '!d.n_colors: ', !d.n_colors

    rsunpix = rsun / platescale     ; 1.0 rsun [pixels]
    irsunpix = fix(rsunpix + 0.5)   ; 1.0 rsun [integer pixels]

    ; print, 'rdisc_pix, rsunpix: ', rdisc_pix, rsunpix

    ; Annotate image.
    ; Skip annotation (except file name) for calibration images.

    if (cal eq 0 and dev eq 0) then begin
      ; draw circle at 1.0 Rsun

      ; tvcircle, rsunpix, axcen, aycen,     0, /device, /fill ; 1.0 Rsun circle
      ; tvcircle, rdisc_pix, axcen, aycen, red, /device        ; occulter edge

      tvcircle, rdisc_pix, axcen, aycen, grey, /device, /fill ; occulter disc 
      tvcircle, rsunpix, axcen, aycen, yellow, /device        ; 1.0 Rsun circle
      tvcircle, rsunpix*3.0, axcen, aycen, grey, /device      ; 3.0 Rsun circle

      ; draw "+" at sun center
      plots, [ixcen - 5, ixcen + 5], [iycen, iycen], color=yellow, /device
      plots, [ixcen, ixcen], [iycen - 5, iycen + 5], color=yellow, /device

      if (dev eq 0) then $
        xyouts, 490, 1010, 'NORTH', color=green, charsize=1.0, /device
    endif

    ; create GIF file name, draw circle (as needed)
    fitsloc  = strpos(l0_file, '.fts')
    gif_file = 'kcor.gif'   ; default gif file name
    qual     = 'unk'

    ;  xyouts, 4, ydim-20, gif_file, color=red, charsize=1.5, /device
    ;  save = tvrd()

    ; write GIF image

    ; IF (eng GT 0) THEN begin   ; Engineering
    ;    gif_file = strmid (l0_file, 0, fitsloc) + '_e.gif' 
    ;    gif_path = q_dir_eng + gif_file
    ; END ELSE $

    if (cal gt 0) then begin   ; calibration
      gif_file = strmid(l0_file, 0, fitsloc) + '_c.gif' 
      gif_path = q_dir_cal + gif_file
      qual = q_cal
      ncal += 1
      printf, ucal, l0_file
      ; printf, ulog, l0_file, ' --> ', cdate_dir
      file_copy, l0_file, cdate_dir, /overwrite   ; copy l0 file to cdate_dir.
    endif else if (dev gt 0) then begin   ; device obscuration
      gif_file = strmid(l0_file, 0, fitsloc) + '_m.gif' 
      gif_path = q_dir_dev + gif_file
      qual = q_dev
      ndev += 1
      printf, udev, l0_file
    endif else if (bright gt 0) then begin   ; bright image
      tvcircle, rpixb, axcen, aycen, red, /device   ; bright circle
      gif_file = strmid(l0_file, 0, fitsloc) + '_b.gif' 
      gif_path = q_dir_brt + gif_file
      qual = q_brt
      nbrt += 1
      printf, ubrt, l0_file
    endif else if (clo    gt 0) then begin   ; dim image
      tvcircle, rpixc, axcen, aycen, green,  /device   ; cloud circle
      gif_file = strmid(l0_file, 0, fitsloc) + '_d.gif'
      gif_path = q_dir_dim + gif_file
      qual = q_dim
      ndim += 1
      printf, udim, l0_file
    endif else if (chi    gt 0) then begin   ; cloudy image
      tvcircle, rpixc, axcen, aycen, green,  /device   ; cloud circle
      gif_file = strmid(l0_file, 0, fitsloc) + '_o.gif' 
      gif_path = q_dir_cld + gif_file
      qual = q_cld
      ncld += 1
      printf, ucld, l0_file
    endif else  if (sat    gt 0) then begin   ; saturation
      tvcircle, rpixt, axcen, aycen, blue, /device   ; sat circle
      gif_file = strmid(l0_file, 0, fitsloc) + '_t.gif' 
      gif_path = q_dir_sat + gif_file
      qual = q_sat
      nsat += 1
      printf, usat, l0_file
    endif else if (noise gt 0) then begin   ; noisy
      tvcircle, rpixn, axcen, aycen, yellow, /device   ; noise circle
      gif_file = strmid (l0_file, 0, fitsloc) + '_n.gif' 
      gif_path = q_dir_nsy + gif_file
      qual = q_nsy
      nnsy += 1
      printf, unsy, l0_file
    endif else begin   ; good image
      gif_file = strmid (l0_file, 0, fitsloc) + '_g.gif'
      gif_path = q_dir_ok + gif_file
      qual = q_ok
      nokf += 1
      printf, uokf, l0_file
      printf, uoka, l0_file
    endelse

    ; write GIF file
    if (keyword_set(gif)) then begin
      xyouts, 4, ydim-20, gif_file, color=red, charsize=1.5, /device
      save = tvrd()
      write_gif, gif_path, save, rlut, glut, blut

      ; print,        'gif_file: ', gif_file
      ; printf, ulog, 'gif_file: ', gif_file
    endif

    istring     = string(format='(i5)',   num_img)
    exptime_str = string(format='(f5.2)', exptime)
    ; print,        '>>>>> ', l0_file, istring, ' exptime:', exptime_str, '  ', $
    ;               datatype, ' <<<<< ', qual
    ; printf, ulog, '>>>>> ', l0_file, istring, ' exptime:', exptime_str, '  ', $
    ;               datatype, ' <<<<< ', qual

    datatype_str = string(format='(a12)', datatype)
    darkshut_str = string(format='(a4)', darkshut)
    cover_str    = string(format='(a4)', cover)
    diffuser_str = string(format='(a4)', diffuser)
    calpol_str   = string(format='(a4)', calpol)
    calpang_str  = string(format='(f7.2)', calpang)
    qual_str     = string(format='(a4)', qual)

    mg_log, '%s %s %s %s % %s %s %s %s', $
            l0_file, datatype_str, exptime_str, cover_str, darkshut_str, $
            diffuser_str, calpol_str, calpang_str, qual_str, $
            name='kcor/rt', /debug
  endwhile   ; end of image loop

  free_lun, ucal
  free_lun, udev
  free_lun, ubrt
  free_lun, udim
  free_lun, ucld
  free_lun, usat
  free_lun, unsy
  free_lun, uokf
  free_lun, uoka

  ; delete empty files
  ; if (ncal eq 0) then file_delete, cal_qpath else printf, ulog, 'ncal: ', ncal
  ; if (ndev eq 0) then file_delete, dev_qpath else printf, ulog, 'ndev: ', ndev
  ; if (nbrt eq 0) then file_delete, brt_qpath else printf, ulog, 'nbrt: ', nbrt
  ; if (ndrk eq 0) then file_delete, drk_qpath else printf, ulog, 'ndrk: ', ndrk
  ; if (ncld eq 0) then file_delete, cld_qpath else printf, ulog, 'ncld: ', ncld
  ; if (nsat eq 0) then file_delete, sat_qpath else printf, ulog, 'nsat: ', nsat
  ; if (nnsy eq 0) then file_delete, nsy_qpath else printf, ulog, 'nssy: ', nnsy
  ; if (nokf eq 0) then file_delete, okf_qpath else printf, ulog, 'nokf: ', nokf

  ; move 'okf_list' to 'date' directory
  ;if (file_test(okf_qpath)) then file_copy, okf_qpath, okf_dpath, /overwrite
  if (file_test(okf_qpath)) then begin
    mg_log, 'moving %s to %s', okf_path, okf_dpath, name='kcor/rt', /debug
    file_move, okf_qpath, okf_dpath, /overwrite
  endif

  mg_log, 'number of images: %d', num_img, name='kcor/rt', /debug

  cd, start_dir
  set_plot, 'X'

  ; get system time & compute elapsed time since "TIC" command
  qtime = toc()
  mg_log, 'elapsed time: %0.1f sec', qtime, name='kcor/rt', /info
  mg_log, '%0.1 sec/image', qtime / num_img, name='kcor/rt', /info
  mg_log, 'done', name='kcor/rt', /info

  free_lun, ulist
end
