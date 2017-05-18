; docformat = 'rst'

;+
; Read the fit parameters from a camera correction file.
;
; :Returns:
;   fltarr(1024, 1024, 5)
;
; :Params:
;   filename : in, required, type=string
;     camera correction filename
;-
function kcor_read_camera_correction, filename
  compile_opt strictarr

  id = ncdf_open(filename)

  fit_params_varid = ncdf_varid(id, 'Fit Parameters')
  ncdf_varget, id, fit_params_varid, fit_params

  ncdf_close, id

  return, fit_params
end
