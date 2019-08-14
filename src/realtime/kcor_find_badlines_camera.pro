; docformat = 'rst'

;+
; Find indices of anomalous lines.
;
; :Returns:
;   `lonarr` of indices, `!null` if none
;
; :Params:
;   im : in, required, type="fltarr(nx, ny)"
;     coronal image from one camera to check
;-
function kcor_find_badlines_camera, corona
  compile_opt strictarr

  meds = median(corona, dimension=1)

  n = 5
  kernel = fltarr(n) - 1.0 / (n - 1)
  kernel[n / 2] = 1.0

  ; number of lines to skip at the top and bottom of the image
  n_skip = 3

  diffs = convol(meds[n_skip:-n_skip-1], kernel, /edge_truncate)
  bad_lines = where(diffs gt 25.0, n_bad_lines, /null)
  if (n_bad_lines gt 0L) then bad_lines += n_skip

  return, bad_lines
end
