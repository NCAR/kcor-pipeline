; docformat = 'rst'

;+
; Given a list of bad lines and the median values, determine the actual bad
; lines. There are artifacts in lines of nearby bad lines, so the worst in each
; continuous block of bad lines is used.
;
; :Returns:
;   `lonarr` of list of bad lines or `!null` if none
;
; :Params:
;   bad_lines : in, required, type=lonarr
;     list of original bad lines, may be `!null` if there are no bad lines
;   medians : in, required, type=lonarr
;     medians of each line in the corona
;-
function kcor_filter_badlines, bad_lines, medians, count=n_labels
  compile_opt strictarr

  if (n_elements(bad_lines) eq 0L) then return, bad_lines

  mask = bytarr(n_elements(medians))
  mask[bad_lines] = 1B

  labels = label_region(mask)
  n_labels = max(labels)
  worse_lines = lonarr(n_labels)

  for r = 1L, n_labels do begin
    ind = where(labels eq r, count)
    if (count gt 0L) then begin
      !null = max(medians[ind], max_index)
      worse_lines[r - 1L] = ind[max_index]
    endif
  endfor

  return, worse_lines
end
