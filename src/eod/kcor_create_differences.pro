; docformat = 'rst'

;+
;  1) Create averaged images from KCor level 2 data, averaging up to 4 images
;     if they are taken < 2 minutes apart
;  2) generate subtractions from averages that are >= 10 minutes apart in time
;  3) create a subtraction every 5 minutes
;  4) check subtractions for quality by checking azimutal scan intensities at
;     1.15 Rsun
;  5) save each subtraction as an annotated GIF and a FITS image with quality
;     value in filename
;
; :History:
;   J. Burkepile (Jan 2018)
;
; :Uses:
;   tscan
;
; :Params:
;   date : in, required, type=string
;     date in the form "YYYYMMDD"
;   l2_files : in, required, type=strarr
;     array of L2 filenames
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;-
pro kcor_create_differences, date, l2_files, run=run
  compile_opt strictarr

  mg_log, 'creating difference images/movies', name='kcor/eod', /info

  date_parts = kcor_decompose_date(date)
  archive_dir = filepath('', subdir=date_parts, root=run->config('results/archive_basedir'))
  fullres_dir = filepath('', subdir=date_parts, root=run->config('results/fullres_basedir'))
  cropped_dir = filepath('', subdir=date_parts, root=run->config('results/croppedgif_basedir'))
  if (run->config('realtime/distribute')) then begin
    if (~file_test(archive_dir, /directory)) then file_mkdir, archive_dir
    if (~file_test(fullres_dir, /directory)) then file_mkdir, fullres_dir
    if (~file_test(cropped_dir, /directory)) then file_mkdir, fullres_dir
  endif

  l2_dir = filepath('level2', subdir=date, root=run->config('processing/raw_basedir'))

  cd, current=current
  cd, l2_dir

  ; set up variables and arrays needed
  l2_file = ''
  base_file = ''
  fits_file = ''
  gif_file = ''

  difference_files = list()

  ; set up julian date intervals for averaging, creating subtractions, and how
  ; often subtractions are created.

  ; currently: average 4 images over a maximum of 2 minutes
  ;            create a subtraction image every 30 seconds
  ;            create subtractions using averaged images 10 minutes apart

  avginterval = run->config('differences/average_interval') / 60.0D / 60.0D / 24.0D
  time_between_subs = run->config('differences/cadence') / 60.0D / 60.0D / 24.0D
  subinterval = run->config('differences/interval') / 60.0D / 60.0D / 24.0D

  n_images_to_average = run->config('differences/n_images_to_average')
  date_julian = dblarr(n_images_to_average)

  ; size of background image stack
  bkdimgnum = ceil(subinterval / float(avginterval))

  nx = 1024
  ny = 1024
  imgsave  = fltarr(nx, ny, n_images_to_average)
  aveimg   = fltarr(nx, ny)
  bkdimg   = fltarr(nx, ny, bkdimgnum)
  bkdtime  = dblarr(2, bkdimgnum)
  filetime = strarr(bkdimgnum)

  savefilename = ''
  avgimghr0    = ''
  avgimghr1    = ''
  avgimgmnt0   = ''
  avgimgmnt1   = ''
  avgimgsec0   = ''
  avgimgsec1   = ''
  imgtime      = strarr(n_images_to_average)

  subimg = fltarr(nx, ny)

  ; set up counting variables

  avgcount  = 0   ; keep track of number of averaged images 
  bkdcount  = 0   ; keep track of number of background images up to 12 for stack storage
  imgcount  = 0   ; keep track of number of images read
  subtcount = 0   ; has a subtraction image been created?
  stopavg   = 0   ; set to 1 if images are more than 2 minutes apart (stop averaging)
  newsub    = 0
  datagap   = 0

  ; read in images and generate subtractions ~10 minutes apart
  f = 0L
  while (f lt n_elements(l2_files)) do begin
    numavg = 0

    ; 0: background images
    ; 1: foreground images
    difference_times = strarr(2, n_images_to_average)
    difference_datetimes = strarr(2, n_images_to_average)

    ; read in up to n_images_to_average images, get time, and average if
    ; images <= avginterval sec apart
    for i = 0, n_images_to_average - 1L do begin
      if (f ge n_elements(l2_files)) then break

      ; already have an image from previous loop as first image
      if (datagap eq 1) then begin
        i = 1
        datagap = 0
      endif

      l2_file = file_basename(l2_files[f])
      img = readfits(l2_file, header, /silent, /noscale)

      f += 1

      imgsave[*, *, i] = float(img)

      ; scaling information for quality scans
      rsun    = fxpar(header, 'RSUN_OBS')         ; solar radius [arcsec/Rsun]
      cdelt1  = fxpar(header, 'CDELT1')           ; resolution   [arcsec/pixel]
      pixrs   = rsun / cdelt1
      r_photo = rsun / cdelt1

      bscale  = fxpar(header, 'BSCALE')

      xcen    = fxpar(header, 'CRPIX1')       ; X center
      ycen    = fxpar(header, 'CRPIX2')       ; Y center
      roll    = 0.0

      ; find image time
      date_obs = fxpar(header, 'DATE-OBS')    ; yyyy-mm-ddThh:mm:ss
      run.time = date_obs

      ; extract fields from DATE_OBS
      yr  = strmid(date_obs,  0, 4)
      mon = strmid(date_obs,  5, 2)
      dy  = strmid(date_obs,  8, 2)
      hr  = strmid(date_obs, 11, 2)
      mnt = strmid(date_obs, 14, 2)
      sec = strmid(date_obs, 17, 2)
      imgtime[i] = string(hr, mnt, sec, format='(a2, a2, a2)')

      ; convert strings to integers
      year   = fix(yr)
      month  = fix(mon)
      day    = fix(dy)
      hour   = fix(hr)
      minute = fix(mnt)
      second = fix(sec)

      ; find julian day
      date_julian[i] = julday(month, day, year, hour, minute, second)

      if (i eq 0) then begin
        aveimg = imgsave[*, *, 0]
        goodheader = header
        avgimghr0  = hr
        avgimgmnt0 = mnt
        avgimgsec0 = sec
        savefilename = l2_file

        difference_times[0, i] = string(hr, mnt, sec, format='%02d:%02d:%02d')
        difference_datetimes[0, i] = string(year, month, day, hour, minute, second, $
                                            format='%04d-%02d-%02dT%02d:%02d:%02d')

        mg_log, '[1] saving image at %s in difference_times[0, %d] ', $
                string(hr, mnt, sec, format='%02d:%02d:%02d'), i, $
                name='kcor/eod', /debug
        numavg = 1
      endif

      ; Once we have read more than one image we check that images are <=
      ; avginterval sec apart

      ; If images are <= avginterval sec apart we average them together
      ; If images are > avginterval sec apart we stop averaging, save avg.
      ;   image and make a subtraction
      if (i gt 0) then begin
        difftime = date_julian[i] - date_julian[0]

        mg_log, '[2] difference %0.2f s, avg interval: %0.2f s', $
                difftime * 60D * 60D * 24D, avginterval * 60D * 60D * 24D, $
                name='kcor/eod', /debug
        if (difftime le avginterval) then begin
          aveimg += imgsave[*, *, i]
          if (i eq 1) then begin
            avgimgyr1 = yr
            avgimgmon1 = mon
            avgimgdy1 = dy

            avgimghr1 = hr
            avgimgmnt1 = mnt
            avgimgsec1 = sec
            ;difference_times[1, i] = string(hr, mnt, sec, format='%s:%s:%s')
          endif
          goodheader = header ; save header in case next image is > avginterval sec in time
          t = string(hr, mnt, sec, format='%s:%s:%s')
          difference_times[0, i] = t
          difference_datetimes[0, i] = string(year, month, day, hour, minute, second, $
                                              format='%04d-%02d-%02dT%02d:%02d:%02d')
          mg_log, '[3] saving image at %s in difference_times[0, %d]', t, i, $
                  name='kcor/eod', /debug
          numavg += 1
        endif

        if ((difftime gt avginterval) || (numavg eq n_images_to_average)) then begin
          stopavg = 1   ; set flag to stop averaging
        endif
      endif

      if (stopavg eq 1) then break
    endfor

    i -= 1
    stopavg = 0

    if (i lt 0L) then begin
      mg_log, 'array index i < 0 (%d)', i, name='kcor/eod', /error
    endif

    ; Make averaged FITS image
    aveimg = aveimg / float(numavg)
    avgcount += 1
    bkdcount += 1

    ; Build up a stack of up to bkdimgnum averaged images to use as future
    ; background images.

    ; FIRST LOOP TO BUILD UP BACKGROUND IMAGE STACK: Initialize the stack with
    ; the first image only.
    if (bkdcount eq 1) then begin
      time_since_sub = date_julian[i]  
      for j = 0L, bkdimgnum - 1L do begin
        bkdimg[*, *, j] = aveimg
        bkdtime[0, j] = date_julian[0]
        bkdtime[1, j] = date_julian[1]
        filetime[j] = imgtime[i]
      endfor
    endif

    ; check in these 2 stacks if image time is already in the stack
    if (bkdcount gt 1 && subtcount eq 0L) then begin
      counter = bkdimgnum - 2
      for k = 0, counter do begin
        bkdtime[*, counter + 1 - k] = bkdtime[*, counter - k]
        bkdimg[*, *, counter + 1 - k] = bkdimg[*, *, counter - k]
        filetime[counter + 1 - k] = filetime[counter - k]
      endfor
      ; for first 10 images, copy current image into 0 position (latest time)
      bkdimg[*, *, 0] = aveimg
      bkdtime[0, 0] = date_julian[0]
      bkdtime[1, 0] = date_julian[1]
      filetime[0] = imgtime[i]
    endif

    if (subtcount ge 1) then begin
      counter = bkdimgnum - 2
      for k = 0, counter do begin
        bkdtime[*, counter + 1 - k] = bkdtime[*, counter - k]
        bkdimg[*, *, counter + 1 - k] = bkdimg[*, *, counter - k]
        filetime[counter + 1 - k] = filetime[counter - k]
      endfor
      bkdimg[*, *, 0] = newbkdimg0
      bkdtime[i, 0] = newbkdtime0
      bkdtime[0, 0] = date_julian[0]
      filetime[0] = newfiletime0
     endif

    ; Create a difference image every time_between_subs observing seconds
    ; Difference the current image from an image taken >= 10 minutes earlier

    ; Has it been time_between_subs minutes since the previous subtraction?
    ; Go thru the stack of 10 images looking for the 'newest' time that is 10
    ; minutes before the current image
    mg_log, '[4] avgcount: %d, date_julian[i] - time_since_sub: %0.2f s, time_between_subs: %0.2f s', $
            avgcount, $
            (date_julian[i] - time_since_sub) * 60D * 60D * 24D, $
            time_between_subs * 60D * 60D * 24D, $
            name='kcor/eod', /debug

    if ((numavg le n_images_to_average) $
          && ((date_julian[i] - time_since_sub) ge time_between_subs)) then begin
      for j = 0L, bkdimgnum - 1L do begin
        mg_log, '[5] date_julian[i] - bkdtime[i, j]: %0.2f s, subinterval: %0.2f s', $
                (date_julian[i] - bkdtime[i, j]) * 60D * 60D * 24D, $
                subinterval * 60D * 60D * 24D, $
                name='kcor/eod', /debug
        if ((date_julian[i] - bkdtime[i, j] ge subinterval) && (newsub eq 0)) then begin
          ; this is the new subtraction image
          subimg = aveimg - bkdimg[*, *, j]
          mg_log, '[6] subtracting j=%d [time: %s]', $
                  j, kcor_jd2time(bkdtime[i, j]), $
                  name='kcor/eod', /debug

          newsub = 1  ;  need to write a new subtraction image
          subtcount += 1L
          time_since_sub = date_julian[i]
          ; need this info to write into FITS and GIF filename
          timestring = filetime[j]
          newbkdimg0 = aveimg    ; save current image as the new bkd image 
          newbkdtime0 = date_julian[i] ; save current time as the new time of bkd image 
          newfiletime0 = imgtime[i]
          difference_times[1, i] = kcor_jd2time(bkdtime[i, j])
          difference_datetimes[1, i] = kcor_jd2time(bkdtime[i, j], /datetime)
        endif
      endfor
    endif

    ; If a subtraction image was created save:

    ; 1) perform a quality control check using an azimuthal scan at 1.15
    ;    solar radii and checking the absolute values of the intensities.
    ;    Flag the filenames with: good, pass, bad
    ; 2) Create annotation for the GIF image
    ; 3) Create GIF and FITS images of the subtraction

    ; 1) SET UP SCAN PARAMETERS and perform quality control scan

    theta_min       = 0.0
    theta_max       = 359.0
    theta_increment = 0.5
    radius          = 1.15

    pointing_ck = 0
    good_value  = run->config('differences/good_max')
    pass_value  = run->config('differences/pass_max')
    threshold_intensity = run->config('differences/threshold_intensity')

    fxaddpar, goodheader, 'AVGTIME0', kcor_combine_times(difference_times[1, *]), $
              ' image times used in bkg avg'
    fxaddpar, goodheader, 'AVGTIME1', kcor_combine_times(difference_times[0, *]), $
              ' image times used in fg avg'

    if (newsub eq 1) then begin
      tscan, l2_file, subimg, pixrs, roll, xcen, ycen, $
             theta_min, theta_max, theta_increment, radius, $
             scan, scandx, ns

      for i = 0, ns - 1 do begin
        if (abs(scan[i]) gt threshold_intensity) then pointing_ck += 1
      endfor

      ; 2) Create annotation for GIF image

      ; convert month from integer to name of month
      name_month = (['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', $
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'])[month - 1]

      date_img = string(dy, name_month, yr, hr, mnt, sec, $
                        format='(%"%s %s %s %sx:%s:%s")')

      ; compute DOY (day-of-year)
      mday      = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
      mday_leap = [0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]   ; leap year

      if ((year mod 4) eq 0) then begin
        doy = (mday_leap[month - 1] + day)
      endif else begin
        doy = (mday[month - 1]) + day
      endelse

      ; 3) Create GIF and FITS images

      set_plot, 'Z'
      device, set_resolution=[1024, 1024], $
              decomposed=0, $
              set_colors=256, $
              z_buffering=0

      display_min    = run->config('differences/display_min')
      display_max    = run->config('differences/display_max')
      display_factor = 1.0e6

      loadct, 0, /silent

      tv, bytscl(display_factor * bscale * subimg, $
                 min=display_factor * display_min, $
                 max=display_factor * display_max)

      xyouts, 4, 990, 'MLSO/HAO/KCOR', color=255, charsize=1.5, /device
      xyouts, 4, 970, 'K-Coronagraph', color=255, charsize=1.5, /device
      xyouts, 512, 1000, 'North', color=255, charsize=1.2, alignment=0.5, $
              /device
      xyouts, 1018, 995, string(format='(a2)', dy) + ' ' $
              + string(format='(a3)', name_month) $
              + ' ' + string(format = '(a4)', yr), $
              /device, alignment=1.0, $
              charsize=1.2, color=255
      xyouts, 1010, 975, 'DOY ' + string(format='(i3)', doy), /device, $
              alignment=1.0, charsize=1.2, color=255
      xyouts, 1018, 955, string(format='(a2)', hr) + ':' $
              + string(format = '(a2)', mnt) $
              + ':' + string(format='(a2)', sec) + ' UT', $
              /device, alignment=1.0, charsize=1.2, color=255
      xyouts, 1010, 935, 'MINUS', /device, alignment=1.0, charsize=1.2, color=255
      xyouts, 1018, 915, string(format='(a2)', strmid(timestring, 0, 2)) + ':' $
              + string(format = '(a2)', strmid(timestring, 2, 2)) $
              + ':' + string(format='(a2)', strmid(timestring, 4, 2)) + ' UT', $
              /device, alignment=1.0, charsize=1.2, color=255

      xyouts, 22, 512, 'East', color=255, charsize=1.2, alignment=0.5, $
              orientation=90., /device
      xyouts, 1012, 512, 'West', color=255, charsize=1.2, alignment=0.5, $
              orientation=90., /device
      xyouts, 4, 46, 'Subtraction', color=255, charsize=1.2, /device
      xyouts, 4, 26, string(display_min, display_max, $
                            format='("min/max: ", e0.1, ", ", e0.1)'), $
              color=255, charsize=1.2, /device
      xyouts, 1018, 6, 'Circle = photosphere.', $
              color=255, charsize=1.2, /device, alignment=1.0

      ; image has been shifted to center of array
      kcor_add_directions, [511.5, 511.5], r_photo, $
                           dimensions=[1024, 1024], $
                           charsize=1.0, color=255
      kcor_suncir, 1024, 1024, 511.5, 511.5, 0, 0, r_photo, 0.0, log_name='kcor/eod'
      ; draw circle at photosphere
      ;tvcircle, r_photo, 511.5, 511.5, color=255, /device

      device, decomposed = 1 
      save = tvrd()

      case 1 of
        pointing_ck le good_value: status = 'good'
        pointing_ck le pass_value: status = 'pass'
        else: status = 'bad'
      endcase

      name = strmid(file_basename(l2_file), 0, 20)

      mg_log, 'writing %s-%s GIF/FTS file (%s)', $
              strmid(name, 9, 6), timestring, status, $
              name='kcor/eod', /info

      gif_basename = string(name, timestring, status, format='(%"%s_minus_%s_%s.gif")')
      write_gif, gif_basename, save

      sxaddpar, goodheader, 'DATE-OBS', difference_datetimes[1, 0]
      indices = where(difference_times[0, *] ne '', /null)
      sxaddpar, goodheader, 'DATE-END', difference_datetimes[0, indices[-1]]
      sxaddpar, goodheader, 'PRODUCT', 'level 2 pB subtraction', $
                ' difference of two level 2 pB images', $
                after='OBJECT'

      fits_basename = string(name, timestring, status, format='(%"%s_minus_%s_%s.fts")')
      writefits, fits_basename, subimg, goodheader
      difference_files->add, fits_basename

      if (run->config('realtime/distribute')) then begin
        ; check status -- only good and pass get archived
        if (status eq "good" || status eq "pass") then begin
          file_copy, gif_basename, fullres_dir, /overwrite

          kcor_zip_files, fits_basename, run=run
          file_copy, fits_basename + '.gz', archive_dir, /overwrite
        endif
      endif

      if (datagap eq 2) then datagap = 0

      ; under following conditions need to save image 2 for next average image
      ; loop
      ; TODO: do these index=1 be index=i
      if ((datagap eq 1) || (newsub eq 0)) then begin
        goodheader = header
        savefilename = l2_file
        aveimg = imgsave[*, *, 1]
        imgtime[0] = imgtime[1]
        date_julian[0] = date_julian[1]

        avgimghr0 = avgimghr1
        avgimgmnt0 = avgimgmnt1
        avgimgsec0 = avgimgsec1
        difference_times[0, i] = string(avgimghr1, avgimgmnt1, avgimgsec1, $
                                        format='%02d:%02d:%02d')
        difference_datetimes[0, i] = string(avgimgyr1, avgimgmon1, avgimgdy1, $
                                            avgimghr1, avgimgmnt1, avgimgsec1, $
                                            format='%04d-%02d-%02dT%02d:%02d:%02d')
      endif

      newsub = 0
    endif
  endwhile

  n_all_difference_files = difference_files->count()
  if (n_all_difference_files gt 0L) then begin
    all_difference_filenames = difference_files->toarray()
    ok_difference_indices = where(strpos(all_difference_filenames, 'good') ge 0 $
                                    or strpos(all_difference_filenames, 'pass') ge 0, $
                                  n_ok_difference_files, /null)
    ok_difference_filenames = all_difference_filenames[ok_difference_indices]
  endif

  if (run->config('database/update') $
        && n_all_difference_files gt 0L $
        && n_ok_difference_files gt 0L) then begin
    obsday_index = mlso_obsday_insert(date, $
                                      run=run, $
                                      database=db, $
                                      status=db_status, $
                                      log_name='kcor/eod')
    if (db_status eq 0L) then begin
      mg_log, 'adding %d difference FITS files to database', n_ok_difference_files, $
              name='kcor/eod', /info
      kcor_img_insert, date, ok_difference_filenames, run=run, $
                       database=db, obsday_index=obsday_index, log_name='kcor/eod'
    endif else begin
      mg_log, 'error connecting to database', name='kcor/eod', /warn
      goto, done
    endelse
  endif else begin
    mg_log, 'not adding difference files to database', name='kcor/eod', /info
  endelse

  ; create mp4 of difference images
  difference_gif_filenames = file_search('*_minus_*_{good,pass}*.gif', $
                                         count=n_difference_gif_files)
  if (n_difference_gif_files gt 0L) then begin
    mg_log, 'creating difference mp4', name='kcor/eod', /info
    difference_mp4_filename = string(date, format='(%"%s_kcor_minus.mp4")')
    kcor_create_mp4, difference_gif_filenames, difference_mp4_filename, $
                     run=run, status=status
    if (status eq 0 && run->config('realtime/distribute')) then begin
      file_copy, difference_mp4_filename, fullres_dir, /overwrite
    endif
  endif else begin
    mg_log, 'no difference GIFs, not creating difference mp4', $
            name='kcor/eod', /info
  endelse

  done:
  obj_destroy, difference_files
  cd, current
  mg_log, 'done', name='kcor/eod', /info
end


; main-level example program

date = '20160211'
config_filename = filepath('kcor.latest.cfg', $
                           subdir=['..', '..', '..', 'kcor-config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)

l2_files = file_search(filepath('*_l2_pb.fts.gz', $
                                subdir=[date, 'level2'], $
                                root=run->config('processing/raw_basedir')), $
                       count=n_l2_files)

kcor_create_differences, date, l2_files, run=run

obj_destroy, run

end
