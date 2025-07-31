;  docformat = 'rst'

;+
; Create animation of side-by-side K-Cor nrgf and K-Cor subtraction images.
;
; Read in nrgf enhanced average gif images and subtraction gif images  K-Cor
; difference images have a nominal 30 second cadence as of 2025. if no data
; gaps).
;  K-Cor nrgf average enhanced images have a nominal 2 minute cadence (if no data gaps)
;  Find nrgf image closest in time to subtraction image
;  If these are 'close' together in time then save these 2 images in a new array then save as a new combined gif image`
;  HOW CLOSE IN TIME SHOULD IMAGES BE?
;  Want images less than `maxsec` seconds apart where `maxsec` is set as a default below
;  INPUTS: None
;
;
;  History  J. Burkepile  August 2021
;  History  J. Burkepile  June-July 2025
;            In a separate program I increased the cadence of subtraction images from 5 minutes
;            to 30 sec. These side-by-side images were created at 5 minute cadence. I am changing
;            that to 2 minute cadence which will match the subtraction cadence from 5 minutes to 30 seconds
;            Use 'good' subtraction gifs unless none are available - use 'pass' quality if necessary.
;-
pro kcor_nrgf_diff_movie, run=run
  compile_opt strictarr

  fullres_dir = filepath('', $
                         subdir=kcor_decompose_date(run.date), $
                         root=run->config('results/fullres_basedir'))

  ; set image dimensions to 1024 x 512
  combined_image = bytarr(1024, 512)

  ; set default values

  ; [secs] maximum REQUIRED (not to exceed) time difference between diff and
  ; enhanced 2 min avg NRGF image when gaps present
  maxsec = 100.0D

  ; convert maxsec time to julian date
  maxtime = maxsec / 60.0D / 60.0D / 24.0D    ; max diff in Julian time between subt and nrgf

  read_subt = 1B     ; flag to determine if a new diff image should be read in
  ncount = 0L        ; counter for number of good nrgf/subt pairs
  found_subt = 0     ; use flag to note when diff-nrgf pair is found: 0=No, 1=Yes
  nrgfimg = bytarr(1024, 1024)
  subtimg = bytarr(1024, 1024)

  ; read in list of good diff GIFs and 2 min average NRGF GIFs
  diff_gifs = file_search(filepath('*minus*_{good,pass}.gif', $
                                   subdir=[run.date, 'level2'], $
                                   root=run->config('processing/raw_basedir')), $
                          count=n_diff_gifs)
  nrgf_average_gifs = file_search(filepath('*l2_nrgf_avg_enhanced.gif', $
                                   subdir=[run.date, 'level2'], $
                                   root=run->config('processing/raw_basedir')), $
                          count=n_nrgf_average_gifs)

  if (n_diff_gifs eq 0L) then begin
    mg_log, 'no subtractions available for this day', name=run.logger_name, /warn
    goto, done
  endif

  diff_keep = strarr(n_diff_gifs)
  nrgf_keep = strarr(n_nrgf_average_gifs)
  frame_filenames = strarr(n_nrgf_average_gifs)
  gif_date_obs = strarr(n_nrgf_average_gifs)
  gif_date_end = strarr(n_nrgf_average_gifs)
  gif_carrington_rotation = lonarr(n_nrgf_average_gifs)
  gif_numsum = lonarr(n_nrgf_average_gifs)
  gif_exptime = fltarr(n_nrgf_average_gifs)

  diff_time = dblarr(n_diff_gifs)    ; use to store the julian date of each subtraction image
  delta_time = dblarr(n_diff_gifs)   ; use to store julian time of subtraction minus julian time of nrgf
  qual_diffs = strarr(n_diff_gifs)   ; use to store the quality of each subtraction image

  ;   ADDING LOGIC TO READ IN FILENAMES OF ALL SUBTRACTION IMAGES AND CONVERT TIMES TO Julian Dates
  ;   in order to find the best match to the 2 min avg enhanced nrgf images.

  ; Read in list of names of subt gifimages. Compute julian dates. Save quality
  ; info. Will use these later to find closest time match to the NRGF GIF
  ; images.
  for f = 0L, n_diff_gifs - 1L do begin
    ; read in next difference image
    diff_file = file_basename(diff_gifs[f])

    year    = strmid(diff_file, 0, 4)
    month   = strmid(diff_file, 4, 2)
    day     = strmid(diff_file, 6, 2)
    hour    = strmid(diff_file, 9, 2)
    minute  = strmid(diff_file, 11, 2)
    second  = strmid(diff_file, 13, 2)
    quality = strmid(diff_file, 34, 4)

    qual_diffs[f] = quality

    ;  set up integer values to identify date for path
    yr  = fix(year)
    mon = fix(month)
    dy  = fix(day)
    hr  = fix(hour)
    mn  = fix(minute)
    sec = fix(second)

    ; compute julian date in order to match dark with appropriate flat
    diff_time[f] = julday(mon, dy, yr, hr, mn, sec)
  endfor

  ; this logic reads in the NRGF and finds the closest in time good quality subtraction. 
  ; If no good quality subtractions are available it finds the closest 'pass' quality subt. 
  for current_nrgf = 0L, n_nrgf_average_gifs - 1L do begin
    ; read in next NRGF image
    nrgf_file = nrgf_average_gifs[current_nrgf]
    ftspos = strpos(nrgf_file, '_kcor')

    ; determine time of image

    ; extract NRGF time from filename
    nrgf_basename = file_basename(nrgf_file)
    nrgf_year     = fix(strmid(nrgf_basename,  0, 4))
    nrgf_month    = fix(strmid(nrgf_basename,  4, 2))
    nrgf_day      = fix(strmid(nrgf_basename,  6, 2))
    nrgf_hour     = fix(strmid(nrgf_basename,  9, 2))
    nrgf_minute   = fix(strmid(nrgf_basename, 11, 2))
    nrgf_second   = fix(strmid(nrgf_basename, 13, 2))

    ; convert to julian date 
    nrgf_time = julday(nrgf_month, nrgf_day, nrgf_year, $
                       nrgf_hour, nrgf_minute, nrgf_second)

    ; find difference between NRGF and all difference images
    delta_time = double(abs(diff_time - nrgf_time))   
    okaytimes = where(delta_time lt maxtime, okcount) ; index of images that meet time difference criteria

    if (okcount eq 0) then begin
      mg_log, 'no acceptable diff found for NRGF %s', nrgf_basename, $
              name=run.logger_name, /debug
    endif
 
    if (okcount eq 1) then begin
      ; there was 1 image that met the time difference criteria
       best_diff_gif_filename = diff_gifs[okaytimes]
       found_subt = 1   ; found an image
    endif

    if (okcount gt 1) then begin
      ; we have at least two diff images close to NRGF time
      goodqual = where(qual_diffs[okaytimes] eq 'good', qcount)
      if (qcount gt 0) then begin   ; have at least one good quality image
        ; pick closest time
        !null = min(delta_time[okaytimes[goodqual]], bestindex)
        best_diff_gif_filename = diff_gifs[okaytimes[goodqual[bestindex]]]
        found_subt = 1   ; found best image
      endif
      if (qcount eq 0) then begin   ; only have 'pass' quality images
        !null = min(delta_time[okaytimes], bestindex)   ; pick closest time
        best_diff_gif_filename = diff_gifs[okaytimes[bestindex]]
        found_subt = 1   ; found best image
      endif
    endif

    if (found_subt eq 1) then begin   ; found matching images
      mg_log, 'found a matching diff file', name=run.logger_name, /debug
      nrgf_keep[ncount] = nrgf_file
      diff_keep[ncount] = best_diff_gif_filename

      read_gif, nrgf_file, nrgfimg
      read_gif, best_diff_gif_filename, subtimg
      nrgf_image = rebin(nrgfimg, 512, 512)
      diff_image = rebin(subtimg, 512, 512)

      ; put NRGF image on left and subtraction on the right side of the window
      combined_image[0:511, *] = nrgf_image
      combined_image[512:1023, *] = diff_image

      ; create GIF name and save image
      ftspos   = strpos(diff_keep[ncount], '_kcor')
      basename = strmid(diff_keep[ncount], 0, ftspos)
      frame_filenames[ncount] = basename + '_kcor_l2_nrgf_and_diff.gif'
      mg_log, 'writing %s...', file_basename(frame_filenames[ncount]), $
              name=run.logger_name, /info
      write_gif, frame_filenames[ncount], combined_image
      if (run->config('realtime/distribute')) then begin
        file_copy, frame_filenames[ncount], fullres_dir, /overwrite
      endif

      mg_log, 'NRGF: %s', file_basename(nrgf_keep[ncount]), $
              name=run.logger_name, /debug
      mg_log, 'diff: %s', file_basename(diff_keep[ncount]), $
              name=run.logger_name, /debug

      ; find metadata for frames
      nrgf_fits_filename = strmid(nrgf_keep[ncount], 0, strlen(nrgf_keep[ncount]) - 4L) + '.fts.gz'
      diff_fits_filename = strmid(diff_keep[ncount], 0, strlen(diff_keep[ncount]) - 4L) + '.fts.gz'

      nrgf_primary_header = headfits(nrgf_fits_filename, exten=0)
      diff_primary_header = headfits(diff_fits_filename, exten=0)
      gif_date_obs[ncount] = min([sxpar(nrgf_primary_header, 'DATE-OBS'), $
                                  sxpar(diff_primary_header, 'DATE-OBS')])
      gif_date_end[ncount] = min([sxpar(nrgf_primary_header, 'DATE-END'), $
                                  sxpar(diff_primary_header, 'DATE-END')])

      date_obs_anytim = utc2str(tai2utc(utc2tai(str2utc(gif_date_obs[ncount]))), /stime)
      gif_carrington_rotation[ncount] = long((tim2carr(date_obs_anytim, /dc))[0])
      gif_numsum[ncount] = sxpar(nrgf_primary_header, 'NUMSUM')
      gif_exptime[ncount] = sxpar(nrgf_primary_header, 'EXPTIME')

      ; reset all counters, best and okay image info before reading in next image
      best_diff_gif_filename = ''
      closest = -1
      delta_time[*] = 1.0D
      found_subt = 0
      goodqual = -1
      qcount = 0
      okcount = 0
      okaytimes = lonarr(12)   ; reset. Should never be 12 images < 100 sec from nrgf

      ncount += 1L
    endif
  endfor

  mg_log, 'number of difference images: %d', n_diff_gifs, $
          name=run.logger_name, /info
  mg_log, 'number of NRGF average images: %d', n_nrgf_average_gifs, $
          name=run.logger_name, /info
  if (ncount eq 0L) then begin
    mg_log, 'no good or acceptable NRGF+diff matches', $
            name=run.logger_name, /info
    goto, done
  endif else begin
    mg_log, 'number of NRGF+diff images: %d', ncount, $
            name=run.logger_name, /info
  endelse

  ; create movie filename
  if (ncount gt 1L) then begin
    frame_filenames = frame_filenames[0:ncount - 1]

    mp4_date_obs = min(gif_date_obs)
    mp4_date_end = max(gif_date_end)

    nrfgdiff_mp4_basename = string(strmid(file_basename(diff_keep[0]), 0, 8), $
                                   format='(%"%s_kcor_l2_nrgf_and_diff.mp4")')
    mg_log, 'writing %s...', nrfgdiff_mp4_basename, name=run.logger_name, /info
    nrfgdiff_mp4_filename = filepath(nrfgdiff_mp4_basename, $
                                     subdir=[run.date, 'level2'], $
                                     root=run->config('processing/raw_basedir'))

    kcor_create_mp4, frame_filenames, nrfgdiff_mp4_filename, $
                     run=run, status=status
    if (status eq 0L && run->config('realtime/distribute')) then begin
      file_copy, nrfgdiff_mp4_filename, fullres_dir, /overwrite
    endif
  endif

  ; create database entries for new NRGF+diff images
  if (run->config('database/update')) then begin
    mg_log, 'adding %d NRGF+diff GIFs to database', ncount, name=run.logger_name, /info
    obsday_index = mlso_obsday_insert(run.date, $
                                      run=run, $
                                      database=db, $
                                      status=db_status, $
                                      log_name=run.logger_name)
    kcor_db_nrgfdiff_insert, file_basename(frame_filenames), $
                             gif_date_obs, gif_date_end, $
                             gif_carrington_rotation, gif_numsum, gif_exptime, $
                             nrfgdiff_mp4_basename, $
                             mp4_date_obs, mp4_date_end, $
                             gif_carrington_rotation[0], gif_numsum[0], gif_exptime[0], $
                             database=db, run=run, obsday_index=obsday_index
  endif else begin
    mg_log, 'skipping updating database', name=run.logger_name, /info
  endelse

  done:
  if (obj_valid(db)) then obj_destroy, db
end


; main-level example program

date = '20240409'
config_basename = 'kcor.latest.cfg'
config_filename = filepath(config_basename, $
                           subdir=['..', '..', '..', 'kcor-config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)
kcor_nrgf_diff_movie, run=run
obj_destroy, run

end
