; docformat = 'rst'

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
  vdimref = metadata.vdimref
  date = metadata.date
  file_list = metadata.file_list
  file_types = metadata.file_types

  sz = size(data.gain, /dimensions)

  cid = ncdf_create(outfile, /clobber, /netcdf4_format)
  ncdf_attput, cid, /global, 'title', 'COSMO K-Cor Calibration Data for ' + date
  ncdf_attput, cid, /global, 'epoch_version', run->epoch('cal_epoch_version')

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

  ; define variables
  filelistvar = ncdf_vardef(cid, 'Input File List', [filesdim], /string)
  filetypesvar = ncdf_vardef(cid, 'Input File Type', [filesdim], /string)
  darkvar = ncdf_vardef(cid, 'Dark', [xdim, ydim, beamdim], /float)
  gainvar = ncdf_vardef(cid, 'Gain', [xdim, ydim, beamdim], /float)
  dimrefvar = ncdf_vardef(cid, 'DIM Reference Voltage', [scalardim], /float)
  dimrefsigmavar = ncdf_vardef(cid, 'DIM Reference Voltage Standard Deviation', $
                               [scalardim], /float)
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
  ncdf_varput, cid, dimrefvar, vdimref
  ncdf_varput, cid, dimrefsigmavar, metadata.vdimref_sigma
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

  ; close the file
  ncdf_close, cid
end
