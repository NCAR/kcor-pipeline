; docformat = 'rst'

;+
; Find the indices of the base elements where there was change from the element
; on their left, but no change for `n_without_change` elements to the right
; (including themselves)
;
; :Returns:
;   `lonarr` of indices into `ra_offsets` and `dec_offsets` or `!null` if none
;   found
;
; :Params:
;   ra_offsets : in, required, type=fltarr(n)
;     RA offsets
;   dec_offsets : in, required, type=fltarr(n)
;     DEC offsets
;
; :Keywords:
;   n_without_change : in, optional, type=integer, default=3
;     number of elements in a row without a change to qualify as a new base
;     index
;-
function kcor_find_basefiles, ra_offsets, dec_offsets, $
                              n_without_change=n_without_change
  compile_opt strictarr

  n = n_elements(ra_offsets)

  ; find changes in RA and DEC
  ra_diffs = ra_offsets[1:*] - ra_offsets[0:-2]
  dec_diffs = dec_offsets[1:*] - dec_offsets[0:-2]

  ; assume we always start and end with a change -- adding the start change
  ; makes the change values have the same index as the element in RA or DEC that
  ; is changing or not
  diffs = [1B, ra_diffs ne 0.0 or dec_diffs ne 0.0, 1B]

  ; how many elements in a row need to be the same to consider this a new base?
  _n_without_change = n_elements(n_without_change) eq 0L ? 3 : n_without_change
  kernel = bytarr(2 * _n_without_change - 1) + 1B
  kernel[0:_n_without_change - 1] = 0B

  ; how many changes in the next `n_without_change - 1` elements? e.g., there
  ; are 2 opportunities for change in 3 elements
  future_changes = convol(diffs, kernel, /edge_truncate)

  ; find the indices of the elements that change from the element on their left,
  ; but don't change without `n_without_change - 1` elements on their right
  diff_indices = where(diffs ne 0L and future_changes eq 0L, n_diffs, /null)

  return, diff_indices
end


; main-level example program

ra_offsets  = [ 15.0,  15.0,  20.0,  25.0,  25.0,  25.0,  25.0,  25.0, $
                15.0,  15.0,  20.0,  25.0,  25.0,  25.0,  25.0,  25.0, $
                15.0,  15.0,  20.0,  25.0,  25.0]
dec_offsets = [-15.0, -20.0, -20.0, -20.0, -20.0, -20.0, -20.0, -20.0, $ 
               -15.0, -20.0, -20.0, -20.0, -20.0, -20.0, -20.0, -20.0, $
               -15.0, -20.0, -20.0, -20.0, -20.0]

print, kcor_find_basefiles(ra_offsets, dec_offsets)

end
