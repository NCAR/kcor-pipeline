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
function kcor_find_badlines_camera, corona, $
                                    diff_threshold=diff_threshold, $
                                    kernel_width=kernel_width
  compile_opt strictarr

  meds = median(corona, dimension=1)

  _diff_threshold = n_elements(diff_threshold) eq 0L ? 25.0 : diff_threshold

  n = n_elements(kernel_width) eq 0L ? 5 : kernel_width
  kernel = fltarr(n) - 1.0 / (n - 1)
  kernel[n / 2] = 1.0

  ; number of lines to skip at the top and bottom of the image
  n_skip = 3

  diffs = convol(meds[n_skip:-n_skip-1], kernel, /edge_truncate)
  bad_lines = where(diffs gt _diff_threshold, n_bad_lines, /null)
  ;if (n_bad_lines eq 0L) then begin
  ;  max_value = max(diffs, max_index)
  ;  print, max_value, max_index + 3, format='(%"  %0.3f @ %d")'
  ;endif
  if (n_bad_lines gt 0L) then bad_lines += n_skip

  return, bad_lines
end


; main-level example program

f = filepath('20190625_174555_kcor.fts.gz', $
             subdir=['20190625', 'level0'], $
             root='/hao/sunset/Data/KCor/raw.latest')

im = readfits(f, heade)
corona1 = kcor_corona(im[*, *, *, 1]
cam1_badlines = kcor_find_badlines_camera(corona1, diff_threshold=20.0)

end
