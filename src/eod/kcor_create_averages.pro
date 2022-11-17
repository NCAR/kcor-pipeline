; docformat = 'rst'

;+
; Create averages from L2 data.
;
;  1) create averaged images from KCor level 2 data, averaging up to 8 images
;     taken < 3 minutes apart
;  2) save each average an annotated GIF and a FITS image
;  3) create a daily averaged image of up to 40 images taken < 15 min. apart
;     for the daily average we will skip the first 8 images (~2 minutes) of data
;  4) save the daily average as an annotated gif and a fits image
;
; :Author:
;   J. Burkepile, Jan 2018
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
pro kcor_create_averages, date, l2_files, run=run
  compile_opt strictarr

  mg_log, 'creating average movies', name='kcor/eod', /info

  date_parts = kcor_decompose_date(date)
  archive_dir = filepath('', subdir=date_parts, root=run->config('results/archive_basedir'))
  fullres_dir = filepath('', subdir=date_parts, root=run->config('results/fullres_basedir'))
  cropped_dir = filepath('', subdir=date_parts, root=run->config('results/croppedgif_basedir'))

  if (run->config('realtime/distribute')) then begin
    if (~file_test(archive_dir, /directory)) then file_mkdir, archive_dir
    if (~file_test(fullres_dir, /directory)) then file_mkdir, fullres_dir
    if (~file_test(cropped_dir, /directory)) then file_mkdir, cropped_dir
  endif

  l2_dir = filepath('level2', subdir=date, root=run->config('processing/raw_basedir'))

  cd, current=current
  cd, l2_dir

  ; set up variables and arrays needed

  imgsave     = fltarr(1024, 1024, 8)
  avgimg      = fltarr(1024, 1024)
  imgtimes    = strarr(8)
  imgendtimes = strarr(8)
  timestring  = strarr(2)

  dailyavg = fltarr(1024, 1024, 48)  ; this will hold up to 15 min. of data
  dailytimes = strarr(48)            ; this will hold up to 15 min. of data
  dailyendtimes = strarr(48)

  hst = ''
  daily_hst = ''

  n_skip = 0                         ; number of daily times to skip

  date_julian = dblarr(8)

  ; Set up julian date intervals for averaging
  ; Currently: 	average 8 images over a maximum of 3 minutes
  ;             create 1 daily average of 40 images over a maximum of 15 minutes

  ; ** NOTE: 2 minutes in julian date units = 1.38889e-03
  ; ** NOTE: 3 minutes in julian date units = 2.08334e-03
  ; ** NOTE: 5 minutes in julian date units = 3.47222e-03
  ; ** NOTE:10 minutes in julian date units = 6.94445e-03
  ; ** NOTE:15 minutes in julian date units = 1.04167e-02

  avginterval = run->config('averaging/interval') / 60.0D / 60.0D / 24.0D
  dailyavgval = run->config('averaging/daily_interval') / 60.0D / 60.0D / 24.0D

  display_min   = run->epoch('display_min')
  display_max   = run->epoch('display_max')
  display_exp   = run->epoch('display_exp')
  display_gamma = run->epoch('display_gamma')

  ; set up counting variables
  dailycount = 0  ; want to average up to 40 images in < 15 minutes for daily avg.
  stopavg = 0  ; set to 1 if images are more than 3 minutes apart (stop averaging)

  mg_log, 'averaging for %d L2 files', n_elements(l2_files), name='kcor/eod', /info

  ; read in images and generate subtractions ~10 minutes apart
  f = 0L
  while (f lt n_elements(l2_files)) do begin
    numavg = 0
    timestring[*] = ''

    ; read in up to 8 images, get time, and average if images <= 3 min apart
    for i = 0, 7 do begin
      if (f ge n_elements(l2_files)) then break

      ; if last image was not used in average (i.e. stopavg = 1) then begin with
      ; the last image else read in a new image
      if (stopavg eq 1 ) then begin
        imgsave[0, 0, 0] = imgsave[*, *, last]
        avgimg = imgsave[*, *, last]
        if (dailycount lt 48 and date_julian[i] - firsttime lt dailyavgval) then begin
          if (dailycount eq n_skip) then begin
            daily_hst = hst
            daily_savename = strmid(file_basename(l2_file), 0, 23)
            dailysaveheader = header
          endif

          dailyavg[0, 0, dailycount] = imgsave[*, *, last]
          dailytimes[dailycount] = imgtimes[last]
          dailyendtimes[dailycount] = imgendtimes[last]
          dailycount += 1
        endif
        date_julian[0] = date_julian[last]
        hst = tmp_hst
        stopavg = 0
        numavg = 1
        saveheader = header
        savename = strmid(file_basename(l2_file), 0, 23)
        imgtimes[0]    = imgtimes[last]
        imgendtimes[0] = imgendtimes[last]
        timestring[0]  = strmid(imgtimes[0], 11)
      endif else begin
        if (f ge n_elements(l2_files)) then break

        l2_file = file_basename(l2_files[f])
        img = readfits(l2_file, header, /silent, /noscale)

        f += 1
        imgsave[0, 0, i] = float(img)

        ; read in info to draw a circle at photosphere in gif images
        rsun    = fxpar(header, 'RSUN_OBS')         ; solar radius [arcsec/Rsun]
        cdelt1  = fxpar(header, 'CDELT1')       ; resolution   [arcsec/pixel]
        pixrs   = rsun / cdelt1
        r_photo = rsun / cdelt1

        bscale  = fxpar(header, 'BSCALE')

        xcen    = fxpar(header, 'CRPIX1')       ; X center
        ycen    = fxpar(header, 'CRPIX2')       ; Y center
        roll    = 0.0

        ; find image time
        date_obs = fxpar(header, 'DATE-OBS')    ; yyyy-mm-ddThh:mm:ss
        date_end = fxpar(header, 'DATE-END')    ; yyyy-mm-ddThh:mm:ss
        tmp_hst  = fxpar(header, 'DATE_HST')    ; yyyy-mm-ddThh:mm:ss
        run.time = date_obs

        ; extract fields from DATE_OBS
        yr   = strmid(date_obs,  0, 4)
        mon  = strmid(date_obs,  5, 2)
        dy   = strmid(date_obs,  8, 2)
        hr   = strmid(date_obs, 11, 2)
        mnt  = strmid(date_obs, 14, 2)
        sec  = strmid(date_obs, 17, 2)

        imgtimes[i]    = date_obs
        imgendtimes[i] = date_end

        ; convert strings to integers
        year   = fix(yr)
        month  = fix(mon)
        day    = fix(dy)
        hour   = fix(hr)
        minute = fix(mnt)
        second = fix(sec)

        ; find julian day
        date_julian[i] = julday(month, day, year, hour, minute, second)

        ; save first image time for making daily avg. img.
        if (numavg eq 0) then begin
          hst = tmp_hst
          firsttime = date_julian[0]
        endif

        if (dailycount eq 0L) then begin
          daily_savename = strmid(file_basename(l2_file), 0, 23)
          dailyavg[0, 0, dailycount] = imgsave[*, *, 0]
          dailysaveheader = header
          dailytimes[dailycount] = imgtimes[0]
          dailyendtimes[dailycount] = imgendtimes[0]
          dailycount += 1
        endif

        if (i eq 0) then begin
          savename = strmid(file_basename(l2_file), 0, 23)
          avgimg = imgsave[*, *, 0]
          saveheader = header
          numavg = 1
          timestring[0] = strmid(imgtimes[0], 11)
        endif
      endelse

      ; Once we have read more than one image we check that images are <= 3
      ; minutes apart.
      ; If images are <= 3 minutes apart we average them together
      ; If images are > 3 minutes apart we stop averaging, and save avg. image
      if (i gt 0) then begin
        difftime = date_julian[i] - date_julian[0]

        if (difftime le avginterval) then begin
          avgimg += imgsave[*, *, i]
          numavg += 1
          if (i le 3) then timestring[0] = timestring[0] + ' ' + strmid(imgtimes[i], 11)
          if (i gt 3) then timestring[1] = timestring[1] + ' ' + strmid(imgtimes[i], 11)
        endif

        if (difftime gt avginterval) then begin
          stopavg = 1  ; set flag to stop averaging
          last = i
        endif

        if (dailycount lt 48 and date_julian[i] - firsttime lt dailyavgval) then begin
          if (dailycount eq n_skip) then begin
            daily_hst = hst
            daily_savename = strmid(file_basename(l2_file), 0, 23)
            dailysaveheader = header
          endif

          dailyavg[0, 0, dailycount] = imgsave[*, *, i]
          dailytimes[dailycount] = imgtimes[i]
          dailyendtimes[dailycount] = imgendtimes[i]
          dailycount += 1
        endif
      endif

      if (stopavg eq 1) then break
    endfor

    ; clean up extra spaces
    timestring = strtrim(timestring, 2)

    ; make sure you use the time from the saved header
    date_obs = fxpar(saveheader, 'DATE-OBS')    ; yyyy-mm-ddThh:mm:ss

    ; extract fields from DATE_OBS
    yr   = strmid(date_obs,  0, 4)
    mon  = strmid(date_obs,  5, 2)
    dy   = strmid(date_obs,  8, 2)
    hr   = strmid(date_obs, 11, 2)
    mnt  = strmid(date_obs, 14, 2)
    sec  = strmid(date_obs, 17, 2)

    ; convert strings to integers
    year   = fix(yr)
    month  = fix(mon)
    day    = fix(dy)
    hour   = fix(hr)
    minute = fix(mnt)
    second = fix(sec)

    ; make averaged image
    avgimg = avgimg / float(numavg)

    ; create annotation for GIF image
    ; convert month from integer to name of month
    name_month = (['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', $
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'])[month - 1]

    date_img = string(dy, name_month, yr, hr, mnt, sec, $
                      format='(%"%s %s %s %s:%s:%s")')

    ; compute DOY [day-of-year]
    mday      = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
    mday_leap = [0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]   ; leap year

    if ((year mod 4) eq 0) then begin
      doy = mday_leap[month - 1] + day
    endif else begin
      doy = mday[month - 1] + day
    endelse

    ; set up device, color table and scaling
    set_plot, 'Z'
    device, set_resolution=[1024, 1024], $
            decomposed=0, $
            set_colors=256, $
            z_buffering=0, $
            set_pixel_depth=8

    loadct, 0, /silent
    gamma_ct, display_gamma, /current
    tvlct, red, green, blue, /get

    ; create fullres (1024x1024) GIF images
    display_factor = 1.0e6
    tv, bytscl((display_factor * bscale * avgimg)^display_exp, $
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
    xyouts, 1018, 975, 'DOY ' + string(format='(i3)', doy), /device, $
            alignment=1.0, charsize=1.2, color=255
    avgtimes = strsplit(strjoin(timestring, ' '), /extract)
    xyouts, 1018, 955, string(avgtimes[0], format='(%"%s UT to")'), $
            /device, alignment=1.0, charsize=1.2, color=255 
    xyouts, 1018, 935, string(avgtimes[-1], format='(%"%s UT")'), $
            /device, alignment=1.0, charsize=1.2, color=255 

    xyouts, 22, 512, 'East', color=255, charsize=1.2, alignment=0.5, $
            orientation=90., /device
    xyouts, 1012, 512, 'West', color=255, charsize=1.2, alignment=0.5, $
            orientation=90., /device
    xyouts, 4, 46, 'Level 2 Avg', color=255, charsize=1.2, /device
    xyouts, 4, 26, string(display_min, display_max, $
                          format='(%"min/max: %0.2g, %0.2g")'), $
            color=255, charsize=1.2, /device
    xyouts, 4, 6, string(display_exp, $
                         display_gamma, $
                         format='("scaling: Intensity ^ ", f3.1, ", gamma=", f4.2)'), $
            color=255, charsize=1.2, /device
    xyouts, 1018, 6, 'Circle = photosphere', $
            color=255, charsize=1.2, /device, alignment=1.0

    ; image has been shifted to center of array
    kcor_add_directions, [511.5, 511.5], r_photo, $
                         dimensions=[1024, 1024], $
                         charsize=1.0, color=255
    kcor_suncir, 1024, 1024, 511.5, 511.5, 0, 0, r_photo, 0.0, log_name='kcor/eod'

    ; draw circle at photosphere
    ;tvcircle, r_photo, 511.5, 511.5, color=255, /device

    save = tvrd()

    gif_basename = strmid(savename, 0, 23) + '_avg.gif'

    if (numavg gt 1L) then begin
      write_gif, gif_basename, save, red, green, blue
      if (run->config('realtime/distribute')) then begin
        file_copy, gif_basename, fullres_dir, /overwrite
      endif

      ; create cropped (512 x 512) GIF images
      kcor_cropped_gif, bscale * avgimg, date, kcor_parse_dateobs(date_obs), $
                        /average, output_filename=cgif_filename, run=run, $
                        log_name='kcor/eod', $
                        level=2
      if (run->config('realtime/distribute')) then begin
        file_copy, cgif_filename, cropped_dir, /overwrite
      endif
    endif else begin
      mg_log, 'not writing average GIFs with single image: %s', gif_basename, $
              name='kcor/eod', /debug
    endelse

    ; Create fullres (1024x1024) FITS image
    ; Create up to 2 new keywords that record the times of the images used in
    ; the avg. Each keyword holds up 4 image times to accommodate up to 8 images
    ; in the avg.
    fxaddpar, saveheader, 'AVGTIME0', timestring[0], ' Img times used in avg.'
    if (numavg gt 3) then begin
      fxaddpar, saveheader, 'AVGTIME1', timestring[1], ' Img times used in avg.'
    endif
    name = strmid(savename, 0, 15) + '_kcor_l2'
    fits_filename = string(name, format='(%"%s_avg.fts")')

    fxaddpar, saveheader, 'DATE-OBS', imgtimes[0]
    fxaddpar, saveheader, 'DATE-END', imgtimes[numavg - 1]
    fxaddpar, saveheader, 'DATE_HST', hst

    if (numavg gt 1L) then begin
      mg_log, 'writing %s', fits_filename, name='kcor/eod', /info
      writefits, fits_filename, avgimg, saveheader
    endif else begin
      mg_log, 'not writing average FITS with single image: %s', fits_filename, $
              name='kcor/eod', /debug
    endelse
  endwhile

  ; zip average FITS files
  zipped_avg_glob = '*_avg.fts.gz'
  zipped_avg_files = file_search(zipped_avg_glob, count=n_avg_files)
  if (n_avg_files gt 0L) then file_delete, zipped_avg_files, /allow_nonexistent

  unzipped_avg_glob = '*_avg.fts'
  unzipped_avg_files = file_search(unzipped_avg_glob, count=n_avg_files)
  if (n_avg_files gt 0L) then begin
    mg_log, 'zipping %d average FITS files...', n_avg_files, $
            name='kcor/eod', /info
    gzip_cmd = string(run->config('externals/gzip'), unzipped_avg_glob, $
                      format='(%"%s %s")')
    spawn, gzip_cmd, result, error_result, exit_status=status
    if (status ne 0L) then begin
      mg_log, 'problem zipping average files with command: %s', gzip_cmd, $
              name='kcor/eod', /error
      mg_log, '%s', strjoin(error_result, ' '), name='kcor/eod', /error
    endif
  endif
 
  if (run->config('realtime/distribute') && n_avg_files gt 0L) then begin
    mg_log, 'copying %d average files to archive dir', n_avg_files, $
            name='kcor/eod', /info
    file_copy, unzipped_avg_files + '.gz', archive_dir, /overwrite
  endif

  if (run->config('database/update')) then begin
    obsday_index = mlso_obsday_insert(date, $
                                      run=run, $
                                      database=db, $
                                      status=db_status, $
                                      log_name='kcor/eod')
    if (db_status eq 0L) then begin
      mg_log, 'adding %d average FITS files to database', n_avg_files, $
              name='kcor/eod', /info
      kcor_img_insert, date, unzipped_avg_files, run=run, $
                       database=db, obsday_index=obsday_index, log_name='kcor/eod'
    endif else begin
      mg_log, 'error connecting to database', name='kcor/eod', /warn
      goto, done
    endelse
  endif else begin
    mg_log, 'not adding daily average file to database', name='kcor/eod', /info
  endelse

  mg_log, 'making extended averages', name='kcor/eod', /info

  ; make daily average 1024x1024 GIF ; 512x512 gif; and 1024x1024 FITS image
  set_plot, 'Z'
  device, set_resolution=[1024, 1024], $
          decomposed=0, $
          set_colors=256, $
          z_buffering=0, $
          set_pixel_depth=8
  erase

  daily = fltarr(1024, 1024)
  ; don't use the first 8 images (2 min.) of the day
  n_daily_skip = dailycount lt 40L ? 0L : 8L
  for i = n_daily_skip, dailycount - 1L do begin
    daily += dailyavg[*, *, i] 
  endfor

  daily /= float(dailycount) - float(n_daily_skip)

  display_factor = 1.0e6
  tv, bytscl((display_factor * bscale * daily)^display_exp, $
             min=display_factor * display_min, $
             max=display_factor * display_max)

  ; make sure you use the time from the daily saved header
  date_obs = fxpar(dailysaveheader, 'DATE-OBS')    ; yyyy-mm-ddThh:mm:ss

  ; extract fields from DATE_OBS
  yr   = strmid(date_obs,  0, 4)
  mon  = strmid(date_obs,  5, 2)
  dy   = strmid(date_obs,  8, 2)
  hr   = strmid(date_obs, 11, 2)
  mnt  = strmid(date_obs, 14, 2)
  sec  = strmid(date_obs, 17, 2)

  ; convert strings to integers
  year   = fix(yr)
  month  = fix(mon)
  day    = fix(dy)
  hour   = fix(hr)
  minute = fix(mnt)
  second = fix(sec)

  ; make averaged image
  avgimg = avgimg / float(numavg)

  ; create annotation for GIF image
  ; convert month from integer to name of month
  name_month = (['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', $
                 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'])[month - 1]

  date_img = string(dy, name_month, yr, hr, mnt, sec, $
                    format='(%"%s %s %s %s:%s:%s")')

  ; compute DOY [day-of-year]
  mday      = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
  mday_leap = [0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]   ; leap year

  if ((year mod 4) eq 0) then begin
    doy = mday_leap[month - 1] + day
  endif else begin
    doy = mday[month - 1] + day
  endelse

  xyouts, 4, 990, 'MLSO/HAO/KCOR', color=255, charsize=1.5, /device
  xyouts, 4, 970, 'K-Coronagraph', color=255, charsize=1.5, /device
  xyouts, 512, 1000, 'North', color=255, charsize=1.2, alignment=0.5, $
          /device
  xyouts, 1018, 995, $
          string(format='(a2)', dy) + ' ' $
            + string(format='(a3)', name_month) $
            + ' ' + string(format = '(a4)', yr), $
          /device, alignment=1.0, $
          charsize=1.2, color=255
  xyouts, 1018, 975, 'DOY ' + string(format='(i3)', doy), /device, $
          alignment=1.0, charsize=1.2, color=255
  xyouts, 1018, 955, $
          string(strmid(dailytimes[n_skip], 11), format='(%"%s UT to")'), $
          /device, alignment=1.0, charsize=1.2, color=255
  xyouts, 1018, 935, $
          string(strmid(dailytimes[dailycount - 1], 11), format='(%"%s UT")'), $
          /device, alignment=1.0, charsize=1.2, color=255

  xyouts, 22, 512, 'East', color=255, charsize=1.2, alignment=0.5, $
          orientation=90., /device
  xyouts, 1012, 512, 'West', color=255, charsize=1.2, alignment=0.5, $
          orientation=90., /device
  xyouts, 4, 46, 'Level 2 Avg', color=255, charsize=1.2, /device
  xyouts, 4, 26, string(display_min, display_max, $  
                        format='(%"min/max: %0.2g, %0.2g")'), $
          color=255, charsize=1.2, /device
  xyouts, 4, 6, string(display_exp, $     
                       display_gamma, $
                       format='("scaling: Intensity ^ ", f3.1, ", gamma=", f4.2)'), $
          color=255, charsize=1.2, /device
  xyouts, 1018, 6, 'Circle = photosphere.', $
          color=255, charsize=1.2, /device, alignment=1.0

  ; image has been shifted to center of array
  kcor_add_directions, [511.5, 511.5], r_photo, $
                       dimensions=[1024, 1024], $
                       charsize=1.0, color=255
  kcor_suncir, 1024, 1024, 511.5, 511.5, 0, 0, r_photo, 0.0, log_name='kcor/eod'

  device, decomposed=1
  save = tvrd()

  if (n_elements(daily_savename) gt 0L) then begin
    gif_filename = strmid(daily_savename, 0, 23) + '_extavg.gif'
    write_gif, gif_filename, save, red, green, blue  
    if (run->config('realtime/distribute')) then begin
      mg_log, 'copying extended average GIF to cropped dir', $
              name='kcor/eod', /debug
      file_copy, gif_filename, fullres_dir, /overwrite
    endif
  endif else begin
    mg_log, 'no extended average for this day', name='kcor/eod', /warn
  endelse

  ; create extavg cropped GIF image

  if (n_elements(daily_savename) gt 0L) then begin
    kcor_cropped_gif, bscale * daily, date, kcor_parse_dateobs(date_obs), $
                      /daily, /average, output_filename=cgif_filename, run=run, $
                      log_name='kcor/eod', $
                      level=2

    if (run->config('realtime/distribute')) then begin
      mg_log, 'copying cropped extended average GIF to cropped dir', $
              name='kcor/eod', /debug
      file_copy, cgif_filename, cropped_dir, /overwrite
    endif
  endif

  ; create extavg fullres 1024x1024 FITS
  ;   - save times used to make the daily average image in the header
  ;   - create 10 FITS keywords, each holds 4 image times to accommodate up to
  ;     40 images in the average

  n_times_per_keyword = 4
  n_daily_times = n_elements(dailytimes[n_skip:*])
  n_keywords = ceil(n_daily_times / float(n_times_per_keyword))

  keyword_times = strarr(n_times_per_keyword, n_keywords)
  keyword_times[0] = strmid(dailytimes[n_skip:*], 11)
  keyword_times = strjoin(keyword_times, ' ')

  for k = 0L, n_keywords - 1L do begin
    fxaddpar, dailysaveheader, string(k, format='(%"AVGTIME%d")'), keyword_times[k], $
              ' Image times used in avg.'
  endfor

  fxaddpar, dailysaveheader, 'DATE-OBS', dailytimes[n_skip]
  fxaddpar, dailysaveheader, 'DATE-END', dailyendtimes[dailycount - 1]
  fxaddpar, dailysaveheader, 'DATE_HST', daily_hst

  if (n_elements(daily_savename) gt 0L) then begin
    name = strmid(daily_savename, 0, 23)
    daily_fits_average_filename = string(name, format='(%"%s_extavg.fts")')

    mg_log, 'writing %s', daily_fits_average_filename, name='kcor/eod', /info
    writefits, daily_fits_average_filename, daily, dailysaveheader
    ; remove zipped version if already exists
    file_delete,  daily_fits_average_filename + '.gz', /allow_nonexistent

    mg_log, 'zipping daily FITS average file...', name='kcor/eod', /info
    gzip_cmd = string(run->config('externals/gzip'), daily_fits_average_filename, $
                      format='(%"%s %s")')
    spawn, gzip_cmd, result, error_result, exit_status=status
    if (status ne 0L) then begin
      mg_log, 'problem zipping daily average file with command: %s', gzip_cmd, $
              name='kcor/eod', /error
      mg_log, '%s', strjoin(error_result, ' '), name='kcor/eod', /error
    endif

    if (run->config('realtime/distribute')) then begin
      mg_log, 'copying daily average file to archive', name='kcor/eod', /info
      file_copy, daily_fits_average_filename + '.gz', archive_dir, /overwrite
    endif else begin
      mg_log, 'not copying daily average file to archive', name='kcor/eod', /info
    endelse

    if (run->config('database/update')) then begin
      mg_log, 'adding daily average file to database', name='kcor/eod', /info
      kcor_img_insert, date, daily_fits_average_filename, run=run, $
                       database=db, obsday_index=obsday_index, log_name='kcor/eod'
    endif else begin
      mg_log, 'not adding daily average file to database', name='kcor/eod', /info
    endelse
  endif

  done:
  cd, current
  if (obj_valid(db)) then obj_destroy, db
  mg_log, 'done', name='kcor/eod', /info
end


; main-level example program

; setup
date = '20210307'
config_filename = filepath('kcor.latest.cfg', $
                           subdir=['..', '..', 'config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)

; clean old averages
old_average_files = file_search(filepath('*avg*', $
                                         subdir=[date, 'level2'], $
                                         root=run->config('processing/raw_basedir')), $
                                count=n_old_average_files)
if (n_old_average_files gt 0L) then begin
  file_delete, old_average_files, /allow_nonexistent
endif

; create new averages
l2_zipped_fits_glob = '*_l2.fts.gz'
l2_zipped_files = file_search(filepath(l2_zipped_fits_glob, $
                                       subdir=[date, 'level2'], $
                                       root=run->config('processing/raw_basedir')), $
                              count=n_l2_zipped_files)

kcor_create_averages, date, l2_zipped_files, run=run

; cleanup
obj_destroy, run

end

