; docformat = 'rst'

;+
; Create averages from L1 data.
;
;  1) create averaged images from KCor level 1 data, averaging up to 8 images
;     taken < 3 minutes apart
;  2) save each average an annotated GIF and a FITS image
;  3) create a daily averaged image of up to 40 images taken < 15 min. apart
;     for the daily average we will skip the first 8 images (~2 minutes) of data
;  4) save the daily average as an annotated gif and a fits image
;
; :Todo:
;   re-create the nrgf images (FITS and GIF) in a separate routine using the
;   averaged FITS images created here.
;
; :Author:
;   J. Burkepile, Jan 2018
;
; :Params:
;   date : in, required, type=string
;     date in the form "YYYYMMDD"
;   l1_files : in, required, type=strarr
;     array of L1 filenames
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;- 
pro kcor_create_averages, date, l1_files, run=run
  compile_opt strictarr

  mg_log, 'creating average movies', name='kcor/eod', /info

  date_parts = kcor_decompose_date(date)
  archive_dir = filepath('', subdir=date_parts, root=run.archive_basedir)
  fullres_dir = filepath('', subdir=date_parts, root=run.fullres_basedir)
  cropped_dir = filepath('', subdir=date_parts, root=run.croppedgif_basedir)

  if (run.distribute) then begin
    if (~file_test(archive_dir, /directory)) then file_mkdir, archive_dir
    if (~file_test(fullres_dir, /directory)) then file_mkdir, fullres_dir
    if (~file_test(cropped_dir, /directory)) then file_mkdir, cropped_dir
  endif

  l1_dir = filepath('level1', subdir=date, root=run.raw_basedir)

  cd, current=current
  cd, l1_dir

  ; set up variables and arrays needed

  imgsave    = fltarr(1024,1024,8)
  avgimg     = fltarr(1024,1024)
  imgtime    = strarr(8)
  timestring = strarr(2)

  dailyavg = fltarr(1024, 1024, 48)  ; this will hold up to 15 min. of data
  dailytimes = strarr(48)            ; this will hold up to 15 min. of data
  dailytimestring = strarr(10)

  date_julian = dblarr(8)

  ; Set up julian date intervals for averaging  
  ; Currently: 	average 8 images over a maximum of 3 minutes
  ;               create 1 daily average of 40 images over a maximum of 15 minutes

  ; ** NOTE: 2 minutes in julian date units = 1.38889e-03
  ; ** NOTE: 3 minutes in julian date units = 2.08334e-03
  ; ** NOTE: 5 minutes in julian date units = 3.47222e-03
  ; ** NOTE:10 minutes in julian date units = 6.94445e-03
  ; ** NOTE:15 minutes in julian date units = 1.04167e-02

  avginterval = run.average_interval / 60.0D / 60.0D / 24.0D
  dailyavgval = run.daily_average_interval / 60.0D / 60.0D / 24.0D

  ; set up counting variables
  dailycount = 0  ; want to average up to 40 images in < 15 minutes for daily avg.
  stopavg = 0  ; set to 1 if images are more than 3 minutes apart (stop averaging)

  mg_log, 'averaging for %d L1 files', n_elements(l1_files), name='kcor/eod', /info

  ; read in images and generate subtractions ~10 minutes apart
  f = 0L
  while (f lt n_elements(l1_files)) do begin
    numavg = 0
    timestring[*] = ''

    ; read in up to 8 images, get time, and average if images <= 3 min apart
    for i = 0, 7 do begin
      if (f ge n_elements(l1_files)) then break

      ; If last image was not used in average (i.e. stopavg = 1) then begin with
      ; the last image else read in a new image
      if (stopavg eq 1 ) then begin
        imgsave[0, 0, 0] = imgsave[*, *, last]
        avgimg = imgsave[*, *, last]
        if (dailycount lt 48 and date_julian[i] - firsttime lt dailyavgval) then begin
          dailyavg[0, 0, dailycount] = imgsave[*, *, last]
          dailytimes[dailycount] = imgtime[last]
	  dailycount += 1
        endif
        date_julian[0] = date_julian[last]
        stopavg = 0
        numavg = 1
      endif else begin
        if (f ge n_elements(l1_files)) then break

        l1_file = file_basename(l1_files[f])
        savename = strmid(file_basename(l1_file), 0, 23)

        img = readfits(l1_file, header, /silent)

        f += 1
        imgsave[0, 0, i] = float(img)

        ; read in info to draw a circle at photosphere in gif images
        rsun    = fxpar(header, 'RSUN')         ; solar radius [arcsec/Rsun]
        cdelt1  = fxpar(header, 'CDELT1')       ; resolution   [arcsec/pixel]
        pixrs   = rsun / cdelt1
        r_photo = rsun / cdelt1
        xcen    = fxpar(header, 'CRPIX1')       ; X center
        ycen    = fxpar(header, 'CRPIX2')       ; Y center
        roll    = 0.0

        ; find image time
        date_obs = fxpar(header, 'DATE-OBS')       ; yyyy-mm-ddThh:mm:ss

        ; extract fields from DATE_OBS
        yr   = strmid(date_obs,  0, 4)
        mon  = strmid(date_obs,  5, 2)
        dy   = strmid(date_obs,  8, 2)
        hr   = strmid(date_obs, 11, 2)
        mnt  = strmid(date_obs, 14, 2)
        sec  = strmid(date_obs, 17, 2)

        imgtime[i] = string(hr, mnt, sec, format='(%"%s:%s:%s")')

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
        if (numavg eq 0) then firsttime = date_julian[0]

        if (i eq 0) then begin
          avgimg = imgsave[*, *, 0]
          saveheader = header
          numavg = 1
          if (dailycount lt 48 and date_julian[i] - firsttime lt dailyavgval) then begin
	    dailyavg[0, 0, dailycount] = imgsave[*, *, 0]
            dailytimes[dailycount] = imgtime[0]
            dailycount += 1
          endif
          timestring[0] = imgtime[0]
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
	  saveheader = header   ; save header in case next image is > 3 min. in time
	  numavg += 1
	  if (i le 3) then timestring[0] = timestring[0] + ' ' + imgtime[i]
	  if (i gt 3) then timestring[1] = timestring[1] + ' ' + imgtime[i]
        endif

        if (difftime gt avginterval) then begin
          stopavg = 1  ; set flag to stop averaging
          last = i   
        endif

        if (dailycount lt 48  and  date_julian[i] - firsttime lt dailyavgval) then begin
          dailyavg[0, 0, dailycount] = imgsave[*, *, i]
          dailytimes[dailycount] = imgtime[i]
          dailycount += 1
        endif
      endif

      if (stopavg eq 1) then break
    endfor

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
      doy = (mday_leap[month - 1] + day)
    endif else begin
      doy = (mday[month] - 1) + day
    endelse

    ; set up device, color table and scaling
    set_plot, 'Z'
    device, set_resolution=[1024, 1024], decomposed=0, set_colors=256, z_buffering=0

    display_min   = run->epoch('display_min')
    display_max   = run->epoch('display_max')
    display_exp   = run->epoch('display_exp')
    display_gamma = run->epoch('display_gamma')

    lct, filepath('quallab_ver2.lut', root=run.resources_dir)

    gamma_ct, display_gamma, /current
    tvlct, red, green, blue, /get

    ; create fullres (1024x1024) GIF images
    tv, bytscl(avgimg^display_exp, display_min, display_max)

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
    xyouts, 1018, 955, string(format='(a2)', hr) + ':' $
                         + string(format = '(a2)', mnt) $
                         + ':' + string(format='(a2)', sec) + ' UT', $
            /device, alignment=1.0, charsize=1.2, color=255
    xyouts, 1018, 935, '2 to 3 min avg', /device, alignment=1.0, charsize=1.2, color=255 
   
    xyouts, 22, 512, 'East', color=255, charsize=1.2, alignment=0.5, $
            orientation=90., /device
    xyouts, 1012, 512, 'West', color=255, charsize=1.2, alignment=0.5, $
            orientation=90., /device
    xyouts, 4, 46, 'Level 1 Avg', color=255, charsize=1.2, /device
    xyouts, 4, 26, string(display_min, display_max, $
                          format='("min/max: ", f5.2, ", ", f3.1)'), $
            color=255, charsize=1.2, /device
    xyouts, 4, 6, string(display_exp, $
                         display_gamma, $
                         format='("scaling: Intensity ^ ", f3.1, ", gamma=", f4.2)'), $
            color=255, charsize=1.2, /device
    xyouts, 1018, 6, 'Circle = photosphere', $
            color=255, charsize=1.2, /device, alignment=1.0

    ; image has been shifted to center of array
    ; draw circle at photosphere
    tvcircle, r_photo, 511.5, 511.5, color=255, /device

    device, decomposed=1
    save = tvrd()

    gif_basename = strmid(savename, 0, 23) + '_avg.gif'
    write_gif, gif_basename, save, red, green, blue
    if (run.distribute) then begin
      file_copy, gif_basename, fullres_dir, /overwrite
    endif

    ; create lowres (512 x 512) GIF images

    ; rebin to 768x768 (75% of original size) and crop around center to 512 x
    ; 512 image
    rebin_img = congrid(avgimg, 768, 768)
    crop_img  = rebin_img[128:639, 128:639]

    set_plot, 'Z'
    erase
    device, set_resolution=[512, 512], decomposed=0, set_colors=256, $
            z_buffering=0
    erase

    tv, bytscl(crop_img ^ display_exp, $
               min=display_min, max=display_max)

    xyouts, 4, 495, 'MLSO/HAO/KCOR', color=255, charsize=1.2, /device
    xyouts, 4, 480, 'K-Coronagraph', color=255, charsize=1.2, /device
    xyouts, 256, 500, 'North', color=255, $
            charsize=1.0, alignment=0.5, /device
    xyouts, 500, 495, string(format='(a2)', dy) + ' ' $
                               + string(format='(a3)', name_month)$
                               + ' ' + string(format='(a4)', yr), $
            /device, alignment = 1.0, $
            charsize=1.0, color=255
    xyouts, 500, 480, $
            string(format='(a2)', hr) + ':' $
              + string(format='(a2)', mnt) + ':' $
              + string(format='(a2)', sec) + ' UT', $
            /device, alignment=1.0, $
            charsize=1.0, color=255
    xyouts, 12, 256, 'East', color=255, $
            charsize=1.0, alignment=0.5, orientation=90.0, /device
    xyouts, 507, 256, 'West', color=255, $
            charsize=1.0, alignment=0.5, orientation=90.0, /device

    xyouts, 4, 20, string(display_min, display_max, $
                          format='("min/max: ", f5.2, ", ", f3.1)'), $
            color=255, charsize=1.0, /device

    xyouts, 4, 6, string(display_exp, $
                         display_gamma, $
                         format='("scaling: Intensity ^ ", f3.1, ", gamma=", f4.2)'), $
            color=255, charsize=1.0, /device
    xyouts, 500, 21, '2 minx avg', color=255, charsize=1.0, alignment=1.0, /device
    xyouts, 500, 6, 'Circle = photosphere', color=255, $
            charsize=1.0, /device, alignment=1.0

    r = r_photo * 0.75    ;  image is rebined to 75% of original size
    tvcircle, r, 255.5, 255.5, color=255, /device

    save = tvrd()
    gif_basename = strmid(savename, 0, 23) + '_cropped_avg.gif'
    write_gif, gif_basename, save, red, green, blue
    if (run.distribute) then begin
      file_copy, gif_basename, cropped_dir, /overwrite
    endif

    ; Create fullres (1024x1024) FITS image
    ; Create up to 2 new keywords that record the times of the images used in
    ; the avg. Each keyword holds up 4 image times to accommodate up to 8 images
    ; in the avg.
    fxaddpar, saveheader, 'AVGTIME0', timestring[0], ' Img times used in avg.'
    if (numavg gt 3) then begin
      fxaddpar, saveheader, 'AVGTIME1', timestring[1], ' Img times used in avg.'
    endif
    name = strmid(savename, 0, 23)
    fits_filename = string(format='(a23, "_avg.fts")', name)

    mg_log, 'writing %s', fits_filename, name='kcor/eod', /info
    writefits, fits_filename, avgimg, saveheader
    if (run.distribute) then begin
      file_copy, fits_filename, archive_dir, /overwrite
    endif
  endwhile

  ; make daily average 1024x1024 GIF ; 512x512 gif; and 1024x1024 FITS image
  set_plot, 'Z'
  device, set_resolution=[1024, 1024], decomposed=0, set_colors=256, z_buffering=0
  erase

  daily = fltarr(1024, 1024)
  ; don't use the first 8 images (2 min.) of the day
  for i = 8L, dailycount - 1L do begin
    daily += dailyavg[*, *, i] 
  endfor

  daily /= float(dailycount) - 8.0

  tv, bytscl(daily^display_exp, display_min, display_max)

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
          string(format='(a2)', hr) + ':' $
            + string(format = '(a2)', mnt) $
            + ':' + string(format='(a2)', sec) + ' UT', $
          /device, alignment=1.0, charsize=1.2, color=255
  xyouts, 1018, 935, '10 to 15 min. AVG.', /device, alignment=1.0, charsize=1.2, color=255

  xyouts, 22, 512, 'East', color=255, charsize=1.2, alignment=0.5, $
          orientation=90., /device
  xyouts, 1012, 512, 'West', color=255, charsize=1.2, alignment=0.5, $
          orientation=90., /device
  xyouts, 4, 46, 'Level 1 Avg', color=255, charsize=1.2, /device
  xyouts, 4, 26, string(display_min, display_max, $  
                        format='("min/max: ", f5.2, ", ", f3.1)'), $
          color=255, charsize=1.2, /device
  xyouts, 4, 6, string(display_exp, $     
                       display_gamma, $
                       format='("scaling: Intensity ^ ", f3.1, ", gamma=", f4.2)'), $
          color=255, charsize=1.2, /device
  xyouts, 1018, 6, 'Circle = photosphere.', $
          color=255, charsize=1.2, /device, alignment=1.0

  ; image has been shifted to center of array
  ; draw circle at photosphere
  tvcircle, r_photo, 511.5, 511.5, color=255, /device

  device, decomposed=1
  save = tvrd()

  gif_filename = strmid(savename, 0, 23) + '_dailyavg.gif'
  write_gif, gif_filename, save, red, green, blue  
  if (run.distribute) then begin
    file_copy, gif_filename, fullres_dir, /overwrite
  endif

  ; create lowres  (512 x 512  gif images

  ; rebin to 768x768 (75% of original size) and crop around center to 512 x
  ; 512 image

  rebin_img = congrid(daily, 768, 768)
  crop_img = rebin_img[128:639, 128:639]

  ; window, 0, xsize=512, ysize=512, retain=2

  set_plot, 'Z'
  erase
  device, set_resolution=[512,512], decomposed=0, set_colors=256, $
            z_buffering=0
  erase

  tv, bytscl(crop_img^display_exp, min=display_min, max=display_max)

  xyouts, 4, 495, 'MLSO/HAO/KCOR', color=255, charsize=1.2, /device
  xyouts, 4, 480, 'K-Coronagraph', color=255, charsize=1.2, /device
  xyouts, 256, 500, 'North', color=255, $
            charsize=1.0, alignment=0.5, /device
  xyouts, 500, 495, string(format='(a2)', dy) + ' ' $
                             + string(format='(a3)', name_month)$
                             + ' ' + string(format='(a4)', yr), $
          /device, alignment = 1.0, $
          charsize=1.0, color=255
  xyouts, 500, 480, string(format='(a2)', hr) + ':' $
                      + string(format='(a2)', mnt) + ':' $
                      + string(format='(a2)', sec) + ' UT', $
          /device, alignment=1.0, $
          charsize=1.0, color=255
  xyouts, 12, 256, 'East', color=255, $
          charsize=1.0, alignment=0.5, orientation=90.0, /device
  xyouts, 507, 256, 'West', color=255, $
          charsize=1.0, alignment=0.5, orientation=90.0, /device
  xyouts, 4, 20, string(format='("min/max: ", f5.2, ", ", f5.2)', $
                        display_min, display_max), $
          color=255, charsize=1.0, /device
  xyouts, 4, 6, string(format='("scaling: Intensity ^ ", f3.1, ", gamma=", f4.2)', $
                       display_exp, display_gamma), $
          color=255, charsize=1.0, /device
  xyouts, 500, 21, '10 min. avg.', color=255, charsize=1.0, alignment=1.0, /device
  xyouts, 500, 6, 'Circle = photosphere', color=255, $
          charsize=1.0, /device, alignment=1.0

  r = r_photo * 0.75    ;  image is rebined to 75% of original size
  tvcircle, r, 255.5, 255.5, color=255, /device

  save = tvrd()
  gif_filename = strmid(savename, 0, 23) + '_dailyavg_cropped.gif'
  write_gif, gif_filename, save, red, green, blue   
  if (run.distribute) then begin
    file_copy, gif_filename, cropped_dir, /overwrite
  endif

  ; create fullres (1024x1024) FITS image
  ; save times used to make the daily avg. image in the header 
  ; create 10 fits keywords; each holds 4 image times to accommodate up to 40
  ; images in the avg.

  n_times_per_keyword = 4
  n_skip = 8
  n_daily_times = n_elements(dailytimes[n_skip:*])
  n_keywords = ceil(n_daily_times / float(n_times_per_keyword))

  keyword_times = strarr(n_times_per_keyword, n_keywords)
  keyword_times[0] = dailytimes[n_skip:*]
  keyword_times = strjoin(keyword_times, ' ')

  for k = 0L, n_keywords - 1L do begin
    fxaddpar, saveheader, string(k, format='(%"AVGTIME%d")'), keyword_times[k], $
              ' Image times used in avg.'
  endfor

  name = strmid(savename, 0, 23)
  daily_fits_average_filename = string(format='(a23, "_dailyavg.fts")', name)
  mg_log, 'writing %s', daily_fits_average_filename, name='kcor/eod', /info
  writefits, daily_fits_average_filename, daily, saveheader
  if (run.distribute) then begin
    file_copy, daily_fits_average_filename, archive_dir, /overwrite
  endif

  done:
  cd, current
  mg_log, 'done', name='kcor/eod', /info
end
