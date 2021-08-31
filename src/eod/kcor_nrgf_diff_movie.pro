;  docformat = 'rst'

;+
;  Create animation of side-by-side K-Cor NRGF and K-Cor subtraction images.
;
; Read in NRGF average GIF images and subtraction GIF images.
; K-Cor subtraction images have a nominal 5 minute cadence (if no data gaps).
; K-Cor NRGF average images have a nominal 2 minute cadence (if no data gaps).
; Find NRGF image closest in time to subtraction image.
; If these are 'close' together in time then save these 2 images in a new
; array then save as a new combined gif image`
; HOW CLOSE IN TIME SHOULD IMAGES BE?
; Want images less than `numsec` seconds apart where `numsec` is set as a
; default below.
;
;  History  J. Burkepile  August 2021
;-
pro kcor_nrgf_diff_movie, run=run
  compile_opt strictarr

   ; set image dimensions to 1024 x 512
   combined_image = bytarr(1024, 512)

  ; set default values

  ; [secs] maximum DESIRED time difference between diff and NRGF image (no data
  ; gaps)
  numsec = 80.0D

  ; [secs] maximum REQUIRED (not to exceed) time difference between diff and
  ; NRGF image when gaps present
  maxsec = 300.0D

  secs_per_day = 86400.0D

  ; used to find NRGF images in units of fraction of a day in seconds
  goodtime = numsec / secs_per_day

  ; used to find NRGF if data gaps in fraction of a day in seconds
  maxtime = maxsec / secs_per_day

  ; used to determine if data gap present; initialize to 1 day
  savetime = secs_per_day / secs_per_day

  read_subt = 1B     ; flag to determine if a new diff image should be read in
  ncount = 0L        ; counter for number of good nrgf/subt pairs
  end_of_data = 0B   ; use flag to find last good image matches

  ; read in list of good diff GIFs and 2 min average NRGF GIFs

  diff_gifs = file_search(filepath('*minus*_good.gif', $
                                   subdir=[run.date, 'level2'], $
                                   root=raw->config('processing/raw_basedir')), $
                          count=n_diff_gifs)
  nrgf_average_gifs = file_search(filepath('*l2_nrgf_avg.gif', $
                                   subdir=[run.date, 'level2'], $
                                   root=raw->config('processing/raw_basedir')), $
                          count=n_nrgf_average_gifs)

  if (n_diff_gifs eq 0L) then begin
    mg_log, 'no subtractions available for this day', name=run.logger_name, /warn
    goto, done
  endif

  diff_keep = strarr(n_diff_gifs)
  nrgf_keep = strarr(n_diff_gifs)

  current_diff = 0L
  current_nrgf = 0L

  ; this logic should find the last good subt/nrgf match of the day
  while (end_of_data ne 1) do begin
    ; read in next NRGF image
    nrgf_file = nrgf_average_gifs[current_nrgf++]

    ; read in next difference image
    if (read_subt eq 1) then diff_file = diff_gifs[current_diff++]

    ftspos = strpos(nrgf_file, '_kcor')

    ; determine time of images

    ; extract subtraction time from filename
    diff_year   = fix(strmid(diff_file,  0, 4))
    diff_month  = fix(strmid(diff_file,  4, 2))
    diff_day    = fix(strmid(diff_file,  6, 2))
    diff_hour   = fix(strmid(diff_file,  9, 2))
    diff_minute = fix(strmid(diff_file, 11, 2))
    diff_second = fix(strmid(diff_file, 13, 2))

    ; extract NRGF time from filename
    nrgf_year   = fix(strmid(nrgf_file,  0, 4))
    nrgf_month  = fix(strmid(nrgf_file,  4, 2))
    nrgf_day    = fix(strmid(nrgf_file,  6, 2))
    nrgf_hour   = fix(strmid(nrgf_file,  9, 2))
    nrgf_minute = fix(strmid(nrgf_file, 11, 2))
    nrgf_second = fix(strmid(nrgf_file, 13, 2))

    ; use diff time to find nearest NRGF image 
    ; convert to julian date to make it easier to find difference between times 
    ; want images to be < numsec seconds apart (i.e. < numsec/86400 where
    ;   86400 = number of sec/day)

    diff_time = julday(diff_month, diff_day, diff_year, $
                       diff_hour, diff_minute, diff_second)
    nrgf_time = julday(nrgf_month, nrgf_day, nrgf_year, $
                       nrgf_hour, nrgf_minute, nrgf_second)
    delta_time = double(abs(diff_time - nrgf_time))
 
    ; check to see if NRGF is within 'goodtime' from the difference image

    if (delta_time lt goodtime) then begin
      nrgf_keep[ncount] = nrgf_file
      diff_keep[ncount] = diff_file
      print, 'found a good NRGF file'
      read_subt = 1B
      ; found a good image so reset to start looking for next good image
      savetime = 1.0D
      ncount += 1L
    endif else if (delta_time lt savetime) then begin
      ; time difference decreasing (i.e. closer to subt) but want something
      ; closer

      ; save current img time difference to check for future data gaps
      savetime = delta_time
      ; save current image filename in case of future data gaps
      saveimg = nrgf_file

      read_subt = 0
    endif else if (delta_time ge savetime) and (savetime lt maxtime) then begin    
      ; time difference increasing; probably data gap. Use previous image if
      ; meets less strict criteria
      nrgf_keep[ncount] = saveimg
      diff_keep[ncount] = diff_file
      print, 'found an acceptable NRGF file'
      read_subt = 1B
      savetime = 1.0D
      ncount += 1L
    endif else if (delta_time ge savetime) and (savetime ge maxtime) then begin
      ; no good image found to match subtraction 
      read_subt = 1B   ; need to read in a new subtraction 
      savetime = 1.0D
      print, 'NO acceptable NRGF found '
    endif

    ; when the last diff image is found; continue reading NRGFs to find a match
    if ((current_diff eq n_diff_gifs) and (current_nrgf eq n_nrgf_average_gifs)) then end_of_data = 1B

    ; still have some NRGF images
    if ((current_diff eq n_diff_gifs) and (current_nrgf lt n_nrgf_average_gifs)) then begin
      ; no more NRGFs within time range
      if (read_subt eq 1) then end_of_data = 1B

      ; keep going to find last good NRGF
      if (read_subt eq 0) then end_of_data = 0B
    endif
  endwhile

  mg_log, 'number of difference images: %d', n_diff_gifs, name=run.logger_name, /info

  frame_filenames = strarr(ncount)
  for i = 0L, ncount - 1L  do begin
    read_gif, nrgf_keep[i], nrgfimg
    read_gif, diff_keep[i], subtimg

    ; remove the seconds from the filename
    ftspos   = strpos(diff_keep[i], '_kcor')
    basename = strmid(diff_keep[i], 0, ftspos - 2)

    nrgf_image = rebin(nrgfimg, 512, 512)
    diff_image = rebin(subtimg, 512, 512)

    ; put NRGF image on left and difference on the right side of the window
    combined_image[0:511, *] = nrgf_image
    combined_image[512:1023, *] = diff_image

    ; create GIF name and save image
    frame_filenames[i] = filepath(basename + '_kcor_l2_nrgf_and_diff.gif', $
                                  subdir=[run.date, 'level2'], $
                                  root=raw->config('processing/raw_basedir'))
    write_gif, frame_filenames[i], combined_image
  endfor

  ; create movie filename
  ; note: there are a handful of days when there is only 1 K-Cor diff image,
  ;       if that is the case then add that info to the filename
  basename = string(strmid(diff_keep[0], 0, 8), $
                    n_diff_gifs eq 1L ? 'one_frame_only_' : '', $
                    format='(%"%s_kcor_l2_nrgf_and_diff_%smovie.gif")')
  movie_name = filepath(basename, $
                        subdir=[run.date, 'level2'], $
                        root=raw->config('processing/raw_basedir'))

  kcor_create_mp4, frame_filenames, movie_name, run=run, status=status

  done:
end
