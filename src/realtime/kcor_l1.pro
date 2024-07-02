; docformat = 'rst'

;+
; Produce the L1 FITS and GIF files.
;
; :Params:
;   ok_file : in, out, optional, type=strarr
;     level 0 filename to process
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;   mean_phase1 : out, optional, type=fltarr
;     mean_phase1 for `ok_file`
;   error : out, optional, type=long
;     set to a named variable to retrieve the error status of the call
;-
pro kcor_l1, ok_filename, $
             l1_filename=l1_filename, $
             l1_header=l1_header, $
             intensity=intensity, $
             q=qmk4, $
             u=umk4, $
             flat_vdimref=flat_vdimref, $
             run=run, $
             nomask=nomask, $
             mean_phase1=mean_phase1, $
             log_name=log_name, $
             error=error
  compile_opt strictarr
  on_error, 2

  mean_phase1 = 0.0   ; TODO: this is not set?
  error = 0L

  ; setup directories
  dirs  = filepath('level' + ['0', '1'], $
                   subdir=run.date, $
                   root=run->config('processing/raw_basedir'))
  l0_dir = dirs[0]
  l1_dir = dirs[1]

  if (~file_test(l1_dir, /directory)) then file_mkdir, l1_dir

  mg_log, 'L1 processing %s', $
          file_basename(ok_filename), $
          name=log_name, /info

  ; set image dimensions
  xsize = run->epoch('xsize')
  ysize = run->epoch('ysize')

  ; set guess for radius - needed to find center
  radius_guess = 178   ; average radius for occulter

  ; initialize variables
  cal_data_new = dblarr(xsize, ysize, 2, 3)
  gain_shift   = dblarr(xsize, ysize, 2)

  clock = tic('l1_loop')

  if (~file_test(ok_filename, /regular)) then begin
    message, string(file_basename(ok_filename), format='(%"%s not found")')
  endif

  dt = strmid(file_basename(ok_filename), 0, 15)
  run.time = string(strmid(dt, 0, 4), $
                    strmid(dt, 4, 2), $
                    strmid(dt, 6, 2), $
                    strmid(dt, 9, 2), $
                    strmid(dt, 11, 2), $
                    strmid(dt, 13, 2), $
                    format='(%"%s-%s-%sT%s-%s-%s")')
  start_state = run->epoch('start_state')
  mg_log, 'start_state: [%d, %d]', start_state, name=log_name, /debug

  use_double = run->config('realtime/use_double')
  kcor_read_rawdata, ok_filename, image=img, header=header, $
                     repair_routine=run->epoch('repair_routine'), $
                     xshift=run->epoch('xshift_camera'), $
                     start_state=start_state, $
                     raw_data_prefix=run->epoch('raw_data_prefix'), $
                     datatype=run->epoch('raw_datatype'), $
                     double=use_double

  type = fxpar(header, 'DATATYPE')
  mg_log, 'type: %s', strmid(type, 0, 3), name=log_name, /debug

  ; read date of observation
  date_obs = sxpar(header, 'DATE-OBS')   ; yyyy-mm-ddThh:mm:ss
  date_struct = kcor_parse_dateobs(date_obs, hst_date=hst_date_struct)
  run.time = date_obs

  ; extract information from calibration file
  cal_file = run->epoch('cal_file', error_code=cal_file_error)
  switch cal_file_error of
    0: break
    1: mg_log, 'no cal files of correct cal epoch', name=log_name, /error
    2: mg_log, 'unable to find cal file', name=log_name, /error
    else: begin
        error = 1L
        goto, done
      end
  endswitch

  calpath = filepath(cal_file, root=run->config('calibration/out_dir'))
  if (file_test(calpath)) then begin
    mg_log, 'cal file: %s', file_basename(calpath), name=log_name, /debug
  endif else begin
    mg_log, 'cal file does not exist', name=log_name, /error
    mg_log, 'cal file: %s', file_basename(calpath), name=log_name, /error
    error = 1L
    goto, done
  endelse

  unit = ncdf_open(calpath)
  if (unit lt 0L) then begin
    mg_log, 'unable to open cal file %s', file_basename(calpath), $
            name=log_name, /error
    error = 1L
    goto, done
  endif

  ncdf_varget, unit, 'Dark', dark_alfred
  ncdf_varget, unit, 'Gain', gain_alfred  ; gain_alfred is a dark corrected gain
  gain_alfred /= 1.0e-6   ; this makes gain_alfred in units of B/Bsun
  ncdf_varget, unit, 'Modulation Matrix', mmat
  ncdf_varget, unit, 'Demodulation Matrix', dmat
  ncdf_varget, unit, 'DIM Reference Voltage', flat_vdimref

  cal_epoch_version = kcor_nc_getattribute(unit, 'epoch_version', default='-1')

  if (kcor_nc_varid(unit, 'lyotstop') eq -1L) then begin
    cal_lyotstop = 'undefined'
  endif else begin
    ncdf_varget, unit, 'lyotstop', cal_lyotstop
  endelse

  if (kcor_nc_varid(unit, 'numsum') eq -1L) then begin
    ; default for old cal files without a numsum variable is 512
    cal_numsum = 512L
  endif else begin
    ncdf_varget, unit, 'numsum', cal_numsum
  endelse

  if (kcor_nc_varid(unit, 'exptime') eq -1L) then begin
    tokens = strsplit(file_basename(cal_file, '.ncdf'), '_', /extract)
    cal_exptime = float(strmid(tokens[-1], 0, strlen(tokens[-1]) - 2))
  endif else begin
    ncdf_varget, unit, 'exptime', cal_exptime
  endelse

  ncdf_close, unit

  ; modify gain images
  ;   - set zero and negative values in gain to value stored in 'gain_negative'

  ; GdT: changed gain correction and moved it up (not inside the loop)
  ; this will change when we read the daily gain instead of a fixed one
  gain_negative = -10
  gain_alfred[where(gain_alfred le 0, /null)] = gain_negative

  ; replace zero and negative values with mean of 5x5 neighbour pixels
  for b = 0, 1 do begin
    gain_temp = double(reform(gain_alfred[*, *, b]))
    filter = mean_filter(gain_temp, 5, 5, invalid=gain_negative, missing=1)
    bad = where(gain_temp eq gain_negative, nbad)

    if (nbad gt 0) then begin
      gain_temp[bad] = filter[bad]
      gain_alfred[*, *, b] = gain_temp
    endif
  endfor
  gain_temp = 0

  ; find center and radius for gain images
  info_gain0 = kcor_find_image(gain_alfred[*, *, 0], radius_guess, log_name=log_name)
  mg_log, /check_math, name=log_name, /debug
  info_gain1 = kcor_find_image(gain_alfred[*, *, 1], radius_guess, log_name=log_name)
  mg_log, /check_math, name=log_name, /debug

  ; define coordinate arrays for gain images
  gxx0 = findgen(xsize, ysize) mod xsize - info_gain0[0]
  gyy0 = transpose(findgen(ysize, xsize) mod ysize) - info_gain0[1]

  gxx0 = double(gxx0)
  gyy0 = double(gyy0)
  grr0 = sqrt(gxx0 ^ 2.0 + gyy0 ^ 2.0)

  gxx1 = dindgen(xsize, ysize) mod xsize - info_gain1[0]
  gyy1 = transpose(dindgen(ysize, xsize) mod ysize) - info_gain1[1]
  grr1 = sqrt(gxx1 ^ 2.0 + gyy1 ^ 2.0)

  mg_log, 'gain 0 center: %0.1f, %0.1f and radius: %0.1f', $
          info_gain0, name=log_name, /debug
  mg_log, 'gain 1 center: %0.1f, %0.1f and radius: %0.1f', $
          info_gain1, name=log_name, /debug

  ; get current date & time
  current_time = systime(/utc)
  date_dp = string(bin_date(current_time), $
                   format='(%"%04d-%02d-%02dT%02d:%02d:%02d")')

  if (cal_epoch_version ne run->epoch('cal_epoch_version')) then begin
    mg_log, 'cal file epoch_version (%s) does not match for time of file %s (%s)', $
            cal_epoch_version, file_basename(ok_filename), run->epoch('cal_epoch_version'), $
            name=log_name, /error
    mg_log, 'skipping file %s', file_basename(ok_filename), name=log_name, /error
    error = 1L
    goto, done
  endif

  date_hst = kcor_construct_dateobs(hst_date_struct)
  mg_log, 'obs UT: %s, HST: %s', date_obs, date_hst, name=log_name, /debug

  ; put the Level-0 FITS header into a structure
  struct = fitshead2struct(header, dash2underscore=dash2underscore)

  if (n_elements(cal_exptime) eq 0L) then begin
    mg_log, 'calibration exptime not defined', name=log_name, /error
    mg_log, 'skipping file %s', file_basename(ok_filename), name=log_name, /error
    error = 1L
    goto, done
  endif else begin
    if (abs(cal_exptime - struct.exptime) gt 1e-3) then begin
      mg_log, 'cal file EXPTIME (%0.2f ms) does not match file (%0.2f ms) for %s', $
              cal_exptime, struct.exptime, file_basename(ok_filename), $
              name=log_name, /error
      mg_log, 'skipping file %s', file_basename(ok_filename), name=log_name, /error
      error = 1L
      goto, done
    endif
  endelse

  file_lyotstop = kcor_lyotstop(header, run=run)
  if (cal_lyotstop ne file_lyotstop) then begin
    mg_log, 'cal file LYOTSTOP (%s) does not match file (%s) for %s', $
            cal_lyotstop, file_lyotstop, file_basename(ok_filename), $
            name=log_name, /error
    mg_log, 'skipping file %s', file_basename(ok_filename), name=log_name, /error
    error = 1L
    goto, done
  endif

  ; all files that have passed KCOR_QUALITY are science type even though
  ; they may have been engineering in the L0
  struct.datatype = 'science'

  ; ephemeris data
  sun, date_struct.year, date_struct.month, date_struct.day, date_struct.ehour, $
       sd=radsun, dist=dist_au, pa=pangle, lat0=bangle, $
       true_ra=sol_ra, true_dec=sol_dec, $
       carrington=sun_carrington_rotnum, long0=sun_carrington_long

  sol_ra = sol_ra * 15.0   ; convert from hours to degrees

  tim2carr_carrington_rotnum = (tim2carr(date_obs, /dc))[0]
  tim2carr_carrington_long   = (tim2carr(date_obs))[0]
  mg_log, 'carrington rot SUN: %0.3f, TIM2CARR: %0.3f', $
          sun_carrington_rotnum, tim2carr_carrington_rotnum, $
          name=log_name, /debug
  mg_log, 'carrington long SUN: %0.3f, TIM2CARR: %0.3f', $
          sun_carrington_long, tim2carr_carrington_long, $
          name=log_name, /debug

  if (run->epoch('use_occulter_id')) then begin
    occltrid = struct.occltrid
  endif else begin
    occltrid = run->epoch('occulter_id')
  endelse
  occulter = kcor_get_occulter_size(occltrid, run=run)  ; arcsec
  radius_guess = occulter / run->epoch('plate_scale')   ; pixels

  ; TODO: do this?
  img = float(img)

  if (run->epoch('remove_horizontal_artifact')) then begin
    difference_threshold = run->epoch('badlines_diff_threshold')
    kcor_find_badlines, img, $
                        cam0_badlines=cam0_badlines, $
                        cam1_badlines=cam1_badlines, $
                        difference_threshold=difference_threshold
  endif

  ; correct camera nonlinearity
  kcor_correct_camera, img, header, run=run, logger_name=log_name, $
                       rcam_cor_filename=rcam_cor_filename, $
                       tcam_cor_filename=tcam_cor_filename

  if (run->config('realtime/diagnostics')) then begin
    save, img, header, filename=strmid(file_basename(ok_filename), 0, 20) + '_cam.sav'
  endif

  if (run->epoch('remove_horizontal_artifact')) then begin
    if (n_elements(cam0_badlines) gt 0L) then begin
      mg_log, 'correcting cam 0 bad lines: %s', $
              strjoin(strtrim(cam0_badlines, 2), ', '), $
              name=log_name, /debug
    endif
    if (n_elements(cam1_badlines) gt 0L) then begin
      mg_log, 'correcting cam 1 bad lines: %s', $
              strjoin(strtrim(cam1_badlines, 2), ', '), $
              name=log_name, /debug
    endif

    kcor_correct_horizontal_artifact, img, $
                                      cam0_badlines, $
                                      cam1_badlines
  endif

  if (run->epoch('remove_vertical_artifact')) then begin
    mg_log, 'correcting bad columns', $
             name=log_name, /debug
    kcor_correct_vertical_artifact, img
  endif

  ; find image centers & radii of raw images

  ; camera 0 (reflected)
  info_raw = kcor_find_image(img[*, *, 0, 0], $
                             radius_guess, $
                             /center_guess, $
                             max_center_difference=run->epoch('max_center_difference'), $
                             log_name=log_name)

  xcen0    = info_raw[0]
  ycen0    = info_raw[1]
  radius_0 = info_raw[2]

  xx0 = dindgen(xsize, ysize) mod xsize - xcen0
  yy0 = transpose(dindgen(ysize, xsize) mod ysize) - ycen0
  rr0 = sqrt(xx0 ^ 2.0 + yy0 ^ 2.0)

  theta0 = atan(- yy0, - xx0)
  theta0 += !pi

  ; inside and outside radius for masks
  r_in  = fix(occulter / run->epoch('plate_scale')) + run->epoch('r_in_offset')
  r_out = run->epoch('r_out')

  cam0_indices = where(rr0 gt r_in and rr0 lt r_out, n_cam0_fov_pixels)
  mask_occulter0 = bytarr(xsize, ysize)
  mask_occulter0[cam0_indices] = 1B

  ; camera 1 (transmitted)
  info_raw = kcor_find_image(img[*, *, 0, 1], $
                             radius_guess, $
                             /center_guess, $
                             max_center_difference=run->epoch('max_center_difference'), $
                             log_name=log_name)

  xcen1    = info_raw[0]
  ycen1    = info_raw[1]
  radius_1 = info_raw[2]

  xx1 = dindgen(xsize, ysize) mod xsize - xcen1
  yy1 = transpose(dindgen(ysize, xsize) mod ysize) - ycen1
  rr1 = sqrt(xx1 ^ 2.0 + yy1 ^ 2.0)

  theta1 = atan(- yy1, - xx1)
  theta1 += !pi

  cam1_indices = where(rr1 gt r_in and rr1 lt r_out, n_cam1_fov_pixels)
  mask_occulter1 = bytarr(xsize, ysize)
  mask_occulter1[cam1_indices] = 1B

  mg_log, 'camera 0 center: %0.1f, %0.1f and radius: %0.1f', $
          xcen0, ycen0, radius_0, name=log_name, /debug
  mg_log, 'camera 1 center: %0.1f, %0.1f and radius: %0.1f', $
          xcen1, ycen1, radius_1, name=log_name, /debug

  if (xcen0 lt 512 - 100 || xcen0 gt 512 + 100) then begin
    mg_log, 'camera 0 x-coordinate center out of bounds', name=log_name, /warn
  endif
  if (ycen0 lt 512 - 100 || ycen0 gt 512 + 100) then begin
    mg_log, 'camera 0 y-coordinate center out of bounds', name=log_name, /warn
  endif
  if (xcen1 lt 512 - 100 || xcen1 gt 512 + 100) then begin
    mg_log, 'camera 1 x-coordinate center out of bounds', name=log_name, /warn
  endif
  if (ycen1 lt 512 - 100 || ycen1 gt 512 + 100) then begin
    mg_log, 'camera 1 y-coordinate center out of bounds', name=log_name, /warn
  endif

  ; create new gain to account for science image shift from flat because the
  ; occulter in the flat will not align with the science image causing
  ; extremely bright pixels in the corrected science image around the occulter
  ;
  ; - region of missing data is replace with shifted flat data for now.
  ; - it should be replaced with the values from the gain we took without
  ;   occulter in.

  ; camera 0
  replace = where(rr0 gt radius_0 - 4.0 and grr0 le info_gain0[2] + 4.0, nrep)
  if (nrep gt 0) then begin
    gain_temp = gain_alfred[*, *, 0]
    gain_replace = shift(gain_alfred[*, *, 0], $
                         xcen0 - info_gain0[0], $
                         ycen0 - info_gain0[1])
    gain_temp[replace] = gain_replace[replace]
    gain_shift[*, *, 0] = gain_temp
  endif

  ; camera 1
  replace = where(rr1 gt radius_1 - 4.0 and grr1 le info_gain1[2] + 4.0, nrep)
  if (nrep gt 0) then begin
    gain_temp = gain_alfred[*, *, 1]
    gain_replace = shift(gain_alfred[*, *, 1], $
                         xcen1 - info_gain1[0], $
                         ycen1 - info_gain1[1])
    gain_temp[replace] = gain_replace[replace]
    gain_shift[*, *, 1] = gain_temp
  endif

  gain_temp    = 0
  gain_replace = 0
  img_cor      = img

  ; need to correct image before we correct with dark
  img_cor *= float(cal_numsum) / float(struct.numsum)

  ; fill inside occulter with mean/median of annulus (over/under occult by 3)
  gain_fill = gain_shift

  n_bad_columns = 8.0   ; number of columns to not trust

  annulus0_indices = where(rr0 gt (info_gain0[2] + 3) and rr0 lt 512.0 - n_bad_columns, $
                           n_annulus0)
  gain_tmp = gain_fill[*, *, 0]
  fill_value0 = mean(gain_tmp[annulus0_indices])

  annulus1_indices = where(rr1 gt (info_gain1[2] + 3) and rr1 lt 512.0 - n_bad_columns, $
                           n_annulus1)
  gain_tmp = gain_fill[*, *, 1]
  fill_value1 = mean(gain_tmp[annulus1_indices])

  mg_log, 'filling gain under occulter with cam 0: %0.2f', $
          fill_value0 / 1.0e6, $
          name=log_name, /debug
  mg_log, 'filling gain under occulter with cam 1: %0.2f', $
          fill_value1 / 1.0e6, $
          name=log_name, /debug

  ; replace under occulter (over occult by 1) of gain with mean/median
  occulter0_indices = where(rr0 lt info_gain0[2] + 1, n_occulter0)
  gain_tmp = gain_fill[*, *, 0]
  gain_tmp[occulter0_indices] = fill_value0
  gain_fill[*, *, 0] = gain_tmp

  occulter1_indices = where(rr1 lt info_gain1[2] + 1, n_occulter1)
  gain_tmp = gain_fill[*, *, 1]
  gain_tmp[occulter1_indices] = fill_value1
  gain_fill[*, *, 1] = gain_tmp

  ; apply dark and gain correction
  for b = 0, 1 do begin
    for s = 0, 3 do begin
      img_cor[*, *, s, b] = img[*, *, s, b] - dark_alfred[*, *, b]

      img_temp = reform(img_cor[*, *, s, b])
      negative_indices = where(img_temp le 0, /null, n_negative_values)

      if (n_negative_values gt 0L) then begin
        ; TODO: should we be doing this?
        ;img_temp[negative_indices] = 0

        case b of
          0: n_fov_negative_values_indices = where(mask_occulter0[negative_indices], $
                                                   n_fov_negative_values)
          1: n_fov_negative_values_indices = where(mask_occulter1[negative_indices], $
                                                   n_fov_negative_values)
        endcase

        if (n_fov_negative_values gt 0L) then begin
          n_fov_negative_values_cutoff = 3
          print_indices = n_fov_negative_values gt n_fov_negative_values_cutoff $
                            ? '' $
                            : ('@ ' $
                               + strjoin(strtrim(n_fov_negative_values_indices, $
                                                 2), $
                                         ' '))
          mg_log, '%d negative values in FOV (cam %d, stokes %d) %s %s', $
                  n_fov_negative_values, b, s, $
                  n_fov_negative_values gt n_fov_negative_values_cutoff $
                  ? '' $
                  : print_indices, $
                  name=log_name, /debug
        endif
      endif

      img_cor[*, *, s, b] = temporary(img_temp) / gain_fill[*, *, b]
    endfor
  endfor

  ; apply demodulation matrix to get I, Q, U images from each camera

  ; method 27 Feb 2015

  ; for y = 0, ysize - 1 do begin
  ;    for x = 0, xsize - 1 do begin
  ;       if (mask_occulter0[x, y] eq 1) then $
  ;       cal_data[x, y, 0, *] = reform(dmat[x, y, 0, *, *]) $
  ;                                ## reform(img_cor[x, y, *, 0])
  ;       if (mask_occulter1[x, y] eq 1) then $
  ;         cal_data[x, y, 1, *] = reform(dmat[x, y, 1, *, *]) $
  ;                                  ## reform(img_cor[x, y, *, 1])
  ;    endfor
  ; endfor

  ; new method using M. Galloy C-language code (04 Mar 2015)
  dclock = tic('demod_matrix')

  a = transpose(dmat, [3, 4, 0, 1, 2])
  b = transpose(img_cor, [2, 0, 1, 3])

  result = kcor_batched_matrix_vector_multiply(a, b, 4, 3, xsize * ysize * 2)
  cal_data = reform(transpose(result), xsize, ysize, 2, 3)

  demod_time = toc(dclock)

  mg_log, 'elapsed time for demod_matrix: %0.1f sec', demod_time, $
          name=log_name, /debug

  ; save intermediate result if realtime/save_intermediate
  if (run->config('realtime/save_intermediate')) then begin
    writefits, filepath(string(strmid(file_basename(ok_filename), 0, 20), $
                               format='(%"%s_demod.fts")'), root=l1_dir), $
               cal_data, header
  endif

  ; apply distortion correction for raw images
  img0 = reform(img[*, *, 0, 0])    ; camera 0 [reflected]
  img0 = reverse(img0, 2)           ; y-axis inversion
  img1 = reform(img[*, *, 0, 1])    ; camera 1 [transmitted]

  ; epoch values like distortion correction filename can change during the day
  dc_path = filepath(run->epoch('distortion_correction_filename'), $
                     root=run.resources_dir)
  restore, dc_path   ; distortion correction file

  dat1 = img0
  dat2 = img1
  kcor_apply_dist, dat1, dat2, dx1_c, dy1_c, dx2_c, dy2_c
  cimg0 = dat1
  cimg1 = dat2

  center_offset = run->config('realtime/center_offset')

  ; find image centers of distortion-corrected, non-demodulated  images

  ; camera 0
  info_dc0 = kcor_find_image(cimg0, radius_guess, $
                             /center_guess, $
                             max_center_difference=run->epoch('max_center_difference'), $
                             log_name=log_name, $
                             xoffset=center_offset[0], yoffset=center_offset[1], $
                             offset_xyr=sun_xyr0)

  sun_xx0 = dindgen(xsize, ysize) mod xsize - sun_xyr0[0]
  sun_yy0 = transpose(dindgen(ysize, xsize) mod ysize) - sun_xyr0[1]

  ; camera 1
  info_dc1 = kcor_find_image(cimg1, radius_guess, $
                             /center_guess, $
                             max_center_difference=run->epoch('max_center_difference'), $
                             log_name=log_name, $
                             xoffset=center_offset[0], yoffset=center_offset[1], $
                             offset_xyr=sun_xyr1)

  sun_xx1 = dindgen(xsize, ysize) mod xsize - sun_xyr1[0]
  sun_yy1 = transpose(dindgen(ysize, xsize) mod ysize) - sun_xyr1[1]

  xx1 = dindgen(xsize, ysize) mod xsize - info_dc1[0]
  yy1 = transpose(dindgen(ysize, xsize) mod ysize) - info_dc1[1]
  rad1 = sqrt(xx1 ^ 2.0 + yy1 ^ 2.0)

  theta1 = atan(- sun_yy1, - sun_xx1)
  theta1 += !pi
  theta1 = reverse(theta1)

  ; combine I, Q, U images from camera 0 and camera 1

  radius = (sun_xyr0[2] + sun_xyr1[2]) * 0.5

  ; offsets to shift camera 0 to camera 1
  deltax = sun_xyr1[0] - sun_xyr0[0]
  deltay = sun_xyr1[1] - sun_xyr0[1]

  ; invert calibrated data for camera 0 in Y-axis
  for s = 0, 2 do begin
    cal_data[*, *, 0, s] = reverse(cal_data[*, *, 0, s], 2, /overwrite)
  endfor

  ; apply distortion correction to calibrated data
  restore, dc_path   ; distortion correction file

  for s = 0, 2 do begin
    dat1 = cal_data[*, *, 0, s]
    dat2 = cal_data[*, *, 1, s]
    kcor_apply_dist, dat1, dat2, dx1_c, dy1_c, dx2_c, dy2_c
    cal_data[*, *, 0, s] = dat1
    cal_data[*, *, 1, s] = dat2
  endfor

  ; save intermediate result if realtime/save_intermediate
  if (run->config('realtime/save_intermediate')) then begin
    writefits, filepath(string(strmid(file_basename(ok_filename), 0, 20), $
                               format='(%"%s_distcor.fts")'), root=l1_dir), $
               cal_data, header
  endif

  ; use config value if specified, otherwise use epoch value
  cameras = run->config('realtime/cameras')
  if (n_elements(cameras) eq 0L) then begin
    cameras = run->epoch('cameras')
  endif

  xx1    = dindgen(xsize, ysize) mod xsize - 511.5
  yy1    = transpose(dindgen(ysize, xsize) mod ysize) - 511.5
  rad1   = sqrt((xx1 + center_offset[0])^ 2.0 + (yy1 + center_offset[1]) ^ 2.0)

  theta1 = atan(- yy1, - xx1)
  theta1 += !pi
  theta1 = reverse(theta1)

  ; multiply by ad hoc non-linearity correction factor
  cal_data *= run->epoch('nonlinearity-correction-factor')

  if (keyword_set(nomask)) then begin
    ; create occulter annotated nomask L1 GIFs by camera
    cal_data_temp = dblarr(xsize, ysize, 2, 3)
    u_l1 = dblarr(xsize, ysize, 2)

    for s = 0, 2 do begin
      cal_data_temp[*, *, 0, s] = kcor_fshift(reverse(cal_data[*, *, 0, s], 1), $
                                              511.5 - (xsize - 1 - sun_xyr0[0]), $
                                              511.5 - sun_xyr0[1], $
                                              interp=1)
      cal_data_temp[*, *, 1, s] = kcor_fshift(reverse(cal_data[*, *, 1, s], 1), $
                                              511.5 - (xsize - 1 - sun_xyr1[0]), $
                                              511.5 - sun_xyr1[1], $
                                              interp=1)
    endfor

    for c = 0L, 1L do begin
      u_l1[*, *, c] = cal_data_temp[*, *, c, 1] * cos(2.0 * theta1) $
                        + cal_data_temp[*, *, c, 2] * sin(2.0 * theta1)
      u_l1[*, *, c] = rot(u_l1[*, *, c], $
                          pangle + run->epoch('rotation_correction'), 1, /interp)
      kcor_create_gif, ok_filename, u_l1[*, *, c], date_obs, $
                       level=1, $
                       occulter_radius=([sun_xyr0[2], sun_xyr1[2]])[c], $
                       camera=c, $
                       /nomask, $
                       run=run, log_name=log_name

      if (run->config('realtime/save_intermediate')) then begin
        writefits, filepath(string(strmid(file_basename(ok_filename), 0, 20), $
                                   c, $
                                   format='(%"%s_l1_cam%d_nomask.fts")'), $
                            root=l1_dir), $
                   u_l1[*, *, c], header
      endif
    endfor
  endif

  ; shift images to center of array & orient north up

  xcen = 511.5 + 1.0   ; x center of FITS array equals one plus IDL center
  ycen = 511.5 + 1.0   ; y center of FITS array equals one plus IDL center

  ; if shift_center is set, shift both images so that center of occulter is at
  ; the center of the image; if not set, only shift camera 0 to match camera 1
  ; without shifting camera 1 at all
  if (run->config('realtime/shift_center')) then begin
    cal_data_combined_center = dblarr(xsize, ysize, 3)

    for s = 0, 2 do begin
      cal_data_new[*, *, 0, s] = kcor_fshift(reverse(cal_data[*, *, 0, s], 1), $
                                             511.5 - (xsize - 1 - sun_xyr0[0]), $
                                             511.5 - sun_xyr0[1], $
                                             interp=1)
      cal_data_new[*, *, 1, s] = kcor_fshift(reverse(cal_data[*, *, 1, s], 1), $
                                             511.5 - (xsize - 1 - sun_xyr1[0]), $
                                             511.5 - sun_xyr1[1], $
                                             interp=1)
      case cameras of
        '0': cal_data_combined_center[*, *, s] = cal_data_new[*, *, 0, s]
        '1': cal_data_combined_center[*, *, s] = cal_data_new[*, *, 1, s]
        else: cal_data_combined_center[*, *, s] = (cal_data_new[*, *, 0, s]  $
                                                   + cal_data_new[*, *, 1, s]) * 0.5
      endcase
    endfor

    mg_log, 'performing polarization coord transformation', $
            name=log_name, /debug

    ; polar coordinates
    qmk4 = - cal_data_combined_center[*, *, 1] * sin(2.0 * theta1) $
             + cal_data_combined_center[*, *, 2] * cos(2.0 * theta1)
    umk4 =   cal_data_combined_center[*, *, 1] * cos(2.0 * theta1) $
             + cal_data_combined_center[*, *, 2] * sin(2.0 * theta1)

    intensity = cal_data_combined_center[*, *, 0]
  endif else begin
    mg_log, 'skipping shifting image to center', name=log_name, /debug

    cal_data_combined = dblarr(xsize, ysize, 3)

    ; TODO: why no reverse in kcor_fshift?
    for s = 0, 2 do begin
      camera_0 = kcor_fshift(cal_data[*, *, 0, s], deltax, deltay, interp=1)
      camera_1 = cal_data[*, *, 1, s]

      mg_log, 'cameras used: %s', cameras, name=log_name, /debug
      case cameras of
        '0': cal_data_combined[*, *, s] = camera_0
        '1': cal_data_combined[*, *, s] = camera_1
        else: cal_data_combined[*, *, s] = (camera_0 + camera_1) / 2.0
      endcase
    endfor

    mg_log, 'performing polarization coord transformation', $
            name=log_name, /debug

    ; polar coordinate images (mk4 scheme)
    qmk4 = - cal_data_combined[*, *, 1] * sin(2.0 * theta1) $
           + cal_data_combined[*, *, 2] * cos(2.0 * theta1)
    umk4 = cal_data_combined[*, *, 1] * cos(2.0 * theta1) $
           + cal_data_combined[*, *, 2] * sin(2.0 * theta1)

    intensity = cal_data_combined[*, *, 0]
  endelse

  ; rotate solar North up with small correction for spar alignment
  qmk4 = rot(qmk4, pangle + run->epoch('rotation_correction'), 1, /interp)
  umk4 = rot(umk4, pangle + run->epoch('rotation_correction'), 1, /interp)
  intensity = rot(intensity, pangle + run->epoch('rotation_correction'), 1, $
                  /interp)

  ; output array for FITS data
  data = [[[umk4]], [[qmk4]], [[intensity]]]

  kcor_create_gif, ok_filename, umk4, date_obs, $
                   level=1, $
                   scaled_image=scaled_image, $
                   run=run, log_name=log_name

  ;----------------------------------------------------------------------------
  ; CREATE A FITS IMAGE:
  ;****************************************************************************
  ; BUILD NEW HEADER: reorder old header and insert new information.
  ;****************************************************************************
  ; Enter the info from the level 0 header and insert ephemeris and comments
  ; in proper order. Remove information from level 0 header that is 
  ; NOT correct for level 1 and 2 images.
  ; For example:  NAXIS = 4 for level 0 but NAXIS =  2 for level 1&2 data. 
  ; Therefore NAXIS3 and NAXIS4 fields are not relevent for level 1 and 2 data.
  ;----------------------------------------------------------------------------
  ; Issues of interest:
  ;----------------------------------------------------------------------------
  ; 1. SGSRAZR and SGSDECZR keywords added Oct 22, 2013 00:13:58 image
  ; 2. O1ID objective lens id keyword added on June 18, 2014 22:29:48
  ; 3. On June 17, 2014 19:30 Allen reports the Optimax 01 was installed.
  ;    Prior to that date the 01 was from Jenoptik
  ;    NEED TO CHECK THE EXACT TIME NEW OBJECTIVE WENT IN BY OBSERVING 
  ;    CHANGES IN ARTIFACTS.  IT MAY HAVE BEEN INSTALLED EARLIER IN DAY.
  ; 4. IDL stuctures turn boolean 'T' and 'F' into integers (1, 0);
  ;    Need to turn back to boolean to meet FITS headers standards.
  ; 5. Structures don't accept dashes ('-') in keywords which are FITS header
  ;    standards (e.g. date-obs).
  ;    use /DASH2UNDERSCORE
  ; 6. Structures don't save comments. Need to type them back in.
  ; 7. LYOTSTOP key word added on Oct 17, 2016. (to reflect previous insertion
  ;    of 2nd lyot stop)
  ;----------------------------------------------------------------------------

  ; To date (April 28, 2017) 4 new keywords have been added to the level 0
  ; headers
  ; eCheck to see if the day being processed has these keywords in the level
  ; 0 header

  check_sgsrazr  = tag_exist(struct, 'SGSRAZR')
  check_sgsdeczr = tag_exist(struct, 'SGSDECZR')
  check_lyotstop = tag_exist(struct, 'LYOTSTOP')

  ; clean bad SGS information
  if (run->epoch('use_sgs')) then begin
    bad_dimv = struct.sgsdimv lt 1.0 or struct.sgsdimv gt 10.0
    bad_scint = struct.sgsscint lt 0.0 or struct.sgsscint gt 20.0
    if (bad_dimv) then struct.sgsdimv = !values.f_nan
    if (bad_scint) then struct.sgsscint = !values.f_nan
    if (bad_dimv || bad_scint) then begin
      struct.sgsdims = !values.f_nan
      struct.sgssumv = !values.f_nan
      struct.sgssums = !values.f_nan
      struct.sgsrav  = !values.f_nan
      struct.sgsras  = !values.f_nan
      struct.sgsdecv = !values.f_nan
      struct.sgsdecs = !values.f_nan
    endif
  endif else begin
    struct.sgsdimv  = !values.f_nan
    struct.sgsscint = !values.f_nan
    struct.sgsdims  = !values.f_nan
    struct.sgssumv  = !values.f_nan
    struct.sgssums  = !values.f_nan
    struct.sgsrav   = !values.f_nan
    struct.sgsras   = !values.f_nan
    struct.sgsdecv  = !values.f_nan
    struct.sgsdecs  = !values.f_nan
  endelse
  struct.sgsloop = 1   ; SGSLOOP is 1 if image passed quality check

  bscale = 1.0   ; pB is stored in FITS image
  img_quality = 'ok'
  l1_header    = strarr(200)
  l1_header[0] = header[0]         ; contains SIMPLE keyword

  comment_padding = strjoin(strarr(25) + ' ')

  ; image array information
  fxaddpar, l1_header, 'BITPIX', -32, ' bits per pixel'
  fxaddpar, l1_header, 'NAXIS', 3, ' number of dimensions; FITS image' 
  fxaddpar, l1_header, 'NAXIS1', struct.naxis1, ' [pixels] x dimension'
  fxaddpar, l1_header, 'NAXIS2', struct.naxis2, ' [pixels] y dimension'
  fxaddpar, l1_header, 'NAXIS3', 2, ' 0=K-Corona + sky; 1=sky'
  if (struct.extend eq 0) then val_extend = 'F'
  if (struct.extend eq 1) then val_extend = 'T'
  fxaddpar, l1_header, 'EXTEND', 'F', ' no FITS extensions'

  ; normalize odd values for date/times, particularly "60" as minute value in
  ; DATE-END
  struct.date_d$obs = kcor_normalize_datetime(struct.date_d$obs, error=error)
  struct.date_d$end = kcor_normalize_datetime(struct.date_d$end, error=error)
  if (error ne 0L) then begin
    struct.date_d$end = kcor_normalize_datetime(struct.date_d$obs, error=error, /add_15)
  endif

  ; observation information
  fxaddpar, l1_header, 'DATE-OBS', struct.date_d$obs, ' UTC observation start'
  fxaddpar, l1_header, 'DATE-END', struct.date_d$end, ' UTC observation end'

  fxaddpar, l1_header, 'MJD-OBS', $
            kcor_dateobs2julday(struct.date_d$obs) - 2400000.5D, $
            ' [days] modified Julian date', $
            format='F0.9'
  fxaddpar, l1_header, 'MJD-END', $
            kcor_dateobs2julday(struct.date_d$end) - 2400000.5D, $
            ' [days] modified Julian date', $
            format='F0.9'

  fxaddpar, l1_header, 'TIMESYS',  'UTC', $
            ' date/time system: Coordinated Universal Time'
  fxaddpar, l1_header, 'DATE_HST', date_hst, ' MLSO observation date [HST]'
  fxaddpar, l1_header, 'LOCATION', 'MLSO', $
            ' Mauna Loa Solar Observatory, Hawaii'
  fxaddpar, l1_header, 'ORIGIN',   struct.origin, $
            ' Nat.Ctr.Atmos.Res. High Altitude Observatory'
  fxaddpar, l1_header, 'TELESCOP', 'COSMO K-Coronagraph', $
            ' COSMO: COronal Solar Magnetism Observatory' 
  fxaddpar, l1_header, 'INSTRUME', 'COSMO K-Coronagraph'

  ; wavelength information
  fxaddpar, l1_header, 'WAVELNTH', 735, $
            ' [nm] center wavelength of bandpass filter', $
            format='(i4)'
  fxaddpar, l1_header, 'WAVEFWHM', 30, $
            ' [nm] full width half max of bandpass filter', $
            format='(i3)'

  fxaddpar, l1_header, 'OBJECT', 'K-Corona+sky; sky', $
            ' img0=pB Corona+sky; img1=pB sky; img2=Tot Int'
  fxaddpar, l2_header, 'PRODUCT', 'Calibrated intensity', ' pB corona+sky, pB sky, total intensity'
  fxaddpar, l1_header, 'DATATYPE', struct.datatype, ' type of data acquired'
  fxaddpar, l1_header, 'OBSERVER', struct.observer, $
            ' name of Mauna Loa observer'

  ; mechanism positions
  fxaddpar, l1_header, 'DARKSHUT', strtrim(struct.darkshut), $
            ' dark shutter open (out) or closed (in)'
  fxaddpar, l1_header, 'COVER',    strtrim(struct.cover), $
            ' cover in or out of the light beam'
  fxaddpar, l1_header, 'DIFFUSER', strtrim(struct.diffuser), $
            ' diffuser in or out of the light beam'
  fxaddpar, l1_header, 'CALPOL',   strtrim(struct.calpol), $
            ' calibration polarizer in or out of beam'
  fxaddpar, l1_header, 'CALPANG',  struct.calpang, $
            ' calibration polarizer angle', format='(f9.3)'
  exposure = run->epoch('use_exptime') ? struct.exptime : run->epoch('exptime')
  fxaddpar, l1_header, 'EXPTIME',  exposure * 1.e-3, $
            ' [s] exposure time for each frame', format='(f10.6)'
  numsum = run->epoch('use_numsum') ? struct.numsum : run->epoch('numsum')
  fxaddpar, l1_header, 'NUMSUM', numsum, $
            ' # frames summed per L0 img for each pol state'

  fxaddpar, l1_header, 'BUNIT', 'Mean Solar Brightness', $
            ' [B/Bsun] units of solar disk brightness'
  diffsrid = run->epoch('use_diffsrid') ? struct.diffsrid : run->epoch('diffsrid')
  fxaddpar, l1_header, 'BOPAL', $
            run->epoch(diffsrid) * 1e-6, $
            string(run->epoch(diffsrid + '_comment'), $
                   format='(%" %s")'), $
            format='(G0.3)'

  fxaddpar, l1_header, 'BZERO', 0, $
            ' offset for unsigned integer data'
  fxaddpar, l1_header, 'BSCALE', bscale, $
            ' physical = data * BSCALE + BZERO', format='(F8.3)'

  ; data display information
  fxaddpar, l1_header, 'DATAMIN', min(data, /nan), ' minimum value of data', $
            format='(E0.4)'
  fxaddpar, l1_header, 'DATAMAX', max(data, /nan), ' maximum value of data', $
            format='(E0.4)'
  fxaddpar, l1_header, 'DISPMIN', run->epoch('display_min'), $
            ' minimum value for display', $
            format='(G0.3)'
  fxaddpar, l1_header, 'DISPMAX', run->epoch('display_max'), $
            ' maximum value for display', $
            format='(G0.3)'
  fxaddpar, l1_header, 'DISPEXP', run->epoch('display_exp'), $
            ' exponent value for display (d=b^DISPEXP)', $
            format='(f10.2)'
  fxaddpar, l1_header, 'DISPGAM', run->epoch('display_gamma'), $
            ' gamma value for color table correction', $
            format='(f10.2)'

  ; coordinate system information
  fxaddpar, l1_header, 'WCSNAME', 'helioprojective-cartesian', $
            ' World Coordinate System (WCS) name'
  fxaddpar, l1_header, 'CTYPE1', 'HPLN-TAN', $
            ' [deg] helioprojective west angle: solar X'
  fxaddpar, l1_header, 'CRPIX1', xcen, $
            ' [pixel] solar X center (index origin=1)', $
            format='(f9.2)'
  fxaddpar, l1_header, 'CRVAL1', 0.00, ' [arcsec] solar X sun center', $
            format='(f9.2)'
  fxaddpar, l1_header, 'CDELT1', run->epoch('plate_scale'), $
            ' [arcsec/pixel] solar X increment = platescale', $
            format='(f9.4)'
  fxaddpar, l1_header, 'CUNIT1', 'arcsec', ' unit of CRVAL1'
  fxaddpar, l1_header, 'CTYPE2', 'HPLT-TAN', $
            ' [deg] helioprojective north angle: solar Y'
  fxaddpar, l1_header, 'CRPIX2', ycen, $
            ' [pixel] solar Y center (index origin=1)', $
            format='(f9.2)'
  fxaddpar, l1_header, 'CRVAL2', 0.00, ' [arcsec] solar Y sun center', $
            format='(f9.2)'
  fxaddpar, l1_header, 'CDELT2', run->epoch('plate_scale'), $
            ' [arcsec/pixel] solar Y increment = platescale', $
            format='(f9.4)'
  fxaddpar, l1_header, 'CUNIT2', 'arcsec', ' unit of CRVAL2'
  fxaddpar, l1_header, 'INST_ROT', 0.00, $
            ' [deg] rotation of the image wrt solar north', $
            format='(f9.3)'
  image_scale = kcor_compute_platescale((radius_0 + radius_1) / 2.0, $
                                        occltrid, $
                                        run=run)
  fxaddpar, l1_header, 'IMAGESCL', image_scale, $
            ' [arcsec/pixel] image scale for this file', $
            format='(f9.4)'

  au_to_meters = 149597870700.0D

  fxaddpar, l1_header, 'DSUN_OBS', $
            dist_au * au_to_meters, $
            ' [m] distance to the Sun from observer', $
            format='(f0.1)'
  fxaddpar, l1_header, 'HGLN_OBS', $
            0.0, $
            ' [deg] Stonyhurst heliographic longitude', $
            format='(f0.3)'
  fxaddpar, l1_header, 'HGLT_OBS', $
            bangle, $
            ' [deg] Stonyhurst heliographic latitude', $
            format='(f0.3)'
  fxaddpar, l1_header, 'PC1_1', 1.00, $
            ' coord transform matrix element (1, 1) WCS std.', $
            format='(f9.3)'
  fxaddpar, l1_header, 'PC1_2', 0.00, $
            ' coord transform matrix element (1, 2) WCS std.', $
            format='(f9.3)'
  fxaddpar, l1_header, 'PC2_1', 0.00, $
            ' coord transform matrix element (2, 1) WCS std.', $
            format='(f9.3)'
  fxaddpar, l1_header, 'PC2_2', 1.00, $
            ' coord transform matrix element (2, 2) WCS std.', $
            format='(f9.3)'

  ; software information
  fxaddpar, l1_header, 'QUALITY', img_quality, ' image quality'
  fxaddpar, l1_header, 'LEVEL', 'L1', $
            ' level 1 inst.-corrected calibrated pB intensity'

  check_socketcam = tag_exist(struct, 'SOCKETCA')
  if (check_socketcam) then begin
    fxaddpar, l1_header, 'SOCKETCA', struct.socketca, $
              ' camera interface software filename'
  endif

  fxaddpar, l1_header, 'DATE_DP', date_dp, ' L1 processing date (UTC)'
  version = kcor_find_code_version(revision=revision, date=code_date)
  fxaddpar, l1_header, 'DPSWID',  $
            string(version, revision, $
                   format='(%"%s [%s]")'), $
            string(code_date, $
                   format='(%" L1 data processing software (%s)")')

  fxaddpar, l1_header, 'RCAMCORR', $
            rcam_cor_filename eq '' ? !null : file_basename(rcam_cor_filename), $
            run->epoch('rcamcorr_comment'), /null
  fxaddpar, l1_header, 'TCAMCORR', $
            tcam_cor_filename eq '' ? !null : file_basename(tcam_cor_filename), $
            run->epoch('tcamcorr_comment'), /null

  xshift_camera = run->epoch('xshift_camera')
  fxaddpar, l1_header, 'XCAMSH0', xshift_camera[0], $
            ' [px] image shift, + to right'
  fxaddpar, l1_header, 'XCAMSH1', xshift_camera[1], $
            ' [px] image shift, + to right'

  xshift_camera_correction = run->epoch('xshift_camera_correction')
  fxaddpar, l1_header, 'XCAMCSH0', xshift_camera_correction[0], $
            ' [px] cam corr shift to align w/ img, + to left'
  fxaddpar, l1_header, 'XCAMCSH1', xshift_camera_correction[1], $
            ' [px] cam corr shift to align w/ img, + to left'

  fxaddpar, l1_header, 'FIXCAMLC', $
            run->config('calibration/interpolate_camera_correction') ? 1 : 0, $
            ' interp over bad pixels in camera lin correction'
  fxaddpar, l1_header, 'CALFILE', file_basename(calpath), $
            ' calibration file'
  fxaddpar, l1_header, 'DISTORT', file_basename(dc_path), $
            ' distortion file'
    case cameras of
      '0': cameras_used = 'RCAM'
      '1': cameras_used = 'TCAM'
      else: cameras_used = 'both'
    endcase
    fxaddpar, l1_header, 'CAMERAS', cameras_used, $
              ' cameras used in processing'

  fxaddpar, l1_header, 'ROLLCORR', run->epoch('rotation_correction'), $
            ' [deg] clockwise offset: spar polar axis align.', $
            format='(G0.1)'

  fxaddpar, l1_header, 'DMODSWID', '2016-05-26', $
            ' date of demodulation software'
  fxaddpar, l1_header, 'OBSSWID', struct.obsswid, $
            ' version of the LabVIEW observing software'

  ; raw camera occulting center & radius information
  fxaddpar, l1_header, 'RCAMXCEN', xcen0 + 1, $
            ' [pixel] camera 0 raw X-coord occulting center', $
            format='(f8.2)'
  fxaddpar, l1_header, 'RCAMYCEN', ycen0 + 1, $
            ' [pixel] camera 0 raw Y-coord occulting center', $
            format='(f8.2)'
  fxaddpar, l1_header, 'RCAM_RAD', radius_0, $
            ' [pixel] camera 0 raw occulter radius', $
            format='(f8.2)'
  fxaddpar, l1_header, 'RCAM_DCX', info_dc0[0] + 1, $
            ' [pixel] camera 0 dist cor occulter X center', $
            format='(f8.2)'
  fxaddpar, l1_header, 'RCAM_DCY', info_dc0[1] + 1, $
            ' [pixel] camera 0 dist cor occulter Y center', $
            format='(f8.2)'
  fxaddpar, l1_header, 'RCAM_DCR', info_dc0[2], $
            ' [pixel] camera 0 dist corrected occulter radius', $
            format='(f8.2)'

  fxaddpar, l1_header, 'TCAMXCEN', xcen1 + 1, $
            ' [pixel] camera 1 raw X-coord occulting center', $
            format='(f8.2)'
  fxaddpar, l1_header, 'TCAMYCEN', ycen1 + 1, $
            ' [pixel] camera 1 raw Y-coord occulting center', $
            format='(f8.2)'
  fxaddpar, l1_header, 'TCAM_RAD', radius_1, $
            ' [pixel] camera 1 raw occulter radius', $
            format='(f8.2)'
  fxaddpar, l1_header, 'TCAM_DCX', info_dc1[0] + 1, $
            ' [pixel] camera 1 dist cor occulter X center', $
            format='(f8.2)'
  fxaddpar, l1_header, 'TCAM_DCY', info_dc1[1] + 1, $
            ' [pixel] camera 1 dist cor occulter Y center', $
            format='(f8.2)'
  fxaddpar, l1_header, 'TCAM_DCR', info_dc1[2], $
            ' [pixel] camera 1 dist corrected occulter radius', $
            format='(f8.2)'

  fxaddpar, l1_header, 'RCAMPOLS', start_state[0], $
            ' first state used in polarization demodulation'
  fxaddpar, l1_header, 'TCAMPOLS', start_state[1], $
            ' first state used in polarization demodulation'

  if (~array_equal(center_offset, [0.0, 0.0])) then begin
    fxaddpar, l1_header, 'XOFFSET', center_offset[0], $
              ' [pixel] x-offset between occulter and sun centers', $
              format='(f8.2)'
    fxaddpar, l1_header, 'YOFFSET', center_offset[1], $
              ' [pixel] y-offset between occulter and sun centers', $
              format='(f8.2)'
  endif

  ; add ephemeris data

  ; Solar radius determined from PICARD/SODISM observations and extremely weak
  ; wavelength dependence in the visible and the near-infrared' by Meftah
  ; et al. 2018; https://doi.org/10.1051/0004-6361/201732159
  rsun_ref = 6.96182E8
  fxaddpar, l1_header, 'RSUN_REF', $
            rsun_ref, $
            ' [m] solar radius doi:10.1051/0004-6361/201732159', $
            format='(g0.6)'
  fxaddpar, l1_header, 'RSUN_OBS', radsun, $
            string(dist_au * radsun, $
                   '(%" [arcsec] solar radius using ref radius %0.2f\"")'), $
            format='(f8.2)'
  fxaddpar, l1_header, 'RSUN', radsun, $
            ' [arcsec] solar radius (old standard keyword)', $
            format='(f8.2)'
  fxaddpar, l1_header, 'R_SUN', radsun / run->epoch('plate_scale'), $
            ' [pixel] solar radius', format = '(f9.2)'
  fxaddpar, l1_header, 'SOLAR_P0', pangle, $
            ' [deg] solar P angle applied (image has N up)', format='(f9.3)'
  fxaddpar, l1_header, 'CRLT_OBS', bangle, $
            ' [deg] solar B angle: Carrington latitude ', $
            format='(f8.3)'
  fxaddpar, l1_header, 'CRLN_OBS', tim2carr_carrington_long, $
            ' [deg] solar L angle: Carrington longitude', $
            format='(f9.3)'
  fxaddpar, l1_header, 'CAR_ROT',  fix(tim2carr_carrington_rotnum), $
            ' Carrington rotation number', format = '(i4)'
  fxaddpar, l1_header, 'SOLAR_RA', sol_ra, $
            ' [h] solar right ascension (hours)', $
            format='(f9.3)'
  fxaddpar, l1_header, 'SOLARDEC', sol_dec, $
            ' [deg] solar declination', format = '(f9.3)'

  ; engineering data
  rcamfocs = struct.rcamfocs
  srcamfocs = strmid(string(struct.rcamfocs), 0, 3)
  if (srcamfocs eq 'NaN') then rcamfocs = 0.0
  tcamfocs = struct.tcamfocs
  stcamfocs = strmid(string(struct.tcamfocs), 0, 3)
  if (stcamfocs eq 'NaN') then tcamfocs = 0.0

  fxaddpar, l1_header, 'O1FOCS',   struct.o1focs, $
            ' [mm] objective lens (01) focus position', $
            format='(f8.3)'
  fxaddpar, l1_header, 'RCAMFOCS', rcamfocs, $
            ' [mm] camera 0 focus position', format='(f9.3)'
  fxaddpar, l1_header, 'TCAMFOCS', tcamfocs, $
            ' [mm] camera 1 focus position', format='(f9.3)'
  fxaddpar, l1_header, 'MODLTRT',  struct.modltrt, $
            ' [deg C] modulator temperature', format = '(f8.3)'

  ; component identifiers
  fxaddpar, l1_header, 'CALPOLID', $
            run->epoch('use_calpolid') ? struct.calpolid : run->epoch('calpolid'), $
            ' ID polarizer'
  fxaddpar, l1_header, 'DIFFSRID', diffsrid, $
            run->epoch('use_diffsrid') ? ' ID diffuser' : run->epoch('diffsrid_comment')
  fxaddpar, l1_header, 'FILTERID', struct.filterid, $
            ' ID bandpass filter'

  if (run->epoch('use_O1id')) then begin
    o1id = run->epoch(struct.o1id, found=found, error_message=error_message)
    if (~found) then begin
      mg_log, error_message, name=log_name, /error
      o1id = ''
    endif
  endif else begin
    o1id = run->epoch('O1id')
  endelse
  fxaddpar, l1_header, 'O1ID', o1id, ' ID objective (O1) lens'

  if (check_lyotstop ne 0) then begin
    fxaddpar, l1_header, 'LYOTSTOP', struct.lyotstop, $ 
              ' specifies if the 2nd Lyot stop is in the beam'
  endif

  occulter_comment = run->epoch(strmid(occltrid, 0, 8) + '-comment', $
                                found=found)

  ; Sometimes the OCCLTRID does not have the trailing " mark. This correction
  ; is only needed to report in the FITS header, not the calculations, which
  ; only use the first 8 characters of OCCLTRID to distinguish between the
  ; occulters. The OCCLTRID-use_ticks epoch values indicate if that OCCLTRID
  ; is reporting its size in arcseconds, so need to check last character. One
  ; exception is do not fix the 'OC-1017.0" TAPERED' OCCLTRID.
  use_ticks = run->epoch(strmid(occltrid, 0, 8) + '-use_ticks')
  if (use_ticks && strmid(occltrid, 0, 1, /reverse_offset) ne '"') then begin
    if (strmid(occltrid, 6, 7, /reverse_offset) ne 'TAPERED') then begin
      occltrid = occltrid + '"'
    endif
  endif

  fxaddpar, l1_header, 'OCCLTRID', occltrid, ' ' + occulter_comment
  fxaddpar, l1_header, 'MODLTRID', struct.modltrid, ' ID modulator'

  if (run->epoch('use_camera_info')) then begin
    prefix = run->epoch('use_camera_prefix') ? run->epoch('camera_prefix') : ''
    rcamid = prefix + struct.rcamid
    tcamid = prefix + struct.tcamid
    rcamlut = struct.rcamlut
    tcamlut = struct.tcamlut
  endif else begin
    rcamid = run->epoch('rcamid')
    tcamid = run->epoch('tcamid')
    rcamlut = run->epoch('rcamlut')
    tcamlut = run->epoch('tcamlut')
  endelse

  fxaddpar, l1_header, 'RCAMID', rcamid, ' ' + run->epoch('rcamid_comment')
  fxaddpar, l1_header, 'TCAMID', tcamid, ' ' + run->epoch('tcamid_comment')
  fxaddpar, l1_header, 'RCAMLUT', rcamlut, ' ' + run->epoch('rcamlut_comment')
  fxaddpar, l1_header, 'TCAMLUT', tcamlut, ' ' + run->epoch('tcamlut_comment')

  fxaddpar, l1_header, 'SGSDIMV', struct.sgsdimv, $
            ' [V] SGS DIM signal mean', $
            format='(f9.4)', /null
  fxaddpar, l1_header, 'SGSDIMS', struct.sgsdims, $
            ' [V] SGS DIM signal standard deviation', $
            format='(e11.3)', /null
  fxaddpar, l1_header, 'SGSSUMV', struct.sgssumv, $
            ' [V] mean SGS sum signal', format='(f9.4)', /null
  fxaddpar, l1_header, 'SGSSUMS',  struct.sgssums, $
            ' [V] SGS sum signal standard deviation', $
            format='(e11.3)', /null
  fxaddpar, l1_header, 'SGSRAV', struct.sgsrav, $
            ' [V] mean SGS RA error signal', format='(e11.3)', /null
  fxaddpar, l1_header, 'SGSRAS', struct.sgsras, $
            ' [V] mean SGS RA error standard deviation', $
            format='(e11.3)', /null
  if (check_sgsrazr ne 0) then begin
    fxaddpar, l1_header, 'SGSRAZR', struct.sgsrazr, $
              ' [arcsec] SGS RA zeropoint offset', format='(f9.4)', /null
  endif
  fxaddpar, l1_header, 'SGSDECV', struct.sgsdecv, $
            ' [V] mean SGS DEC error signal', format='(e11.3)', /null
  fxaddpar, l1_header, 'SGSDECS',  struct.sgsdecs, $
            ' [V] mean SGS DEC error standard deviation', $
            format='(e11.3)', /null
  if (check_sgsdeczr ne 0) then begin
    fxaddpar, l1_header, 'SGSDECZR', struct.sgsdeczr, $
              ' [arcsec] SGS DEC zeropoint offset', format='(f9.4)', /null
  endif
  fxaddpar, l1_header, 'SGSSCINT', struct.sgsscint, $
            ' [arcsec] SGS scintillation seeing estimate', $
            format='(f9.4)', /null
  fxaddpar, l1_header, 'SGSLOOP',  struct.sgsloop, ' SGS loop closed fraction'

  ; data citation URL
  fxaddpar, l1_header, 'DATACITE', run->epoch('doi_url'), ' URL for DOI'

  fxaddpar, l1_header, 'DUMMY', 1.0

  ; add headings
  fxaddpar, l1_header, 'COMMENT', $
            comment_padding + 'HARDWARE MECHANISM KEYWORDS GROUPED BELOW', $
            before='DARKSHUT'
  fxaddpar, l1_header, 'COMMENT', $
            comment_padding + 'COORDINATE SYSTEM KEYWORDS GROUPED BELOW', $
            before='WCSNAME'
  fxaddpar, l1_header, 'COMMENT', $
            comment_padding + 'PROCESSING SOFTWARE KEYWORDS GROUPED BELOW', $
            before='QUALITY'
  fxaddpar, l1_header, 'COMMENT', $
            comment_padding + 'SCALING KEYWORDS GROUPED BELOW', $
            before='BUNIT'
  fxaddpar, l1_header, 'COMMENT', $
            comment_padding + 'CAMERA OCCULTING KEYWORDS GROUPED BELOW', $
            before='RCAMXCEN'
  fxaddpar, l1_header, 'COMMENT', $
            comment_padding + 'EPHEMERIS KEYWORDS GROUPED BELOW', $
            before='RSUN_OBS'
  fxaddpar, l1_header, 'COMMENT', $
            comment_padding + 'ENGINEERING KEYWORDS GROUPED BELOW', $
            before='O1FOCS'
  fxaddpar, l1_header, 'COMMENT', $
            comment_padding + 'SPAR GUIDER SYSTEM KEYWORDS GROUPED BELOW', $
            before='SGSDIMV'
  
  ; instrument comments
  comments = ['The COSMO K-coronagraph is a 20-cm aperture, internally occulted', $
              'coronagraph, which observes the polarization brightness of the corona', $
              'with a field-of-view from ~1.05 to 3 solar radii in a wavelength range', $
              'from 720 to 750 nm. Nominal time cadence is 15 seconds.']
  comments = [mg_strwrap(strjoin(comments, ' '), width=72), '']

  fxaddpar, l1_header, 'COMMENT', comments[0], after='DATACITE'
  for c = 1L, n_elements(comments) - 1L do begin
    fxaddpar, l1_header, 'COMMENT', comments[c]
  endfor

  ; data processing comments
  history = ['Level 1 calibration and processing steps: dark current subtracted;', $
             'gain correction; apply polarization demodulation matrix; apply', $
             'distortion correction; align each camera to center, rotate to solar', $
             'north and combine cameras; coordinate transformation from cartesian', $
             'to tangential polarization.']
  history = mg_strwrap(strjoin(history, ' '), width=72)
  for h = 0L, n_elements(history) - 1L do sxaddhist, history[h], l1_header

  sxdelpar, l1_header, 'DUMMY'

  ; write FITS image to disk
  l1_filename = string(strmid(file_basename(ok_filename), 0, 20), $
                       format='(%"%s_l1.fts")')
  writefits, filepath(l1_filename, root=l1_dir), float(data), l1_header

  ; now make cropped GIF file
  kcor_cropped_gif, umk4, run.date, date_struct, $
                    run=run, log_name=log_name, $
                    level=1

  loop_time = toc(clock)   ; save loop time
  mg_log, '%0.1f sec to process %s', loop_time, file_basename(ok_filename), $
          name=log_name, /debug

  done:
  mg_log, /check_math, name=log_name, /debug
end


; main-level example program

date = '20190924'
config_filename = filepath('kcor.parker.cfg', $
                           subdir=['..', '..', 'config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)


l0_filename = filepath('20190924_175132_kcor.fts.gz', $
                       subdir=[date, 'level0'], $
                       root=run->config('processing/raw_basedir'))

kcor_l1, l0_filename, run=run, log_name='kcor/rt'

obj_destroy, run

end
