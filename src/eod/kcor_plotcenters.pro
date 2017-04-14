; docformat = 'rst'

;+
; Plot occulting centers.
;
; :Author:
;   Andrew L. Stanger   HAO/NCAR   22 Jun 2015
;
; :History:
;   26 Jun 2015 Plot time in hours:minutes instead of hours (decimal).
;   03 Dec 2015 Add 'eng' quality type for file summary.
;   26 Jan 2016 Color tables are in /hao/acos/sw/idl/color.
;
; :Params:
;   date : in, required, type=string
;     date in the form 'YYYYMMDD'
;
; :Keywords:
;   list : in, required, type=strarr
;     list of files to process
;   run : in, required, type=object
;     `kcor_run` object
;   append : in, optional, type=boolean
;     if set, append log information to existing log file.
;-
pro kcor_plotcenters, date, list=list, append=append, run=run
  compile_opt strictarr

  ; store initial system time
  tic

  if (n_params() eq 0) then begin
    mg_log, 'missing date parameter', name='kcor/eod', /error
    return
  endif

  ; date for plots
  pyear  = strmid(date, 0, 4)
  pmonth = strmid(date, 4, 2)
  pday   = strmid(date, 6, 2)
  pdate = string(pyear, pmonth, pday, format='(%"%s-%s-%s")')

  ;-----------------------------------------
  ; Define directory names.
  ;-----------------------------------------

  base_dir = run.raw_basedir
  date_dir = filepath(date, root=base_dir)

  ; TODO: change p/ directory to engineering or plots
  plots_dir = filepath('p', root=date_dir)
  l0_dir    = filepath('level0', root=date_dir)

  q_cal = 'cal'
  q_eng = 'eng'
  q_sci = 'sci'
  q_dev = 'dev'

  ncal = 0
  neng = 0
  nsci = 0
  ndev = 0

  ; check for existence of Level0 directory
  if (~file_test (l0_dir, /directory)) then begin
    mg_log, '%s does not exist, no files to process', l0_dir, $
            name='kcor/eod', /warn
    goto, done
  endif

  ; create p sub-directory, if needed
  if (~file_test(plots_dir, /directory)) then file_mkdir, plots_dir

  ; move to 'L0' directory
  cd, current=start_dir   ; save current directory.
  cd, l0_dir              ; move to date directory.

  doview = 0

  set_plot, 'Z'

  ;lct,'/hao/acos/sw/idl/color/quallab_ver2.lut' ; color table.
  ;lct,'/hao/acos/sw/idl/color/art.lut' ; color table.
  ;lct,'/hao/acos/sw/idl/color/bwyvid.lut' ; color table.
  ;lct,'/hao/acos/sw/idl/color/artvid.lut' ; color table.

  lct, filepath('bwy5.lut', root=run.resources_dir)   ; color table
  tvlct, rlut, glut, blut, /get

  ; define color levels for annotation
  yellow = 250 
  grey   = 251
  blue   = 252
  green  = 253
  red    = 254
  white  = 255

  cal = 0
  eng = 0
  sci = 0
  dev = 0

  ; determine the number of files to process
  nimg = n_elements(list)
  mg_log, '%d images to process', nimg, name='kcor/eod', /debug
  mg_log, 'file name                datatype', $
          name='kcor/eod', /debug
  mg_log, '    exp  cov drk  dif pol angle  qual', $
          name='kcor/eod', /debug

  ; declare storage for occulting centers

  hours  = fltarr(nimg)

  fxcen0 = fltarr(nimg)
  fycen0 = fltarr(nimg)
  frocc0 = fltarr(nimg)

  fxcen1 = fltarr(nimg)
  fycen1 = fltarr(nimg)
  frocc1 = fltarr(nimg)

  ; image file loop
  for i = 0L, n_elements(list) - 1L do begin
    l0_file = list[i]
    img = readfits (l0_file, hdu, /silent)   ; read fits image & header

    fitsloc  = strpos(l0_file, '.fts')
    gzloc    = strpos(l0_file, '.gz')
    img_file = l0_file
    if (gzloc ge 0) then img_file = strmid(l0_file, gzloc)

    img0 = reform(img[*, *, 0, 0])
    ; img0 = reverse(img0, 2)  ; y-axis inversion
    img1 = reform(img[*, *, 0, 1])

    cal  = 0
    eng  = 0
    sci  = 0
    dev  = 0
    diff = 0
    calp = 0
    drks = 0
    cov  = 0

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

    dshutter = 'unk'
    if (darkshut eq 'in')  then dshutter = 'shut'
    if (darkshut eq 'out') then dshutter = 'open'

    ; determine occulter size in pixels
    occulter = strmid(occltrid, 3, 5)   ; extract 5 characters from occltrid
    if (occulter eq '991.6') then occulter =  991.6
    if (occulter eq '1006.') then occulter = 1006.9
    if (occulter eq '1018.') then occulter = 1018.9

    platescale = run.plate_scale           ; arsec/pixel
    radius_guess = occulter / platescale   ; occulter size [pixels].

    ; get FITS image size from image array

    n1 = 1
    n2 = 1
    n3 = 1
    n4 = 1
    imgsize = size(img)           ; get size of img array.
    ndim    = imgsize[0]          ; # dimensions
    n1      = imgsize[1]          ; dimension #1 size X: 1024
    n2      = imgsize[2]          ; dimension #2 size Y: 1024
    n3      = imgsize[3]          ; dimension #3 size pol state: 4
    n4      = imgsize[4]          ; dimension #4 size camera: 2
    dtype   = imgsize[ndim + 1]   ; data type
    npix    = imgsize[ndim + 2]   ; # pixels
    nelem   = 1
    for j = 1, ndim do nelem *= imgsize[j]   ; compute # elements in array.
    if (ndim eq 4) then nelem = n1 * n2 * n3 * n4

    ; define array center coordinates

    xdim = naxis1
    ydim = naxis2
    axcen = (xdim / 2.0) - 0.5   ; x-axis array center.
    aycen = (ydim / 2.0) - 0.5   ; y-axis array center.

    ; extract date items from FITS header parameter (DATE-OBS)
    year   = strmid(date_obs,  0, 4)
    month  = strmid(date_obs,  5, 2)
    day    = strmid(date_obs,  8, 2)
    hour   = strmid(date_obs, 11, 2)
    minute = strmid(date_obs, 14, 2)
    second = strmid(date_obs, 17, 2)

    hdate = string(year, month, day, hour, minute, second, $
                   format='(%"%s-%s-%sT%s:%s:%s")')

    obs_hour = hour
    if (hour lt 16) then obs_hour += 24

    hours[i] = obs_hour + minute / 60.0 + second / 3600.0

    ; verify that image size agrees with FITS header information
    if (nelem ne np) then begin
      mg_log, 'nelem != np (nelem: %d, np: %d)', nelem, np, $
              name='kcor/eod', /warn
      continue
    endif

    ; verify that image is Level 0
    if (level ne 'L0') then begin
      mg_log, 'not level 0 data', name='kcor/eod', /warn
      continue
    endif

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

    ; find disc center

    rocc0_pix = 0.0
    rocc1_pix = 0.0

    cen0_info = kcor_find_image(img0, chisq=chisq, radius_guess, $
                                /center_guess, log_name='kcor/eod')
    xcen0 = cen0_info[0]   ; x center
    ycen0 = cen0_info[1]   ; y center
    rocc0 = cen0_info[2]   ; radius of occulter [pixels]
    fxcen0[i] = xcen0
    fycen0[i] = ycen0
    frocc0[i] = rocc0

    cen1_info = kcor_find_image(img1, chisq=chisq, radius_guess, $
                                /center_guess, log_name='kcor/eod')
    xcen1 = cen1_info[0]   ; x center
    ycen1 = cen1_info[1]   ; y center
    rocc1 = cen1_info[2]   ; radius of occulter [pixels]
    fxcen1[i] = xcen1
    fycen1[i] = ycen1
    frocc1[i] = rocc1

    mg_log, 'xcen0, ycen0, rocc0: %0.2f, %0.2f, %0.2f', xcen0, ycen0, rocc0, $
            name='kcor/eod', /debug
    mg_log, 'xcen1, ycen1, rocc1: %0.2f, %0.2f, %0.2f', xcen0, ycen0, rocc0, $
            name='kcor/eod', /debug

    ; determine type of image

    fitsloc  = strpos(l0_file, '.fts')
    qual     = 'unk'

    if (eng gt 0) then begin              ; engineering
      qual  = q_eng
      neng += 1
    endif else if (cal gt 0) then begin   ; calibration
      qual  = q_cal
      ncal += 1
    endif else if (dev gt 0) then begin   ; device obscuration
      qual  = q_dev
      ndev += 1
    endif else begin                      ; science image
      qual = q_sci
      nsci += 1
    endelse

    istring     = string(format='(i5)',   i)
    exptime_str = string(format='(f5.2)', exptime)

    datatype_str = string(format='(a12)', datatype)
    darkshut_str = string(format='(a4)', darkshut)
    dshutter_str = string(format='(a5)', dshutter)
    cover_str    = string(format='(a4)', cover)
    diffuser_str = string(format='(a4)', diffuser)
    calpol_str   = string(format='(a4)', calpol)
    calpang_str  = string(format='(f7.2)', calpang)
    qual_str     = string(format='(a4)', qual)

    ; print image summary
    mg_log, '%s%s', $
            file_basename(img_file), datatype_str, $
            name='kcor/eod', /info
    mg_log, '%s%s%s%s%s%s%s', $
            exptime_str, cover_str, dshutter_str, $
            diffuser_str, calpol_str, calpang_str, qual_str, $
            name='kcor/eod', /info
  endfor

  num_img = i + 1

  cd, plots_dir

  mg_log, 'nimg: %d', num_img, name='kcor/eod', /debug

  ; plot occulting disc center

  ; set up graphics window & color table
  set_plot, 'Z'
  device, set_resolution=[772, 1000], decomposed=0, set_colors=256, $
          z_buffering=0
  !p.multi = [0, 1, 4]

  erase

  plot, hours, fxcen0, title=pdate + '  Camera 0 occulter raw X center', $
        xtitle='Hours [UT]', ytitle='X center', $
        background=255, color=0, charsize=2.0, $
        yrange = [460.0, 540.0]

  plot, hours, fycen0, title=pdate + '  Camera 0 occulter raw Y center', $
        xtitle='Hours [UT]', ytitle='Y center', $
        background=255, color=0, charsize=2.0, $
        yrange = [460.0, 550.0]

  plot, hours, fxcen1, title=pdate + '  Camera 1 occulter X raw center', $
        xtitle='Hours [UT]', ytitle='X center', $
        background=255, color=0, charsize=2.0, $
        yrange = [460.0, 540.0]

  plot, hours, fycen1, title=pdate + '  Camera 1 occulter Y raw center', $
        xtitle='Hours [UT]', ytitle='Y center', $
        background=255, color=0, charsize=2.0, $
        yrange = [460.0, 540.0]
   
  ocen_gif_filename = string(date, format='(%"%s.kcor.ocen.gif")')
  save = tvrd()
  write_gif, ocen_gif_filename, save

  ; plot occulter radius [pixels]

  device, set_resolution=[772, 500], decomposed=0, set_colors=256, $
          z_buffering=0
  !p.multi = [0, 1, 2]

  erase

  plot, hours, frocc0, title=pdate + '  Camera 0 occulter raw radius (pixels)', $
        xtitle='Hours [UT]', ytitle='X center', $
        background=255, color=0, charsize=1.0, $
        yrange = [170.0, 200.0]

  plot, hours, frocc1, title=pdate + '  Camera 1 occulter raw radius (pixels)', $
        xtitle='Hours [UT]', ytitle='X center', $
        background=255, color=0, charsize=1.0, $
        yrange = [170.0, 200.0]

  rocc_gif_filename = string(date, format='(%"%s.kcor.rocc.gif")')
  save     = tvrd()
  write_gif, rocc_gif_filename, save

  cd, l0_dir

  done:
  cd, start_dir
  set_plot, 'X'

  ; get system time & compute elapsed time since TIC command
  qtime = toc()
  mg_log, 'elapsed_time: %0.1f sec', qtime, name='kcor/eod', /info
  mg_log, '%0.1f sec/image', qtime / num_img, name='kcor/eod', /info
end
