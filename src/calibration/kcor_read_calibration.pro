; docformat = 'rst'

;+
; Read calibration file.
;
; :Returns:
;   structure
;
; :Params:
;   file : in, required, type=string
;     filename of netCDF file to read
;-
function kcor_read_calibration, file
  compile_opt strictarr

  cid = ncdf_open(file)

  ; define variables
  filelistvar = ncdf_varid(cid, 'Input File List')
  filetypesvar = ncdf_varid(cid, 'Input File Type')
  darkvar = ncdf_varid(cid, 'Dark')
  gainvar = ncdf_varid(cid, 'Gain')
  dimrefvar = ncdf_varid(cid, 'DIM Reference Voltage')
  pixels0var = ncdf_varid(cid, 'Pixels Fit with Model for Beam 0')
  fits0var = ncdf_varid(cid, 'Model Fit Parameters for Beam 0')
  fiterrors0var = ncdf_varid(cid, 'Model Fit Parameters Formal Errors for Beam 0')
  pixels1var = ncdf_varid(cid, 'Pixels Fit with Model for Beam 1')
  fits1var = ncdf_varid(cid, 'Model Fit Parameters for Beam 1')
  fiterrors1var = ncdf_varid(cid, 'Model Fit Parameters Formal Errors for Beam 1')
  mmatvar = ncdf_varid(cid, 'Modulation Matrix')
  dmatvar = ncdf_varid(cid, 'Demodulation Matrix')

  ; done defining the netCDF file, write data
  ncdf_varget, cid, filelistvar, file_list
  ncdf_varget, cid, filetypesvar, file_types
  ncdf_varget, cid, darkvar, dark
  ncdf_varget, cid, gainvar, gain
  ncdf_varget, cid, dimrefvar, vdimref
  ncdf_varget, cid, pixels0var, pixels0
  ncdf_varget, cid, fits0var, fits0
  ncdf_varget, cid, fiterrors0var, fiterrors0
  ncdf_varget, cid, pixels1var, pixels1
  ncdf_varget, cid, fits1var, fits1
  ncdf_varget, cid, fiterrors1var, fiterrors1
  ncdf_varget, cid, mmatvar, mmat
  ncdf_varget, cid, dmatvar, dmat

  ; close the file
  ncdf_close, cid

  return, {file_list:file_list, file_types:file_types, $
           dark:dark, gain:gain, $
           vdimref:vdimref, $
           pixels0:pixels0, fits0:fits0, fiterrors0:fiterrors0, $
           pixels1:pixels1, fits1:fits1, fiterrors1:fiterrors1, $
           mmat:mmat, dmat:dmat}
end
