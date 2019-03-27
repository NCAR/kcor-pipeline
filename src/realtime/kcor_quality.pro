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
; :Returns:
;   strarr of OK files to continue processing
;
; :Params:
;   date : in, required, type=string
;     format: 'yyyymmdd'
;   l0_fits_files : in, required, type=strarr
;     zipped raw FITS files to process
;
; :Keywords:
;   append : in, optional, type=boolean
;     if set, append log information to existing log file
;   run : in, required, type=object
;     `kcor_run` object
;-
function kcor_quality, date, l0_fits_files, append=append, $
                       brt_files=brt_files, $
                       cal_files=cal_files, $
                       cld_files=cld_files, $
                       dev_files=dev_files, $
                       dim_files=dim_files, $
                       nsy_files=nsy_files, $
                       sat_files=sat_files, $
                       run=run
  compile_opt strictarr

  ; store initial system time
  tic

  maskfile = filepath('kcor_mask.img', root=mg_src_root())

  ; L0 fits files
  date_dir   = filepath(date, root=run->config('processing/raw_basedir'))

  ; calibration date directory
  cdate_dir  = filepath(date, root=run->config('calibration/basedir'))

  ; quality directory
  q_dir      = filepath('q', root=date_dir)

  cal_list  = 'cal.ls'
  dev_list  = 'dev.ls'
  brt_list  = 'brt.ls'
  dim_list  = 'dim.ls'
  cld_list  = 'cld.ls'
  nsy_list  = 'nsy.ls'
  sat_list  = 'sat.ls'
  oka_list  = 'oka.ls'   ; ok files: all or cumulative

  cal_qpath = filepath(cal_list, root=q_dir)
  dev_qpath = filepath(dev_list, root=q_dir)
  brt_qpath = filepath(brt_list, root=q_dir)
  dim_qpath = filepath(dim_list, root=q_dir)
  cld_qpath = filepath(cld_list, root=q_dir)
  nsy_qpath = filepath(nsy_list, root=q_dir)
  sat_qpath = filepath(sat_list, root=q_dir)
  oka_qpath = filepath(oka_list, root=q_dir)

  okf_list  = 'list_okf'                        ; ok files for one invocation
  okf_qpath = filepath(okf_list, root=q_dir)    ; ok fits file list in q directory
  okf_dpath = filepath(okf_list, root=date_dir) ; ok fits file list in date directory

  ; sub-directory names

  q_ok  = 'ok'
  q_bad = 'bad'
  q_brt = 'brt'
  q_cal = 'cal'
  q_cld = 'cld'
  q_dim = 'dim'
  q_dev = 'dev'
  q_nsy = 'nsy'
  q_sat = 'sat'

  q_dir_ok  = filepath(q_ok, root=q_dir)    ; ok quality images
  q_dir_bad = filepath(q_bad, root=q_dir)   ; bad quality images
  q_dir_brt = filepath(q_brt, root=q_dir)   ; bright images
  q_dir_cal = filepath(q_cal, root=q_dir)   ; calibration images
  q_dir_cld = filepath(q_cld, root=q_dir)   ; cloudy images
  q_dir_dim = filepath(q_dim, root=q_dir)   ; dim images
  q_dir_dev = filepath(q_dev, root=q_dir)   ; device images
  q_dir_nsy = filepath(q_nsy, root=q_dir)   ; noisy images
  q_dir_sat = filepath(q_sat, root=q_dir)   ; saturated images

  brt_list = list()
  cal_list = list()
  cld_list = list()
  dim_list = list()
  dev_list = list()
  nsy_list = list()
  sat_list = list()

  ;q_dir_unk    = q_path + 'unk/'    ; unknown images
  ;q_dir_eng    = q_path + 'eng/'    ; engineering images
  ;q_dir_ugly   = q_path + 'ugly/'   ; ugly quality images

  ; create sub-directories for image categories
  file_mkdir, q_dir
  file_mkdir, cdate_dir

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
  mg_log, 'checking quality for %s', date, name='kcor/rt', /info

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
  set_plot, 'Z'
  ; window, 0, xsize=1024, ysize=1024, retain=2

  device, set_resolution=[1024, 1024], $
          decomposed=0, $
          set_colors=256, $
          z_buffering=0

  lct, filepath('bwy5.lut', root=run.resources_dir)   ; color table
  tvlct, rlut, glut, blut, /get

  ; define color levels for annotation
  yellow = 250 
  grey   = 251
  blue   = 252
  green  = 253
  red    = 254
  white  = 255

  ; open file containing a list of kcor L0 FITS files
  mg_log, 'inventory for current run...', name='kcor/rt', /debug
  header = 'filename                 datatype    exp  cov drk dif pol angle  qual'
  mg_log, header, name='kcor/noformat', /debug

  num_img = 0

  quicklook_dir = filepath('', subdir=['level0', 'quicklook'], root=date_dir)
  if (~file_test(quicklook_dir, /directory)) then file_mkdir, quicklook_dir

  n_l0_fits_files = n_elements(l0_fits_files)

  ; image file loop
  foreach l0_file, l0_fits_files do begin
    num_img += 1
    img = readfits(l0_file, hdu, /silent)   ; read fits image & header

    mg_log, 'checking %d/%d: %s', $
            num_img, n_l0_fits_files, file_basename(l0_file), $
            name='kcor/rt', /debug

    ; catch problems where file is not completely written yet
    n_dims = size(img, /n_dimensions)
    if (n_dims ne 4) then begin
      mg_log, 'wrong number of dimensions for image: %d', n_dims, $
              name='kcor/rt', /warn
      delay_time = 3.0   ; seconds
      mg_log, 'attempting another read after %0.2f s delay', delay_time, $
              name='kcor/rt', /warn
      wait, delay_time
      img = readfits(l0_file, hdu, /silent)
      n_dims = size(img, /n_dimensions)
      if (n_dims ne 4) then begin
        mg_log, 'wrong number of dimensions for image: %d', n_dims, $
                name='kcor/rt', /warn
        continue
      endif
    endif

    ; extract keyword parameters from FITS header
    naxis    = sxpar(hdu, 'NAXIS',    count=qnaxis)
    naxis1   = sxpar(hdu, 'NAXIS1',   count=qnaxis1)
    naxis2   = sxpar(hdu, 'NAXIS2',   count=qnaxis2)
    naxis3   = sxpar(hdu, 'NAXIS3',   count=qnaxis3)
    naxis4   = sxpar(hdu, 'NAXIS4',   count=qnaxis4)
    np       = naxis1 * naxis2 * naxis3 * naxis4 

    date_obs = sxpar(hdu, 'DATE-OBS', count=qdate_obs)
    run.time = date_obs

    if (~run->epoch('process')) then begin
      mg_log, 'skipping files from this epoch', name='kcor/rt', /warn
      printf, udev, l0_file
      continue
    endif

    level    = sxpar(hdu, 'LEVEL',    count=qlevel)

    bbscale  = sxpar(hdu, 'BSCALE',   count=qbbscale)
    bitpix   = fix(sxpar(hdu, 'BITPIX'))

    datatype = sxpar(hdu, 'DATATYPE', count=qdatatype)

    diffuser = sxpar(hdu, 'DIFFUSER', count=qdiffuser)
    calpol   = sxpar(hdu, 'CALPOL',   count=qcalpol)
    calpang  = sxpar(hdu, 'CALPANG',  count=qcalpang)
    darkshut = sxpar(hdu, 'DARKSHUT', count=qdarkshut)
    exptime  = sxpar(hdu, 'EXPTIME',  count=qexptime)
    cover    = sxpar(hdu, 'COVER',    count=qcover)

    if (run->epoch('use_occulter_id')) then begin
      occltrid = sxpar(hdu, 'OCCLTRID', count=qoccltrid)
    endif else begin
      occltrid = run->epoch('occulter_id')
    endelse

    numsum = sxpar(hdu, 'NUMSUM', count=qnumsum)

    ; determine occulter size in pixels
    occulter = kcor_get_occulter_size(occltrid, run=run)
    radius_guess = occulter / run->epoch('plate_scale')   ; occulter size [pixels]

    kcor_correct_camera, img, hdu, run=run, logger_name='kcor/rt'
    if (run->epoch('remove_horizontal_artifact')) then begin
      mg_log, 'correcting horiz lines @ [%s], cameras: [%s]', $
              strjoin(strtrim(run->epoch('horizontal_artifact_lines'), 2), ', '), $
              strjoin(strtrim(run->epoch('horizontal_artifact_cameras'), 2), ', '), $
              name='kcor/rt', /debug
      kcor_correct_horizontal_artifact, img, $
                                        run->epoch('horizontal_artifact_lines'), $
                                        run->epoch('horizontal_artifact_cameras')
    endif

    ; define variables for azimuthal angle "scans"
    nray  = 36
    acirc = !pi * 2.0 / float(nray)
    dp    = findgen(nray) * acirc
    dpx   = intarr(nray)
    dpy   = intarr(nray)

    ; get FITS image size from image array
    imgsize = size(img)           ; get size of img array
    ndim    = imgsize[0]          ; # dimensions
    n1      = imgsize[1]          ; dimension #1 size X: 1024
    n2      = imgsize[2]          ; dimension #2 size Y: 1024
    n3      = imgsize[3]          ; dimension #3 size pol state: 4
    n4      = imgsize[4]          ; dimension #4 size camera: 2
    dtype   = imgsize[ndim + 1]   ; data type
    npix    = imgsize[ndim + 2]   ; # pixels
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

    date_str = string(year, month, day, hour, minute, second, $
                      format='(%"%s-%s-%sT%s:%s:%s")')

    ; find ephemeris data (pangle,bangle ...) using solarsoft routine pb0r
    ephem = pb0r(date_str, /arcsec)
    pangle = ephem[0]   ; degrees
    bangle = ephem[1]   ; degrees
    rsun   = ephem[2]   ; solar radius (arcsec)

    pangle += 180.0   ; adjust orientation for Kcor telescope

    ; verify that image size agrees with FITS header information
    if (nelem ne np) then begin
      mg_log, 'nelem: %d, ne np: %d', nelem, np, name='kcor/rt', /warn
      continue
    endif

    ; verify that image is Level 0
    if (level ne 'L0')  then begin
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

    ; check calpol position
    if (calpol ne 'out') then begin
      dev  += 1
      calp += 1
    endif

    ; check dark shutter position
    if (darkshut ne 'out') then begin
      dev  += 1
      drks += 1
    endif

    ; check cover position
    if (cover ne 'out') then begin
      dev += 1
      cov += 1
    endif

    ; saturation check
    chksat = run->config('realtime/check_quality')
    sat = 0B
    if (chksat gt 0) then begin
      sat_pixels = where(img[*, *, 0, 0] ge run->epoch('smax'), n_saturated_pixels)
      sat = n_saturated_pixels gt run->epoch('smax_max_count')

      if (sat) then begin
        pb0rot = img[*, *, 0, 0]
        goto, next
      endif
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
    ; endif

    ; find disc center
    rdisc_pix = 0.0
    if (cal gt 0 or dev gt 0 or cloudy gt 0) then begin  ; fixed location for center
      xcen = axcen - 4
      ycen = aycen - 4
      rdisc_pix = radius_guess
    endif else begin   ; locate disc center
      center_info = kcor_find_image(img00, radius_guess, chisq=chisq, $
                                    /center_guess, $
                                    max_center_difference=run->epoch('max_center_difference'), $
                                    log_name='kcor/rt')
      xcen = center_info[0]        ; x offset
      ycen = center_info[1]        ; y offset
      rdisc_pix = center_info[2]   ; radius of occulter [pixels]
    endelse

    ; integer coordinates for disc center
    ixcen = fix(xcen + 0.5)
    iycen = fix(ycen + 0.5)

    ; rotate image by P-angle, no rotation for calibration or device-obscured
    ; images
    if (cal gt 0 or dev gt 0) then begin
      pb0rot = pb0
      goto, next
    endif else begin
      pb0rot = rot(pb0, pangle, 1.0, xcen, ycen, cubic=-0.5, missing=0)
    endelse

    ; bright sky check
    dobright = run->config('realtime/check_quality')
    bright = 0B
    if (dobright gt 0) then begin
      bmax = run->epoch('bmax') * numsum / 512.0
      if ((bitpix ne 16) and (bitpix ne 32)) then begin
        mg_log, 'unexpected BITPIX: %d', bitpix, name='kcor/rt', /error
        goto, next
      endif
      rpixb = run->epoch('rpixb')   ; circle radius [pixels]
      dpx   = fix(cos(dp) * rpixb + axcen + 0.5005)
      dpy   = fix(sin(dp) * rpixb + aycen + 0.5005)

      brightave = total(pb0rot[dpx, dpy]) / nray
      brightpix = where(pb0rot[dpx, dpy] ge bmax, n_bright_pixels)

      ; if too many pixels in circle exceed threshold, set bright = 1
      bright = n_bright_pixels ge (nray / 5)
    endif

    ; cloud check
    chkcloud = run->config('realtime/check_quality')
    clo      = 0B
    chi      = 0B
    cloud    = 0B
    if (chkcloud gt 0) then begin
      ; upper brightness threshold
      cmax = run->epoch('cmax') * numsum / 512.0
      ; lower brightness threshold
      cmin = run->epoch('cmin') * numsum / 512.0
      rpixc = run->epoch('rpixc') ; circle radius [pixels]
      dpx  = fix(cos(dp) * rpixc + axcen + 0.5005)
      dpy  = fix(sin(dp) * rpixc + aycen + 0.5005)

      cave = total(pb0rot[dpx, dpy]) / nray
      cloudpixlo = where(pb0rot[dpx, dpy] le cmin, n_cloudy_lo)
      cloudpixhi = where(pb0rot[dpx, dpy] ge cmax, n_cloudy_hi)

      ; if too many pixels are below lower limit, set clo = 1
      clo = n_cloudy_lo ge (nray / 5)
      if (n_cloudy_hi gt 0L) then chi = cave ge cmax

      cloud = clo + chi
    endif

    ; do noise (sobel) test for "good" images for 16 bit data.
    ; Need to find noise limits that work for 32 bit (float and long) data
    ; For now, skip noise check for 32 bit data

    chknoise = run->epoch('check_noise') && run->config('realtime/check_quality')

    noise    = 0
    bad = bright + sat + clo + chi
    if ((chknoise gt 0) and (bad eq 0)) then begin
      nray  = 480
      acirc = !pi * 2.0 / float (nray)
      dp    = findgen(nray) * acirc
      dpx   = intarr(nray)
      dpy   = intarr(nray)

      ; noise_diff_limit =  15.0
      ; noise_diff_limit =  50.0   ; difference threshold

      if (bitpix eq 16) then noise_diff_limit = 70.0    ; difference threshold
      if (bitpix eq 32) then noise_diff_limit = 3.e05   ; brightness threshold

      total_bad_limit  =  80     ; total # bad pixel differences

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
          !p.multi = 0
          set_plot, 'Z'
          device, set_resolution = [xdim, ydim], set_colors=256, z_buffering=0
        endif

        ; The noise itself is not a reliable test. The difference of the noise
        ; works well.
        if (badpix[0] ne -1) then begin
          numbad     = n_elements(badpix)
          total_bad += numbad
        endif
      endfor

      ; if noise limit is exceeded, set bad = 1
      noise = total_bad ge total_bad_limit
    endif

    ; apply mask to restrict field of view (FOV)

    next:

    if ((cal gt 0) or (dev gt 0) or (sat gt 0)) then begin
      pb0m = pb0rot
    endif else if (nx ne xdim or ny ne ydim) then begin
      mg_log, 'image dimensions incompatible with mask: %d, %d, %d, %d', $
              nx, ny, xdim, ydim, name='kcor/rt', /warn
      pb0m = pb0rot 
    endif else begin
      pb0m = pb0rot * mask 
    endelse

    ; intensity scaling
    power = 0.5
    pb0s = pb0m ^ power   ; apply exponential power

    imin = min(pb0s)
    imax = run->epoch('quicklook_scale') * max(pb0s)

    ; imin = 0.0
    ; imax = 40.0

    ; scale pixel intensities
    pb0sb = bytscl(pb0s, min=imin, max=imax, top=250)   ; linear scaling: 0-250

    ; display image
    tv, pb0sb

    rsunpix = rsun / run->epoch('plate_scale')   ; 1.0 rsun [pixels]
    irsunpix = fix(rsunpix + 0.5)      ; 1.0 rsun [integer pixels]

    ; Annotate image
    ; Skip annotation (except file name) for calibration images

    if (cal eq 0 and dev eq 0 and sat eq 0) then begin
      ; draw circle at 1.0 Rsun
      tvcircle, rdisc_pix, axcen, aycen, grey, /device, /fill  ; occulter disc 
      tvcircle, rsunpix, axcen, aycen, yellow, /device         ; 1.0 Rsun circle
      tvcircle, 3.0 * rsunpix, axcen, aycen, grey, /device     ; 3.0 Rsun circle

      ; draw "+" at sun center
      plots, [ixcen - 5, ixcen + 5], [iycen, iycen], color=yellow, /device
      plots, [ixcen, ixcen], [iycen - 5, iycen + 5], color=yellow, /device

      if (dev eq 0) then begin
        xyouts, 490, 1010, 'NORTH', color=green, charsize=1.0, /device
      endif
    endif

    ; create GIF file name, draw circle (as needed)
    fitsloc  = strpos(l0_file, '.fts')
    gif_file = 'kcor.gif'   ; default gif file name
    qual     = 'unk'

    ; write GIF image

    l0_basename = file_basename(l0_file)

    if (cal gt 0) then begin   ; calibration
      gif_file = strmid(l0_basename, 0, fitsloc) + '_c.gif' 
      qual = q_cal
      ncal += 1
      printf, ucal, l0_file
      cal_list->add, l0_file
      file_copy, l0_file, cdate_dir, /overwrite   ; copy l0 file to cdate_dir
    endif else if (dev gt 0) then begin   ; device obscuration
      gif_file = strmid(l0_basename, 0, fitsloc) + '_m.gif' 
      qual = q_dev
      ndev += 1
      printf, udev, l0_file
      dev_list->add, l0_file
    endif else if (sat gt 0) then begin   ; saturation
      tvcircle, run->epoch('rpixt'), axcen, aycen, blue, /device   ; sat circle
      gif_file = strmid(l0_basename, 0, fitsloc) + '_t.gif' 
      qual = q_sat
      nsat += 1
      printf, usat, l0_file
      sat_list->add, l0_file
    endif else if (bright gt 0) then begin     ; bright image
      tvcircle, rpixb, axcen, aycen, red, /device   ; bright circle
      gif_file = strmid(l0_basename, 0, fitsloc) + '_b.gif' 
      qual = q_brt
      nbrt += 1
      printf, ubrt, l0_file
      brt_list->add, l0_file
    endif else if (clo gt 0) then begin   ; dim image
      tvcircle, rpixc, axcen, aycen, green,  /device   ; cloud circle
      gif_file = strmid(l0_basename, 0, fitsloc) + '_d.gif'
      qual = q_dim
      ndim += 1
      printf, udim, l0_file
      dim_list->add, l0_file
    endif else if (chi gt 0) then begin   ; cloudy image
      tvcircle, rpixc, axcen, aycen, green,  /device   ; cloud circle
      gif_file = strmid(l0_basename, 0, fitsloc) + '_o.gif' 
      qual = q_cld
      ncld += 1
      printf, ucld, l0_file
      cld_list->add, l0_file
    endif else if (noise gt 0) then begin   ; noisy
      tvcircle, rpixn, axcen, aycen, yellow, /device   ; noise circle
      gif_file = strmid (l0_basename, 0, fitsloc) + '_n.gif' 
      qual = q_nsy
      nnsy += 1
      printf, unsy, l0_file
      nsy_list->add, l0_file
    endif else begin   ; good image
      if (eng gt 0) then begin   ; engineering
        gif_file = strmid(l0_basename, 0, fitsloc) + '_e.gif' 
      endif else begin
        gif_file = strmid(l0_basename, 0, fitsloc) + '_g.gif'
      endelse

      qual = q_ok
      nokf += 1
      printf, uokf, file_basename(l0_file)
      printf, uoka, file_basename(l0_file)
    endelse

    gif_path = filepath(gif_file, root=quicklook_dir)

    ; write GIF file
    xyouts, 6, ydim-20, gif_file, color=white, charsize=1.0, /device
    save = tvrd()
    write_gif, gif_path, save, rlut, glut, blut

    istring     = string(format='(i5)',   num_img)
    exptime_str = string(format='(f5.2)', exptime)

    datatype_str = string(format='(a12)', datatype)
    darkshut_str = string(format='(a4)', darkshut)
    cover_str    = string(format='(a4)', cover)
    diffuser_str = string(format='(a4)', diffuser)
    calpol_str   = string(format='(a4)', calpol)
    calpang_str  = string(format='(f7.2)', calpang)
    qual_str     = string(format='(a4)', qual)

    mg_log, '%s%s%s%s%s%s%s%s%s', $
            file_basename(l0_file), datatype_str, exptime_str, cover_str, darkshut_str, $
            diffuser_str, calpol_str, calpang_str, qual_str, $
            name='kcor/noformat', /debug
    mg_log, '%d/%d: %s [%s] (%s)', $
            num_img, n_l0_fits_files, file_basename(l0_file), $
            strmid(datatype, 0, 3), qual, $
            name='kcor/rt', /info
  endforeach   ; end of image loop

  free_lun, ucal
  free_lun, udev
  free_lun, ubrt
  free_lun, udim
  free_lun, ucld
  free_lun, usat
  free_lun, unsy
  free_lun, uokf
  free_lun, uoka

  brt_files = brt_list->toArray()
  cal_files = cal_list->toArray()
  cld_files = cld_list->toArray()
  dim_files = dim_list->toArray()
  dev_files = dev_list->toArray()
  nsy_files = nsy_list->toArray()
  sat_files = sat_list->toArray()

  obj_destroy, [brt_list, cal_list, cld_list, dim_list, dev_list, nsy_list, $
                sat_list]

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
    mg_log, 'moving %s/q/%s to %s/%s', date, okf_list, date, okf_list, $
            name='kcor/rt', /debug
    file_move, okf_qpath, okf_dpath, /overwrite
  endif

  cd, start_dir
  set_plot, 'X'

  n_ok_files = file_lines(okf_dpath)
  if (n_ok_files gt 0L) then begin
    ok_files = strarr(n_ok_files)
    openr, ok_lun, okf_dpath, /get_lun
    readf, ok_lun, ok_files
    free_lun, ok_lun
  endif else begin
    ok_files = !null
  endelse

  ; get system time & compute elapsed time since "TIC" command
  qtime = toc()
  mg_log, 'checked %d images (%d OK images) in %0.1f sec', $
          num_img, n_ok_files, qtime, $
          name='kcor/rt', /info
  mg_log, '%0.1f sec/image', qtime / num_img, name='kcor/rt', /info
  mg_log, 'done', name='kcor/rt', /info

  return, ok_files
end
