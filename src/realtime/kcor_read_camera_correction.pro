; docformat = 'rst'

;+
; Read the fit parameters from a camera correction file.
;
; :Returns:
;   fltarr(1024, 1024, 5)
;
; :Params:
;   filename : in, required, type=string
;     camera correction filename for netCDF file
;   cache_filename : in, required, type=string
;     cache of mask info `.sav` file corresponding to the `filename`
;
; :Keywords:
;   bad_columns : out, optional, type=lonarr
;     array of indices of the bad columns
;   n_bad_columns : out, optional, type=long
;     number of bad columns
;   bad_values : out, optional, type=lonarr
;     array of indices of the individual bad values; indices are ino the full
;     1024 by 1024 array
;   n_bad_values : out, optional, type=long
;     number of individual bad values
;   interpolate : in, optional, type=boolean
;     set to interpolate over bad values (not bad columns)
;-
function kcor_read_camera_correction, filename, $
                                      cache_filename, $
                                      bad_columns=bad_columns, $
                                      n_bad_columns=n_bad_columns, $
                                      bad_values=bad_values, $
                                      n_bad_values=n_bad_values, $
                                      mask=bad_pixel_mask, $
                                      interpolate=interpolate
  compile_opt strictarr

  if (file_test(cache_filename, /regular)) then begin
    restore, filename=cache_filename
  endif else begin
    id = ncdf_open(filename)

    fit_params_varid = ncdf_varid(id, 'Fit Parameters')
    ncdf_varget, id, fit_params_varid, fit_params

    bad_pixel_mask_varid = ncdf_varid(id, 'Bad Pixel Mask')
    ncdf_varget, id, bad_pixel_mask_varid, bad_pixel_mask

    ncdf_close, id

    compute_bad_columns = arg_present(bad_columns) || arg_present(n_bad_columns)
    compute_bad_values = arg_present(bad_values) $
                           || arg_present(n_bad_values) $
                           || keyword_set(interpolate)

    if (compute_bad_columns || compute_bad_values) then begin
      dims = size(bad_pixel_mask, /dimensions)

      bad_pixel_mask or= (fit_params[*, *, 4] gt 1.0) or (fit_params[*, *, 4] lt -1.0)

      ; number of bad pixels in a column to call it a bad column
      bad_column_max = dims[1]

      bad_pixels_by_column = total(bad_pixel_mask, 2, /integer)
      bad_columns = where(bad_pixels_by_column ge bad_column_max, $
                          n_bad_columns)

      ; find individual bad values if needed
      if (compute_bad_values) then begin
        fixable_column_mask = bytarr(dims[0]) + 1B
        fixable_column_mask[bad_columns] = 0B
        fixable_column_mask = rebin(reform(fixable_column_mask, dims[0], 1), $
                                    dims[0], dims[1])

        bad_values = where(bad_pixel_mask and fixable_column_mask, n_bad_values)
      endif
    endif

    if (keyword_set(interpolate)) then begin
      fit_dims = size(fit_params, /dimensions)

      width = 21
      kernel = fltarr(width, width) + 1.0
      c = width / 2
      kernel[c - 2:c + 2, c - 2:c + 2] = 0.0

      for f = 0L, fit_dims[2] - 1L do begin
        k = reform(fit_params[*, *, f])
        k1 = convol(k, kernel, /center, /normalize, /edge_truncate)
        k[bad_values] = k1[bad_values]
        fit_params[*, *, f] = k
      endfor
    endif

    if (cache_filename ne '') then begin
      cache_dirname = file_dirname(cache_filename)
      if (~file_test(cache_dirname, /directory)) then file_mkdir, cache_dirname

      save, fit_params, $
            bad_columns, $
            n_bad_columns, $
            bad_values, $
            n_bad_values, $
            bad_pixel_mask, $
            filename=cache_filename
    endif
  endelse

  return, fit_params
end


; main-level example program

basename = 'camera_calibration_MV-D1024E-CL-13890_02.5000_lut20160716-13890.ncdf'
filename = filepath(basename, root='/home/mgalloy/Downloads')
print, 'reading uncorrected camera correction...'
uncorrected_fit = kcor_read_camera_correction(filename, bad_values=bad_values, mask=mask)
print, 'reading corrected camera correction...'
corrected_fit = kcor_read_camera_correction(filename, /interpolate)

uncorrected_k0 = reform(uncorrected_fit[*, *, 4])
corrected_k0 = reform(corrected_fit[*, *, 4])

mg_image, bytscl(corrected_k0, -10.0, 10.0), /new, title='Corrected'
write_png, 'corrected.png', tvrd(true=1)

mg_image, bytscl(uncorrected_k0, -10.0, 10.0), /new, title='Uncorrected'
write_png, 'uncorrected.png', tvrd(true=1)

mg_image, bytscl(uncorrected_k0, -10.0, 10.0), /new, title='Bad values'
b_values = where(mask)
xy = array_indices(corrected_k0, b_values)
plots, xy[0, *], xy[1, *], /device, color='0000ff'x, psym=3
write_png, 'bad.png', tvrd(true=1)

end
