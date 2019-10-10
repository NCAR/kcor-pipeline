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

  ; TODO: need to play around with this threshold
  diff_threshold = 40.0

  col_diff_kernel = fltarr(3, 3)
  col_diff_kernel[1, *] = [-0.5, 1.0, -0.5]
  col_diffs = convol(corona, col_diff_kernel)

  means = mean(abs(col_diffs), dimension=1)

  n = 5
  kernel = fltarr(n) - 1.0 / (n - 1)
  kernel[n / 2] = 1.0

  ; number of lines to skip at the top and bottom of the image
  n_skip = 3

  bad_lines = where(means[n_skip:-n_skip-1] gt diff_threshold, $
                    n_bad_lines, /null)

  ; need to add bad the index offset for the skipping lines
  if (n_bad_lines gt 0L) then bad_lines += n_skip

  ; if multiple bad lines found, take the worst one in each contiguous block of
  ; bad lines
  if (n_bad_lines gt 1L) then begin
    dims = size(corona, /dimensions)
    mask = bytarr(dims[1])
    mask[bad_lines] = 1B
    labels = label_region(mask)
    n_labels = max(labels)
    worse_lines = lonarr(n_labels)

    for r = 1L, n_labels do begin
      ind = where(labels eq r, count)
      if (count gt 0L) then begin
        !null = max(means[ind], max_index)
        worse_lines[r - 1L] = ind[max_index]
      endif
    endfor

    bad_lines = worse_lines
  endif

  return, bad_lines
end
