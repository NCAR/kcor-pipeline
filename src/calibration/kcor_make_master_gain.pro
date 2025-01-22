; docformat = 'rst'

;+
; Make a master gain file for a given cal epoch.
;
; :Params:
;   cal_epoch : in, required, type=string
;     cal epoch to compute the master gain for
;
; :Keywords:
;   run : in, required, type=object
;     KCor run object
;-
pro kcor_make_master_gain, cal_epoch, run=run
  compile_opt strictarr

  log_name = 'kcor/eod'

  cal_files = kcor_find_latest_cal_files(cal_epoch, count=n_cal_files, run=run)
  if (n_cal_files eq 0L) then begin
    mg_log, 'no cal files found in cal epoch %s', cal_epoch, $
            name=log_name, /warn
    goto, done
  endif
  
  nx = 1024L
  ny = 1024L
  n_cameras = 2L

  over_occulting_offset = 1.0

  cal_epoch_gains = fltarr(nx, ny, n_cameras, n_cal_files)

  for f = 0L, n_cal_files - 1L do begin
    unit = ncdf_open(cal_files[f])
    ncdf_varget, unit, 'Gain', gain
    ncdf_varget, unit, 'DIM Reference Voltage', flat_vdimref
    ncdf_varget, unit, 'Occulter ID', occulter_id
    ncdf_close, unit

    gain /= flat_vdimref

    ; set date/time to make epoch queries work
    cal_basename = file_basename(cal_files[f])
    run.date = strmid(cal_basename, 0, 8)
    run.time = strmid(cal_basename, 9, 6)

    occulter_size = kcor_get_occulter_size(occulter_id, run=run)  ; arcsec
    plate_scale = run->epoch('plate_scale')
    radius_guess = occulter_size / plate_scale

    ; find center and mask out occulter with NaNs
    for c = 0L, 1L do begin
      cam = reform(gain[*, *, c])

      info_cam = kcor_find_image(cam, radius_guess, log_name=log_name)

      x = rebin(reform(findgen(nx), nx, 1), nx, ny) - info_cam[0]
      y = rebin(reform(findgen(ny), 1, ny), nx, ny) - info_cam[1]
      r = sqrt(x^2 + y^2)

      occulter_indices = where(r lt (info_cam[2] + over_occulting_offset), /null)

      cam[occulter_indices] = !values.f_nan
      cal_epoch_gains[*, *, c, f] = cam
    endfor
  endfor

  master_gain = median(cal_epoch_gains, dimension=4)
  mean_gain = mean(cal_epoch_gains, dimension=4, /nan)
  stddev_gain = stddev(cal_epoch_gains, dimension=4, /nan)
  n_gain = total(long(finite(cal_epoch_gains)), 4, /preserve_type)

  ; kcor_master_gain_v[CAL_EPOCH]_[CODE_VERSION].ncdf
  code_version = kcor_find_code_version()
  output_basename = string(cal_epoch, code_version, $
                           format='kcor_master_gain_v%s_%s.ncdf')
  cal_dir = run->config('calibration/out_dir')
  output_filename = filepath(output_basename, root=cal_dir)

  kcor_write_master_gain, output_filename, $
                          master_gain, $
                          mean_gain, $
                          stddev_gain, $
                          n_gain
  done:
end


; main-level example program

date = '20240330'
config_basename = 'kcor.latest.cfg'
config_filename = filepath(config_basename, $
                           subdir=['..', '..', '..', 'kcor-config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename, mode='test')
cal_epoch = '10'

kcor_make_master_gain, cal_epoch, run=run

code_version = kcor_find_code_version()
master_gain_basename = string(cal_epoch, code_version, $
                              format='kcor_master_gain_v%s_%s.ncdf')
cal_dir = run->config('calibration/out_dir')
master_gain_filename = filepath(master_gain_basename, root=cal_dir)

master_gain = mg_nc_getdata(master_gain_filename, 'master_gain')
stddev_gain = mg_nc_getdata(master_gain_filename, 'stddev_gain')
n_gain = mg_nc_getdata(master_gain_filename, 'n_gain')

camera_names = ['RCAM', 'TCAM']
for c = 0L, n_elements(camera_names) - 1L do begin
  mg_image, bytscl(master_gain[*, *, c]), $
            /new, title=string(camera_names[c], format='%s Master gain')
  mg_image, bytscl(stddev_gain[*, *, c]), $
            /new, title=string(camera_names[c], format='%s Std dev of master gain')
  mg_image, bytscl(n_gain[*, *, c]), $
            /new, title=string(camera_names[c], format='%s Number of images in master gain')
endfor

obj_destroy, run

end
