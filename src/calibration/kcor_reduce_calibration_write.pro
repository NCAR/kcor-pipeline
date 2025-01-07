; docformat = 'rst'

;+
; Find centering information for a gain.
;
; :Returns:
;   `fltarr(3)` where elements are x-center, y-center, and radius
;
; :Params:
;   gain : in, required, type="fltarr(nx, ny)"
;
; :Keywords:
;   run : in, required, type=object
;     KCor run object
;-
function kcor_reduce_calibration_write_centering, gain, run=run
  compile_opt strictarr

  radius_guess = 178   ; average radius for occulter
  center_offset = run->config('realtime/center_offset')

  center_info = kcor_find_image(gain, $
                                radius_guess, $
                                ; /center_guess, $
                                ; xoffset=center_offset[0], $
                                ; yoffset=center_offset[1], $
                                ; max_center_difference=run->epoch('max_center_difference'), $
                                log_name='kcor/eod')

  return, center_info
end


;+
; Write a calibration netCDF file.
;
; :Params:
;   data : in, required, type=structure
;     structure with dark and gain fields, as returned from
;     `KCOR_REDUCE_CALIBRATION_READ` 
;   metadata : in, required, type=structure
;     structure with vdimref, date, file_list, and file_types fields, as
;     returned from `KCOR_REDUCE_CALIBRATION_READ`
;   mmat
;   dmat
;   outfile : in, required, type=string
;     filename of output netCDF file
;   pixels0
;   fits0
;   fiterrors0
;   pixels1
;   fits1
;   fiterrors1
;
; :Keywords:
;   run : in, optional, type=object
;     `kcor_run` object; `config_filename` or `run` is required
;-
pro kcor_reduce_calibration_write, data, metadata, $
                                   mmat, dmat, outfile, $
                                   pixels0, fits0, fiterrors0, $
                                   pixels1, fits1, fiterrors1, run=run
  compile_opt strictarr

  dark = data.dark
  gain = data.gain
  npick = run->config('calibration/npick')
  vdimref = metadata.vdimref
  date = metadata.date
  file_list = metadata.file_list
  file_types = metadata.file_types

  ; compute distortion-corrected gain
  rcam_gain = reform(gain[*, *, 0])
  rcam_gain = reverse(rcam_gain, 2)
  tcam_gain = reform(gain[*, *, 1])

  raw_rcam_centering_info = kcor_reduce_calibration_write_centering(rcam_gain, run=run)
  raw_tcam_centering_info = kcor_reduce_calibration_write_centering(tcam_gain, run=run)

  mg_log, 'Raw RCAM gain, x: %0.2f, y: %0.2f, radius: %0.3f', $
          raw_rcam_centering_info, name='kcor/eod', /debug
  mg_log, 'Raw TCAM gain, x: %0.2f, y: %0.2f, radius: %0.3f', $
          raw_tcam_centering_info, name='kcor/eod', /debug

  dc_path = filepath(run->epoch('distortion_correction_filename'), $
                     root=run.resources_dir)
  restore, dc_path   ; distortion correction coeffs: dx1_c, dy1_c, dx2_c, dy2_c
  kcor_apply_dist, rcam_gain, tcam_gain, dx1_c, dy1_c, dx2_c, dy2_c

  dc_rcam_centering_info = kcor_reduce_calibration_write_centering(rcam_gain, run=run)
  dc_tcam_centering_info = kcor_reduce_calibration_write_centering(tcam_gain, run=run)

  mg_log, 'Distortion-corrected RCAM gain, x: %0.2f, y: %0.2f, radius: %0.3f', $
          dc_rcam_centering_info, name='kcor/eod', /debug
  mg_log, 'Distortion-corrected TCAM gain, x: %0.2f, y: %0.2f, radius: %0.3f', $
          dc_tcam_centering_info, name='kcor/eod', /debug

  dc_gain = [[[rcam_gain]], [[tcam_gain]]]

  sz = size(data.gain, /dimensions)

  cid = ncdf_create(outfile, /clobber, /netcdf4_format)
  ncdf_attput, cid, /global, 'title', 'COSMO K-Cor Calibration Data for ' + date
  ncdf_attput, cid, /global, 'epoch_version', run->epoch('cal_epoch_version')
  ncdf_attput, cid, /global, 'flat-date-obs', metadata.flat_date_obs

  version = kcor_find_code_version(revision=revision, date=code_date)
  ncdf_attput, cid, /global, $
               'version', string(version, revision, $
                                 format='(%"%s [%s]")')

  ; define dimensions
  filesdim = ncdf_dimdef(cid, 'Number of Files', n_elements(file_list))
  pixels0dim = ncdf_dimdef(cid, 'Number of Pixels for Beam 0', n_elements(pixels0) / 2)
  pixels1dim = ncdf_dimdef(cid, 'Number of Pixels for Beam 1', n_elements(pixels1) / 2)
  scalardim = ncdf_dimdef(cid, 'scalar', 1)
  vectordim = ncdf_dimdef(cid, '2-vector', 2)
  paramsdim = ncdf_dimdef(cid, 'Number of Model Parameters', 17)
  xdim = ncdf_dimdef(cid, 'x', sz[0])
  ydim = ncdf_dimdef(cid, 'y', sz[1])
  beamdim = ncdf_dimdef(cid, 'beam', 2)
  stokesdim = ncdf_dimdef(cid, 'Stokes IQU', 3)
  statedim = ncdf_dimdef(cid, 'state', 4)
  npickdim = ncdf_dimdef(cid, 'NPick', 3)

  ; define variables
  filelistvar = ncdf_vardef(cid, 'Input File List', [filesdim], /string)
  filetypesvar = ncdf_vardef(cid, 'Input File Type', [filesdim], /string)
  darkvar = ncdf_vardef(cid, 'Dark', [xdim, ydim, beamdim], /float)

  dc_gainvar = ncdf_vardef(cid, 'Distortion-Corrected Gain', [xdim, ydim, beamdim], /float)
  ncdf_attput, cid, dc_gainvar, 'RCAM x-center', dc_rcam_centering_info[0]
  ncdf_attput, cid, dc_gainvar, 'RCAM y-center', dc_rcam_centering_info[1]
  ncdf_attput, cid, dc_gainvar, 'RCAM radius', dc_rcam_centering_info[2]
  ncdf_attput, cid, dc_gainvar, 'TCAM x-center', dc_tcam_centering_info[0]
  ncdf_attput, cid, dc_gainvar, 'TCAM y-center', dc_tcam_centering_info[1]
  ncdf_attput, cid, dc_gainvar, 'TCAM radius', dc_tcam_centering_info[2]

  gainvar = ncdf_vardef(cid, 'Gain', [xdim, ydim, beamdim], /float)
  ncdf_attput, cid, gainvar, 'RCAM x-center', raw_rcam_centering_info[0]
  ncdf_attput, cid, gainvar, 'RCAM y-center', raw_rcam_centering_info[1]
  ncdf_attput, cid, gainvar, 'RCAM radius', raw_rcam_centering_info[2]
  ncdf_attput, cid, gainvar, 'TCAM x-center', raw_tcam_centering_info[0]
  ncdf_attput, cid, gainvar, 'TCAM y-center', raw_tcam_centering_info[1]
  ncdf_attput, cid, gainvar, 'TCAM radius', raw_tcam_centering_info[2]

  dimrefvar = ncdf_vardef(cid, 'DIM Reference Voltage', [scalardim], /float)
  dimrefsigmavar = ncdf_vardef(cid, 'DIM Reference Voltage Standard Deviation', $
                               [scalardim], /float)
  dimocculteridvar = ncdf_vardef(cid, 'Occulter ID', [scalardim], /string)
  dimnumsum = ncdf_vardef(cid, 'numsum', [scalardim], /long)

  dimexptime = ncdf_vardef(cid, 'exptime', [scalardim], /float)
  ncdf_attput, cid, dimrefvar, 'units', 'V'

  pixels0var = ncdf_vardef(cid, 'Pixels Fit with Model for Beam 0', $
                           [vectordim, pixels0dim], /short)
  fits0var = ncdf_vardef(cid, 'Model Fit Parameters for Beam 0', $
                         [paramsdim, pixels0dim], /float)
  fiterrors0var = ncdf_vardef(cid, 'Model Fit Parameters Formal Errors for Beam 0', $
                              [paramsdim, pixels0dim], /float)
  pixels1var = ncdf_vardef(cid, 'Pixels Fit with Model for Beam 1', $
                           [vectordim, pixels1dim], /short)
  fits1var = ncdf_vardef(cid, 'Model Fit Parameters for Beam 1', $
                         [paramsdim, pixels1dim], /float)
  fiterrors1var = ncdf_vardef(cid, 'Model Fit Parameters Formal Errors for Beam 1', $
                              [paramsdim, pixels1dim], /float)
  mmatvar = ncdf_vardef(cid, 'Modulation Matrix', $
                        [xdim, ydim, beamdim, stokesdim, statedim], /float)
  dmatvar = ncdf_vardef(cid, 'Demodulation Matrix', $
                        [xdim, ydim, beamdim, statedim, stokesdim], /float)
  lyotstop_var = ncdf_vardef(cid, 'lyotstop', [scalardim], /string)
  npick_var = ncdf_vardef(cid, 'NPick', [scalardim], /long)

  if filelistvar eq -1 or filetypesvar eq -1 or darkvar eq -1 or gainvar eq -1 or $
      dimrefvar eq -1 or fits0var eq -1 or fits1var eq -1 or $
      fiterrors0var eq -1 or fiterrors1var eq -1 or $
      mmatvar eq -1 or dmatvar eq -1 then $
          message, 'Something went wrong while attempting to create the NetCDF output file.'

  ; done defining the NetCDF file, write data
  ncdf_control, cid, /endef
  ncdf_varput, cid, filelistvar, file_list
  ncdf_varput, cid, filetypesvar, file_types
  ncdf_varput, cid, darkvar, dark
  ncdf_varput, cid, gainvar, gain
  ncdf_varput, cid, dc_gainvar, dc_gain
  ncdf_varput, cid, dimrefvar, vdimref
  ncdf_varput, cid, dimrefsigmavar, metadata.vdimref_sigma
  ncdf_varput, cid, dimocculteridvar, metadata.occulter_id
  ncdf_varput, cid, dimnumsum, metadata.numsum
  ncdf_varput, cid, dimexptime, metadata.exptime
  ncdf_varput, cid, lyotstop_var, metadata.lyotstop
  ncdf_varput, cid, mmatvar, mmat
  ncdf_varput, cid, dmatvar, dmat
  ncdf_varput, cid, pixels0var, pixels0
  ncdf_varput, cid, fits0var, fits0
  ncdf_varput, cid, fiterrors0var, fiterrors0
  ncdf_varput, cid, pixels1var, pixels1
  ncdf_varput, cid, fits1var, fits1
  ncdf_varput, cid, fiterrors1var, fiterrors1
  ncdf_varput, cid, npick_var, npick

  ; close the file
  ncdf_close, cid
end
