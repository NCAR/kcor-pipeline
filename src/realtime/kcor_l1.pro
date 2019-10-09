; docformat = 'rst'

;+
; Produce the L1 FITS and GIF files.
;
; :Params:
;   ok_file : in, out, optional, type=strarr
;     level 0 filename to process
;
; :Keywords:
;   nomask : in, optional, type=boolean
;     set to not apply a mask to the FITS or GIF files, adding a "nomask" to the
;     filenames
;   run : in, required, type=object
;     `kcor_run` object
;   mean_phase1 : out, optional, type=fltarr
;     mean_phase1 for `ok_file`
;   error : out, optional, type=long
;     set to a named variable to retrieve the error status of the call
;-
pro kcor_l1, ok_filename, $
             l1_filename=l1_filename, $
             nomask=nomask, $
             run=run, $
             mean_phase1=mean_phase1, $
             log_name=log_name, $
             error=error
  compile_opt strictarr

  error = 0L

  ; setup directories
  dirs  = filepath('level' + ['0', '1', '2'], $
                   subdir=run.date, $
                   root=run->config('processing/raw_basedir'))
  l0_dir = dirs[0]
  l1_dir = dirs[1]
  l2_dir = dirs[2]

  if (~file_test(l1_dir, /directory)) then file_mkdir, l1_dir

  mg_log, 'L1 processing %s%s', $
          file_basename(ok_filename), keyword_set(nomask) ? ' (nomask)' : '', $
          name=log_name, /info

  mean_phase1 = 0.0   ; TODO: this is not set?

  ; set image dimensions
  xsize = 1024L
  ysize = 1024L

  ; set guess for radius - needed to find center
  radius_guess = 178   ; average radius for occulter

  ; initialize variables
  cal_data_new = dblarr(xsize, ysize, 2, 3)
  gain_shift   = dblarr(xsize, ysize, 2)

  l1_filename = string(strmid(file_basename(ok_filename), 0, 20), $
                       keyword_set(nomask) ? '_nomask' : '', $
                       format='(%"%s_l1.5%s.fts")')

  lclock = tic('file_loop')

  img = readfits(ok_filename, header, /silent)

  type = fxpar(header, 'DATATYPE')
  mg_log, 'type: %s', strmid(type, 0, 3), name=log_name, /debug

  ; read date of observation
  date_obs = sxpar(header, 'DATE-OBS')   ; yyyy-mm-ddThh:mm:ss
  date_struct = kcor_parse_dateobs(date_obs, hst_date=hst_date_struct)
  run.time = date_obs

  ; extract information from calibration file
  calpath = filepath(run->epoch('cal_file'), root=run->config('calibration/out_dir'))
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
  ncdf_varget, unit, 'Gain', gain_alfred
  gain_alfred /= 1e-6   ; this makes gain_alfred in units of B/Bsun
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
    if (run->epoch('use_pipeline_calfiles')) then begin
      tokens = strsplit(file_basename(run->epoch('cal_file'), '.ncdf'), '_', /extract)
      cal_exptime = float(strmid(tokens[-1], 0, strlen(tokens[-1]) - 2))
    endif else begin
      ; no way to determine EXPTIME for old-style cal files
      mg_log, 'no way to determine EXPTIME for old-style cal files', $
              name=log_name, /error
      error = 1L
      goto, done
    endelse
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

  ; correct camera nonlinearity
  kcor_correct_camera, img, header, run=run, logger_name=log_name, $
                       rcam_cor_filename=rcam_cor_filename, $
                       tcam_cor_filename=tcam_cor_filename

  if (run->config('realtime/diagnostics')) then begin
    save, img, header, filename=strmid(file_basename(ok_filename), 0, 20) + '_cam.sav'
  endif

  if (run->epoch('remove_horizontal_artifact')) then begin
    kcor_find_badlines, img, $
                        cam0_badlines=cam0_badlines, $
                        cam1_badlines=cam1_badlines

    if (n_elements(cam0_badlines) gt 0L) then begin
      mg_log, 'correcting cam 0 bad lines: %s', $
              strjoin(strtrim(cam0_badlines, 2), ', '), $
              name='kcor/rt', /debug
    endif
    if (n_elements(cam1_badlines) gt 0L) then begin
      mg_log, 'correcting cam 1 bad lines: %s', $
              strjoin(strtrim(cam1_badlines, 2), ', '), $
              name='kcor/rt', /debug
    endif

    kcor_correct_horizontal_artifact, img, $
                                      cam0_badlines, $
                                      cam1_badlines
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

      img_cor[*, *, s, b] = temporary(img_temp) / gain_shift[*, *, b]
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

  ; find image centers of distortion-corrected images
  ; camera 0:
  info_dc0 = kcor_find_image(cimg0, radius_guess, $
                             /center_guess, $
                             max_center_difference=run->epoch('max_center_difference'), $
                             log_name=log_name, $
                             xoffset=center_offset[0], yoffset=center_offset[1], $
                             offset_xyr=sun_xyr0)

  sun_xx0 = dindgen(xsize, ysize) mod xsize - sun_xyr0[0]
  sun_yy0 = transpose(dindgen(ysize, xsize) mod ysize) - sun_xyr0[1]

  ; camera 1:
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
  theta1 = rot(reverse(theta1), pangle + run->epoch('rotation_correction'), 1)

  ; combine I, Q, U images from camera 0 and camera 1

  radius = (sun_xyr0[2] + sun_xyr1[2]) * 0.5

  ; to shift camera 0 to canera 1:
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

  ; compute image average from cameras 0 & 1
  cal_data_combined = dblarr(xsize, ysize, 3)

  for s = 0, 2 do begin
    camera_0 = kcor_fshift(cal_data[*, *, 0, s], deltax, deltay)
    camera_1 = cal_data[*, *, 1, s]

    mg_log, 'cameras used: %s', run->config('realtime/cameras'), name=log_name, /debug
    case run->config('realtime/cameras') of
      '0': cal_data_combined[*, *, s] = camera_0
      '1': cal_data_combined[*, *, s] = camera_1
      else: cal_data_combined[*, *, s] = (camera_0 + camera_1) / 2.0
    endcase
  endfor

  ; polar coordinate images (mk4 scheme)
  qmk4 = - cal_data_combined[*, *, 1] * sin(2.0 * theta1) $
           + cal_data_combined[*, *, 2] * cos(2.0 * theta1)
  umk4 = cal_data_combined[*, *, 1] * cos(2.0 * theta1) $
           + cal_data_combined[*, *, 2] * sin(2.0 * theta1)

  intensity = cal_data_combined[*, *, 0]
  mg_log, 'performing polarization coord transformation', $
          name=log_name, /debug

  ; shift images to center of array & orient north up
  xcen = 511.5 + 1     ; x center of FITS array equals one plus IDL center
  ycen = 511.5 + 1     ; y center of FITS array equals one plus IDL center

  if (run->config('realtime/shift_center')) then begin
    cal_data_combined_center = dblarr(xsize, ysize, 3)

    for s = 0, 2 do begin
      cal_data_new[*, *, 0, s] = rot(reverse(cal_data[*, *, 0, s], 1), $
                                     pangle + run->epoch('rotation_correction'), $
                                     1, $
                                     xsize - 1 - sun_xyr0[0], $
                                     sun_xyr0[1], $
                                     cubic=-0.5)
      cal_data_new[*, *, 1, s] = rot(reverse(cal_data[*, *, 1, s], 1), $
                                     pangle + run->epoch('rotation_correction'), $
                                     1, $
                                     xsize - 1 - sun_xyr1[0], $
                                     sun_xyr1[1], $
                                     cubic=-0.5)
      case run->config('realtime/cameras') of
        '0': cal_data_combined_center[*, *, s] = cal_data_new[*, *, 0, s]
        '1': cal_data_combined_center[*, *, s] = cal_data_new[*, *, 1, s]
        else: cal_data_combined_center[*, *, s] = (cal_data_new[*, *, 0, s]  $
                                                   + cal_data_new[*, *, 1, s]) * 0.5
      endcase
    endfor

    xx1    = dindgen(xsize, ysize) mod xsize - 511.5
    yy1    = transpose(dindgen(ysize, xsize) mod ysize) - 511.5
    rad1   = sqrt((xx1 + center_offset[0])^ 2.0 + (yy1 + center_offset[1]) ^ 2.0)

    theta1 = atan(- yy1, - xx1)
    theta1 += !pi
    theta1 = rot(reverse(theta1), pangle + run->epoch('rotation_correction'), 1)

    ; polar coordinates
    qmk4 = - cal_data_combined_center[*, *, 1] * sin(2.0 * theta1) $
             + cal_data_combined_center[*, *, 2] * cos(2.0 * theta1)
    umk4 =   cal_data_combined_center[*, *, 1] * cos(2.0 * theta1) $
             + cal_data_combined_center[*, *, 2] * sin(2.0 * theta1)

    intensity = cal_data_combined_center[*, *, 0]
  endif else begin
    mg_log, 'skipping shfting image to center', name=log_name, /debug
  endelse

  ; sky polarization removal on coordinate-transformed data
  case strlowcase(run->config('realtime/skypol_method')) of
    'subtraction': begin
        mg_log, 'correcting sky polarization with subtraction method', $
                name=log_name, /debug
        qmk4_new = float(qmk4)
        ; umk4 contains the corona
        umk4_new = float(umk4) - float(rot(qmk4, 45.0)) + run->epoch('skypol_bias')
      end
    'sine2theta': begin
        mg_log, 'correcting sky polarization with sine2theta (%d params) method', $
                run->epoch('sine2theta_nparams'), name=log_name, /debug
        kcor_sine2theta_method, umk4, qmk4, intensity, radsun, theta1, rr1, $
                                q_new=qmk3_new, u_new=umk4_new, $
                                run=run
      end
    else: mg_log, 'no sky polarization correction', name=log_name, /debug
  endcase

  ; use only corona minus sky polarization background
  corona = umk4_new

  if (run->epoch('use_sgs')) then begin
    vdimref = kcor_getsgs(header, 'SGSDIMV', /float)
    dimv_comment = ''
  endif else begin
    vdimref = kcor_simulate_sgsdimv(date_obs, run=run)
    dimv_comment = ' (simulated)'
  endelse
  mg_log, 'flat DIMV: %0.1f, image DIMV: %0.1f%s', $
          flat_vdimref, vdimref, dimv_comment, $
          name=log_name, /debug
  if (finite(vdimref) && finite(flat_vdimref)) then begin
    corona *= flat_vdimref / vdimref
  endif

  ; create mask for final image
  if (~keyword_set(nomask)) then begin
    ; mask pixels beyond field of view
    mask = where(rad1 lt r_in or rad1 ge r_out, /null)
    corona[mask] = run->epoch('display_min')
  endif

  ; end of new beam combination modifications

  kcor_l1_gif, ok_filename, corona, date_obs, $
               scaled_image=scaled_image, $
               nomask=nomask, $
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
      if (check_sgsrazr) then struct.sgsrazr = !values.f_nan
      if (check_sgsdeczr) then struct.sgsdeczr = !values.f_nan
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
    if (check_sgsrazr) then struct.sgsrazr = !values.f_nan
    if (check_sgsdeczr) then struct.sgsdeczr = !values.f_nan
  endelse
  struct.sgsloop = 1   ; SGSLOOP is 1 if image passed quality check

  bscale = 1.0   ; pB is stored in FITS image
  img_quality = 'ok'
  newheader    = strarr(200)
  newheader[0] = header[0]         ; contains SIMPLE keyword

  comment_padding = strjoin(strarr(25) + ' ')

  ; image array information
  fxaddpar, newheader, 'BITPIX', -32, ' bits per pixel'
  fxaddpar, newheader, 'NAXIS', 2, ' number of dimensions; FITS image' 
  fxaddpar, newheader, 'NAXIS1', struct.naxis1, ' [pixels] x dimension'
  fxaddpar, newheader, 'NAXIS2', struct.naxis2, ' [pixels] y dimension'
  if (struct.extend eq 0) then val_extend = 'F'
  if (struct.extend eq 1) then val_extend = 'T'
  fxaddpar, newheader, 'EXTEND', 'F', ' no FITS extensions'

  ; normalize odd values for date/times, particularly "60" as minute value in
  ; DATE-END
  struct.date_d$obs = kcor_normalize_datetime(struct.date_d$obs, error=error)
  struct.date_d$end = kcor_normalize_datetime(struct.date_d$end, error=error)
  if (error ne 0L) then begin
    struct.date_d$end = kcor_normalize_datetime(struct.date_d$obs, error=error, /add_15)
  endif

  ; observation information
  fxaddpar, newheader, 'DATE-OBS', struct.date_d$obs, ' UTC observation start'
  ; fxaddpar, newheader, 'DATE-BEG', struct.date_d$obs, ' UTC observation start'
  fxaddpar, newheader, 'DATE-END', struct.date_d$end, ' UTC observation end'

  fxaddpar, newheader, 'TIMESYS',  'UTC', $
            ' date/time system: Coordinated Universal Time'
  fxaddpar, newheader, 'DATE_HST', date_hst, ' MLSO observation date [HST]'
  fxaddpar, newheader, 'LOCATION', 'MLSO', $
            ' Mauna Loa Solar Observatory, Hawaii'
  fxaddpar, newheader, 'ORIGIN',   struct.origin, $
            ' Nat.Ctr.Atmos.Res. High Altitude Observatory'
  fxaddpar, newheader, 'TELESCOP', 'COSMO K-Coronagraph', $
            ' COSMO: COronal Solar Magnetism Observatory' 
  fxaddpar, newheader, 'INSTRUME', 'COSMO K-Coronagraph'

  ; wavelength information
  fxaddpar, newheader, 'WAVELNTH', 735, $
            ' [nm] center wavelength of bandpass filter', $
            format='(i4)'
  fxaddpar, newheader, 'WAVEFWHM', 30, $
            ' [nm] full width half max of bandpass filter', $
            format='(i3)'

  fxaddpar, newheader, 'OBJECT',   struct.object, $
            ' white light polarization brightness'
  fxaddpar, newheader, 'DATATYPE', struct.datatype, ' type of data acquired'
  fxaddpar, newheader, 'OBSERVER', struct.observer, $
            ' name of Mauna Loa observer'

  ; mechanism positions
  fxaddpar, newheader, 'DARKSHUT', struct.darkshut, $
            ' dark shutter open (out) or closed (in)'
  fxaddpar, newheader, 'COVER',    struct.cover, $
            ' cover in or out of the light beam'
  fxaddpar, newheader, 'DIFFUSER', struct.diffuser, $
            ' diffuser in or out of the light beam'
  fxaddpar, newheader, 'CALPOL',   struct.calpol, $
            ' calibration polarizer in or out of beam'
  fxaddpar, newheader, 'CALPANG',  struct.calpang, $
            ' calibration polarizer angle', format='(f9.3)'
  exposure = run->epoch('use_exptime') ? struct.exptime : run->epoch('exptime')
  fxaddpar, newheader, 'EXPTIME',  exposure * 1.e-3, $
            ' [s] exposure time for each frame', format='(f10.6)'
  numsum = run->epoch('use_numsum') ? struct.numsum : run->epoch('numsum')
  fxaddpar, newheader, 'NUMSUM', numsum, $
            ' # frames summed per L0 img for each pol state'

  fxaddpar, newheader, 'BUNIT', 'B/Bsun', $
            ' brightness with respect to solar disk'
  diffsrid = run->epoch('use_diffsrid') ? struct.diffsrid : run->epoch('diffsrid')
  fxaddpar, newheader, 'BOPAL', $
            run->epoch(diffsrid) * 1e-6, $
            string(run->epoch(diffsrid + '_comment'), $
                   format='(%" %s")'), $
            format='(G0.3)'

  fxaddpar, newheader, 'BZERO', 0, $
            ' offset for unsigned integer data'
  fxaddpar, newheader, 'BSCALE', bscale, $
            ' physical = data * BSCALE + BZERO', format='(F8.3)'

  ; data display information
  fxaddpar, newheader, 'DATAMIN', min(corona, /nan), ' minimum value of data', $
            format='(E0.4)'
  fxaddpar, newheader, 'DATAMAX', max(corona, /nan), ' maximum value of data', $
            format='(E0.4)'
  fxaddpar, newheader, 'DISPMIN', run->epoch('display_min'), $
            ' minimum value for display', $
            format='(G0.3)'
  fxaddpar, newheader, 'DISPMAX', run->epoch('display_max'), $
            ' maximum value for display', $
            format='(G0.3)'
  fxaddpar, newheader, 'DISPEXP', run->epoch('display_exp'), $
            ' exponent value for display (d=b^DISPEXP)', $
            format='(f10.2)'
  fxaddpar, newheader, 'DISPGAM', run->epoch('display_gamma'), $
            ' gamma value for color table correction', $
            format='(f10.2)'

  ; coordinate system information
  fxaddpar, newheader, 'WCSNAME', 'helioprojective-cartesian', $
            ' World Coordinate System (WCS) name'
  fxaddpar, newheader, 'CTYPE1', 'HPLN-TAN', $
            ' [deg] helioprojective west angle: solar X'
  fxaddpar, newheader, 'CRPIX1', xcen, $
            ' [pixel] solar X center (index origin=1)', $
            format='(f9.2)'
  fxaddpar, newheader, 'CRVAL1', 0.00, ' [arcsec] solar X sun center', $
            format='(f9.2)'
  fxaddpar, newheader, 'CDELT1', run->epoch('plate_scale'), $
            ' [arcsec/pixel] solar X increment = platescale', $
            format='(f9.4)'
  fxaddpar, newheader, 'CUNIT1', 'arcsec', ' unit of CRVAL1'
  fxaddpar, newheader, 'CTYPE2', 'HPLT-TAN', $
            ' [deg] helioprojective north angle: solar Y'
  fxaddpar, newheader, 'CRPIX2', ycen, $
            ' [pixel] solar Y center (index origin=1)', $
            format='(f9.2)'
  fxaddpar, newheader, 'CRVAL2', 0.00, ' [arcsec] solar Y sun center', $
            format='(f9.2)'
  fxaddpar, newheader, 'CDELT2', run->epoch('plate_scale'), $
            ' [arcsec/pixel] solar Y increment = platescale', $
            format='(f9.4)'
  fxaddpar, newheader, 'CUNIT2', 'arcsec', ' unit of CRVAL2'
  fxaddpar, newheader, 'INST_ROT', 0.00, $
            ' [deg] rotation of the image wrt solar north', $
            format='(f9.3)'
  fxaddpar, newheader, 'PC1_1', 1.00, $
            ' coord transform matrix element (1, 1) WCS std.', $
            format='(f9.3)'
  fxaddpar, newheader, 'PC1_2', 0.00, $
            ' coord transform matrix element (1, 2) WCS std.', $
            format='(f9.3)'
  fxaddpar, newheader, 'PC2_1', 0.00, $
            ' coord transform matrix element (2, 1) WCS std.', $
            format='(f9.3)'
  fxaddpar, newheader, 'PC2_2', 1.00, $
            ' coord transform matrix element (2, 2) WCS std.', $
            format='(f9.3)'

  ; software information
  fxaddpar, newheader, 'QUALITY', img_quality, ' image quality'
  fxaddpar, newheader, 'LEVEL', 'L1.5', $
            ' level 1.5 pB Intensity is fully-calibrated'

  check_socketcam = tag_exist(struct, 'SOCKETCA')
  if (check_socketcam) then begin
    fxaddpar, newheader, 'SOCKETCA', struct.socketca, $
              ' camera interface software filename'
  endif

  fxaddpar, newheader, 'DATE_DP', date_dp, ' L1.5 processing date (UTC)'
  version = kcor_find_code_version(revision=revision, date=code_date)
  fxaddpar, newheader, 'DPSWID',  $
            string(version, revision, $
                   format='(%"%s [%s]")'), $
            string(code_date, $
                   format='(%" L1.5 data processing software (%s)")')

  if (rcam_cor_filename ne '') then begin
    fxaddpar, newheader, 'RCAMCORR', file_basename(rcam_cor_filename), $
              ''
  endif
  if (tcam_cor_filename ne '') then begin
    fxaddpar, newheader, 'TCAMCORR', file_basename(tcam_cor_filename), $
              ''
  endif

  fxaddpar, newheader, 'CALFILE', file_basename(calpath), $
            ' calibration file'
  fxaddpar, newheader, 'DISTORT', file_basename(dc_path), $
            ' distortion file'
  if (finite(vdimref) && finite(flat_vdimref) && vdimref ne 0.0) then begin
    skytrans = flat_vdimref / vdimref
  endif
  fxaddpar, newheader, 'SKYTRANS', skytrans, $
            ' ' + run->epoch('skytrans_comment'), $
            format='(F5.3)', /null
  fxaddpar, newheader, 'BIASCORR', run->epoch('skypol_bias'), $
            ' bias added after sky polarization correction', $
            format='(G0.3)'
  fxaddpar, newheader, 'ROLLCORR', run->epoch('rotation_correction'), $
            ' [deg] clockwise offset: spar polar axis align.', $
            format='(G0.1)'

  fxaddpar, newheader, 'DMODSWID', '2016-05-26', $
            ' date of demodulation software'
  fxaddpar, newheader, 'OBSSWID', struct.obsswid, $
            ' version of the LabVIEW observing software'

  ; raw camera occulting center & radius information
  fxaddpar, newheader, 'RCAMXCEN', xcen0 + 1, $
            ' [pixel] camera 0 raw X-coord occulting center', $
            format='(f8.2)'
  fxaddpar, newheader, 'RCAMYCEN', ycen0 + 1, $
            ' [pixel] camera 0 raw Y-coord occulting center', $
            format='(f8.2)'
  fxaddpar, newheader, 'RCAM_RAD', radius_0, $
            ' [pixel] camera 0 raw occulter radius', $
            format='(f8.2)'
  fxaddpar, newheader, 'RCAM_DCX', info_dc0[0] + 1, $
            ' [pixel] camera 0 dist cor occulter X center', $
            format='(f8.2)'
  fxaddpar, newheader, 'RCAM_DCY', info_dc0[1] + 1, $
            ' [pixel] camera 0 dist cor occulter Y center', $
            format='(f8.2)'
  fxaddpar, newheader, 'RCAM_DCR', info_dc0[2], $
            ' [pixel] camera 0 dist corrected occulter radius', $
            format='(f8.2)'

  fxaddpar, newheader, 'TCAMXCEN', xcen1 + 1, $
            ' [pixel] camera 1 raw X-coord occulting center', $
            format='(f8.2)'
  fxaddpar, newheader, 'TCAMYCEN', ycen1 + 1, $
            ' [pixel] camera 1 raw Y-coord occulting center', $
            format='(f8.2)'
  fxaddpar, newheader, 'TCAM_RAD', radius_1, $
            ' [pixel] camera 1 raw occulter radius', $
            format='(f8.2)'
  fxaddpar, newheader, 'TCAM_DCX', info_dc1[0] + 1, $
            ' [pixel] camera 1 dist cor occulter X center', $
            format='(f8.2)'
  fxaddpar, newheader, 'TCAM_DCY', info_dc1[1] + 1, $
            ' [pixel] camera 1 dist cor occulter Y center', $
            format='(f8.2)'
  fxaddpar, newheader, 'TCAM_DCR', info_dc1[2], $
            ' [pixel] camera 1 dist corrected occulter radius', $
            format='(f8.2)'

  if (~array_equal(center_offset, [0.0, 0.0])) then begin
    fxaddpar, newheader, 'XOFFSET', center_offset[0], $
              ' [pixel] x-offset between occulter and sun centers', $
              format='(f8.2)'
    fxaddpar, newheader, 'YOFFSET', center_offset[1], $
              ' [pixel] y-offset between occulter and sun centers', $
              format='(f8.2)'
  endif

  ; add ephemeris data
  fxaddpar, newheader, 'RSUN_OBS', radsun, $
            string(dist_au * radsun, $
                   '(%" [arcsec] solar radius using ref radius %0.2f\"")'), $
            format='(f8.2)'
  fxaddpar, newheader, 'RSUN', radsun, $
            ' [arcsec] solar radius (old standard keyword)', $
            format='(f8.2)'
  fxaddpar, newheader, 'R_SUN', radsun / run->epoch('plate_scale'), $
            ' [pixel] solar radius', format = '(f9.2)'
  fxaddpar, newheader, 'SOLAR_P0', pangle, $
            ' [deg] solar P angle', format='(f9.3)'
  fxaddpar, newheader, 'CRLT_OBS', bangle, $
            ' [deg] solar B angle: Carrington latitude ', $
            format='(f8.3)'
  fxaddpar, newheader, 'CRLN_OBS', tim2carr_carrington_long, $
            ' [deg] solar L angle: Carrington longitude', $
            format='(f9.3)'
  fxaddpar, newheader, 'CAR_ROT',  fix(tim2carr_carrington_rotnum), $
            ' Carrington rotation number', format = '(i4)'
  fxaddpar, newheader, 'SOLAR_RA', sol_ra, $
            ' [h] solar right ascension (hours)', $
            format='(f9.3)'
  fxaddpar, newheader, 'SOLARDEC', sol_dec, $
            ' [deg] solar declination', format = '(f9.3)'

  ; engineering data
  rcamfocs = struct.rcamfocs
  srcamfocs = strmid(string(struct.rcamfocs), 0, 3)
  if (srcamfocs eq 'NaN') then rcamfocs = 0.0
  tcamfocs = struct.tcamfocs
  stcamfocs = strmid(string(struct.tcamfocs), 0, 3)
  if (stcamfocs eq 'NaN') then tcamfocs = 0.0

  fxaddpar, newheader, 'O1FOCS',   struct.o1focs, $
            ' [mm] objective lens (01) focus position', $
            format='(f8.3)'
  fxaddpar, newheader, 'RCAMFOCS', rcamfocs, $
            ' [mm] camera 0 focus position', format='(f9.3)'
  fxaddpar, newheader, 'TCAMFOCS', tcamfocs, $
            ' [mm] camera 1 focus position', format='(f9.3)'
  fxaddpar, newheader, 'MODLTRT',  struct.modltrt, $
            ' [deg C] modulator temperature', format = '(f8.3)'

  ; component identifiers
  fxaddpar, newheader, 'CALPOLID', struct.calpolid, $
            ' ID polarizer'
  fxaddpar, newheader, 'DIFFSRID', diffsrid, $
            run->epoch('use_diffsrid') ? ' ID diffuser' : run->epoch('diffsrid_comment')
  fxaddpar, newheader, 'FILTERID', struct.filterid, $
            ' ID bandpass filter'

  o1id = run->epoch('use_O1id') ? run->epoch(struct.o1id) : run->epoch('O1id')
  fxaddpar, newheader, 'O1ID', o1id, ' ID objective (O1) lens' 

  if (check_lyotstop ne 0) then begin
    fxaddpar, newheader, 'LYOTSTOP', struct.lyotstop, $ 
              ' specifies if the 2nd Lyot stop is in the beam'
  endif

  fxaddpar, newheader, 'OCCLTRID', occltrid, ' ID occulter'
  fxaddpar, newheader, 'MODLTRID', struct.modltrid, ' ID modulator'

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

  fxaddpar, newheader, 'RCAMID', rcamid, ' ' + run->epoch('rcamid_comment') 
  fxaddpar, newheader, 'TCAMID', tcamid, ' ' + run->epoch('tcamid_comment')  
  fxaddpar, newheader, 'RCAMLUT', rcamlut, ' ' + run->epoch('rcamlut_comment')
  fxaddpar, newheader, 'TCAMLUT', tcamlut, ' ' + run->epoch('tcamlut_comment')

  fxaddpar, newheader, 'SGSDIMV', struct.sgsdimv, $
            ' [V] SGS DIM signal mean', $
            format='(f9.4)', /null
  fxaddpar, newheader, 'SGSDIMS', struct.sgsdims, $
            ' [V] SGS DIM signal standard deviation', $
            format='(e11.3)', /null
  fxaddpar, newheader, 'SGSSUMV', struct.sgssumv, $
            ' [V] mean SGS sum signal', format='(f9.4)', /null
  fxaddpar, newheader, 'SGSSUMS',  struct.sgssums, $
            ' [V] SGS sum signal standard deviation', $
            format='(e11.3)', /null
  fxaddpar, newheader, 'SGSRAV', struct.sgsrav, $
            ' [V] mean SGS RA error signal', format='(e11.3)', /null
  fxaddpar, newheader, 'SGSRAS', struct.sgsras, $
            ' [V] mean SGS RA error standard deviation', $
            format='(e11.3)', /null
  if (check_sgsrazr ne 0) then begin
    fxaddpar, newheader, 'SGSRAZR', struct.sgsrazr, $
              ' [arcsec] SGS RA zeropoint offset', format='(f9.4)', /null
  endif
  fxaddpar, newheader, 'SGSDECV', struct.sgsdecv, $
            ' [V] mean SGS DEC error signal', format='(e11.3)', /null
  fxaddpar, newheader, 'SGSDECS',  struct.sgsdecs, $
            ' [V] mean SGS DEC error standard deviation', $
            format='(e11.3)', /null
  if (check_sgsdeczr ne 0) then begin
    fxaddpar, newheader, 'SGSDECZR', struct.sgsdeczr, $
              ' [arcsec] SGS DEC zeropoint offset', format='(f9.4)', /null
  endif
  fxaddpar, newheader, 'SGSSCINT', struct.sgsscint, $
            ' [arcsec] SGS scintillation seeing estimate', $
            format='(f9.4)', /null
  fxaddpar, newheader, 'SGSLOOP',  struct.sgsloop, ' SGS loop closed fraction'

  ; data citation URL
  fxaddpar, newheader, 'DATACITE', run->epoch('doi_url'), ' URL for DOI'

  fxaddpar, newheader, 'DUMMY', 1.0

  ; add headings
  fxaddpar, newheader, 'COMMENT', $
            comment_padding + 'HARDWARE MECHANISM KEYWORDS GROUPED BELOW', $
            before='DARKSHUT'
  fxaddpar, newheader, 'COMMENT', $
            comment_padding + 'COORDINATE SYSTEM KEYWORDS GROUPED BELOW', $
            before='WCSNAME'
  fxaddpar, newheader, 'COMMENT', $
            comment_padding + 'PROCESSING SOFTWARE KEYWORDS GROUPED BELOW', $
            before='QUALITY'
  fxaddpar, newheader, 'COMMENT', $
            comment_padding + 'SCALING KEYWORDS GROUPED BELOW', $
            before='BUNIT'
  fxaddpar, newheader, 'COMMENT', $
            comment_padding + 'CAMERA OCCULTING KEYWORDS GROUPED BELOW', $
            before='RCAMXCEN'
  fxaddpar, newheader, 'COMMENT', $
            comment_padding + 'EPHEMERAL KEYWORDS GROUPED BELOW', $
            before='RSUN_OBS'
  fxaddpar, newheader, 'COMMENT', $
            comment_padding + 'ENGINEERING KEYWORDS GROUPED BELOW', $
            before='O1FOCS'
  fxaddpar, newheader, 'COMMENT', $
            comment_padding + 'SPAR GUIDER SYSTEM KEYWORDS GROUPED BELOW', $
            before='SGSDIMV'
  
  ; instrument comments
  comments = ['The COSMO K-coronagraph is a 20-cm aperture, internally occulted', $
              'coronagraph, which observes the polarization brightness of the corona', $
              'with a field-of-view from ~1.05 to 3 solar radii in a wavelength range', $
              'from 720 to 750 nm. Nominal time cadence is 15 seconds.']
  comments = [mg_strwrap(strjoin(comments, ' '), width=72), '']

  fxaddpar, newheader, 'COMMENT', comments[0], after='DATACITE'
  for c = 1L, n_elements(comments) - 1L do begin
    fxaddpar, newheader, 'COMMENT', comments[c]
  endfor

  ; data processing comments
  history = ['Level 1.5 calibration and processing steps: dark current subtracted;', $
             'gain correction; apply polarization demodulation matrix; apply', $
             'distortion correction; align each camera to center, rotate to solar', $
             'north and combine cameras; coordinate transformation from cartesian', $
             'to tangential polarization; remove sky polarization; correct for', $
             'sky transmission.']
  history = mg_strwrap(strjoin(history, ' '), width=72)
  for h = 0L, n_elements(history) - 1L do sxaddhist, history[h], newheader

  sxdelpar, newheader, 'DUMMY'

  ; give a warning for NaN/infinite values in the final corona image
  !null = where(finite(corona) eq 0, n_nans)
  if (n_nans gt 0L) then begin
    mg_log, '%d NaN/Inf values in L1.5 FITS', n_nans, name=log_name, /warn
  endif

  ; write FITS image to disk
  writefits, filepath(l1_filename, root=l1_dir), corona, newheader

  ; write Helioviewer JPEG2000 image to a web accessible directory
  if (run->config('results/hv_basedir') ne '' && ~keyword_set(nomask)) then begin
    hv_kcor_write_jp2, scaled_image, newheader, $
                       run->config('results/hv_basedir'), $
                       log_name=log_name
  endif

  ; now make cropped GIF file
  kcor_cropped_gif, corona, run.date, date_struct, run=run, nomask=nomask, log_name=log_name
  
  ; create NRG (normalized, radially-graded) GIF image
  cd, l1_dir
  if (date_struct.second lt 15 and fix(date_struct.minute / 2) * 2 eq date_struct.minute $
        and ~keyword_set(nomask)) then begin
    kcor_nrgf, l1_filename, run=run, log_name=log_name
    mg_log, /check_math, name=log_name, /debug
    kcor_nrgf, l1_filename, /cropped, run=run, log_name=log_name
    mg_log, /check_math, name=log_name, /debug
  endif
  cd, l0_dir

  loop_time = toc(lclock)   ; save loop time
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
