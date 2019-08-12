; docformat = 'rst'

;+
; Interpolate/filter over bad pixels.
;
; :Returns:
;   array of same type and dimensions as `im`
;
; :Params:
;   im : in, required, type="arr(m, n)"
;     2-dimensional array of any numeric type with bad values given by
;     `badpixels`
;   bad_pixels : in, required, type=lonarr
;     indices of bad pixels
;
; :Keywords:
;   width : in, optional, type=integer, default=11
;     width/height of kernel
;-
function kcor_fix_badpixels, im, bad_pixels, width=width
  compile_opt strictarr

  if (n_elements(bad_pixels) eq 0L) then return, im

  result = im

  ; mark the bad pixels with NaNs
  result[bad_pixels] = !values.f_nan

  filtered = estimator_filter(result, n_elements(width) eq 0L ? 11 : width, /nan)

  ; ESIMATOR_FILTER changes all the values of the array, not just the bad
  ; pixels, but only want to use the estimated pixels for the bad values
  result[bad_pixels] = filtered[bad_pixels]

  return, result
end
