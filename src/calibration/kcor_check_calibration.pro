; docformat = 'rst'

;+
; Check polarization states to make sure they are in the correct order.
;
; Only need to check one camera since polarization is before the beam-splitter,
; which  ensure both cameras get the same polarization.
;
; :Returns:
;   0 (for failure) or 1 (for success)
;
; :Params:
;   im : in, required, type="uintarr(nx, ny, npol_states, ncameras)"
;     0 degree polarization calibration image
;
; :Keywords:
;   start_state : out, optional, type=integer
;     set to a named variable to retrieve the suggested `start_state`
;-
function kcor_check_calibration, im, start_state=start_state
  compile_opt strictarr

  check_camera = 0

  mean_states = mean(mean(im[*, *, *, check_camera], dimension=1), dimension=1)
  mean_order = sort(mean_states)

  ; the correct order is half-plus, high, low, half-minus
  correct_order = [2, 3, 0, 1]
  if (array_equal(mean_order, correct_order)) then begin
    start_state = 0L
    return, 1B
  endif else begin
    ; mean_order -> start_state
    ; 2, 3, 0, 1 -> 0
    ; 3, 0, 1, 2 -> 3
    ; 0, 1, 2, 3 -> 2
    ; 1, 2, 3, 0 -> 1
    ; any other order -> -1
    start_state = (where(mean_order eq correct_order[0]))[0]
    print, mean_order
    print, start_state
    if (~array_equal(shift(mean_order, -start_state), correct_order)) then begin
      start_state = -1L
    endif
    return, 0B
  endelse
end


; main-level example program

root = '/hao/mlsodata1/Data/KCor/raw/20201018/level0'
basename = '20201018_201418_kcor.fts.gz'

; root = '/hao/mlsodata1/Data/KCor/raw/20201024/level0'
; basename = '20201024_174906_kcor.fts.gz'

; root = '/hao/mlsodata1/Data/KCor/raw/20201020/level0'
; basename = '20201020_214258_kcor.fts.gz'

filename = filepath(basename, root=root)
im = readfits(filename, header, /silent)

status = kcor_check_calibration(im, start_state=start_state)
print, status ? 'Good' : 'Bad', start_state, format='(%"%s: suggested start_state=%d")'

end
