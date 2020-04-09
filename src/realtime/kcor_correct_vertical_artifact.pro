; docformat = 'rst'

;+
; Interpolate image on given columns from the pixels directly to the left and right.
;
; :Params:
;   im : in, out, required, type="fltarr(nx, ny, 4, 2)"
;     raw image to correct
;-
pro kcor_correct_vertical_artifact, im
  compile_opt strictarr

  dims = size(im, /dimensions)
  n_columns      = dims[0]
  n_rows         = dims[1]
  n_polstates    = dims[2]
  n_cameras      = dims[3]
  n_bad_columns  = 4L
  start_col      = n_columns / 2L - n_bad_columns
  end_col        = n_columns / 2L - 1L + n_bad_columns
  n_good_columns = 3L

  for c = 0L, n_cameras - 1L do begin
    for p = 0L, n_polstates - 1L do begin
      im[start_col:end_col, *, p, c] = !values.f_nan

      interp = mean(reform(im[start_col - n_good_columns:end_col + n_good_columns, $
                              *, $
                              p, $
                              c]), $
                    dimension=1, /nan)

      im[start_col:end_col, *, p, c] = rebin(reform(interp, 1, n_rows), $
                                             end_col - start_col + 1L, $
                                             n_rows)
    endfor
  endfor
end
