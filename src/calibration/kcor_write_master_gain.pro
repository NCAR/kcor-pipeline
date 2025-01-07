; docformat = 'rst'

;+
; Write a netCDF master gain file.
;
; :Params:
;   output_filename : in, required, type=string
;     filename of netCDF file to write
;   master_gain : in, required, type="fltarr(nx, ny, n_cameras)"
;     median of all gains in cal epoch (masked by occulter in each gain)
;   mean_gain : in, required, type="fltarr(nx, ny, n_cameras)"
;     mean of all gains in cal epoch (masked by occulter in each gain)
;   stddev_gain : in, required, type="fltarr(nx, ny, n_cameras)"
;     stddev of all gains in cal epoch (masked by occulter in each gain)
;   n_gain : in, required, type="lonarr(nx, ny, n_cameras)"
;     number of gains in cal epoch (masked by occulter in each gain)
;-
pro kcor_write_master_gain, output_filename, $
                            master_gain, $
                            mean_gain, $
                            stddev_gain, $
                            n_gain
  compile_opt strictarr

  cid = ncdf_create(output_filename, /clobber, /netcdf4_format)
  version = kcor_find_code_version(revision=revision, date=code_date)
  ncdf_attput, cid, /global, $
               'version', string(version, revision, $
                                 format='(%"%s [%s]")')

  dims = size(master_gain, /dimensions)

  x_dim = ncdf_dimdef(cid, 'x', dims[0])
  y_dim = ncdf_dimdef(cid, 'y', dims[1])
  camera_dim = ncdf_dimdef(cid, 'camera', dims[2])

  master_gain_var = ncdf_vardef(cid, 'master_gain', [x_dim, y_dim, camera_dim], /float)
  mean_gain_var = ncdf_vardef(cid, 'mean_gain', [x_dim, y_dim, camera_dim], /float)
  stddev_gain_var = ncdf_vardef(cid, 'stddev_gain', [x_dim, y_dim, camera_dim], /float)
  n_gain_var = ncdf_vardef(cid, 'n_gain', [x_dim, y_dim, camera_dim], /long)

  ncdf_varput, cid, master_gain_var, master_gain
  ncdf_varput, cid, mean_gain_var, mean_gain
  ncdf_varput, cid, stddev_gain_var, stddev_gain
  ncdf_varput, cid, n_gain_var, n_gain

  ncdf_close, cid
end
