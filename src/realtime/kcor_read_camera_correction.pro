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
;-
function kcor_read_camera_correction, filename, $
                                      bad_columns=bad_columns, $
                                      n_bad_columns=n_bad_columns, $
                                      bad_values=bad_values, $
                                      n_bad_values=n_bad_values
  compile_opt strictarr

  id = ncdf_open(filename)

  fit_params_varid = ncdf_varid(id, 'Fit Parameters')
  ncdf_varget, id, fit_params_varid, fit_params

  bad_pixel_mask_varid = ncdf_varid(id, 'Bad Pixel Mask')
  ncdf_varget, id, bad_pixel_mask_varid, bad_pixel_mask

  ncdf_close, id

  compute_bad_columns = arg_present(bad_columns) || arg_present(n_bad_columns)
  compute_bad_values = arg_present(bad_values) || arg_present(n_bad_values)

  if (compute_bad_columns || compute_bad_values) then begin
    dims = size(bad_pixel_mask, /dimensions)

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

  return, fit_params
end
