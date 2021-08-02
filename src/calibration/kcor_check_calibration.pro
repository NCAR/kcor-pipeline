; docformat = 'rst'

;+
; Check polarization states to make sure they are in the correct order.
;
; :Returns:
;   0 (for failure) or 1 (for success)
;
; :Params:
;   im : in, required, type="uintarr(nx, ny, npol_states, ncameras)"
;     0 degree polarization calibration image
;
; :Keywords:
;   start_state : out, optional, type=lonarr(2)
;     set to a named variable to retrieve the suggested `start_state`
;-
function kcor_check_calibration, im, start_state=start_state
  compile_opt strictarr

  start_state = lonarr(2)
  is_valid = 1B

  ; the correct order for camera 0 is half-plus, high, low, half-minus
  ; the correct order for camera 1 is half-minus, low, high, half-plus
  correct_order = [[2, 3, 0, 1], [1, 0, 3, 2]]

  for check_camera = 0L, 1L do begin
    mean_states = mean(mean(im[*, *, *, check_camera], dimension=1), dimension=1)
    mean_order = sort(mean_states)

    if (array_equal(mean_order, correct_order[*, check_camera])) then begin
      start_state[check_camera] = 0L
    endif else begin
      ; mean_order -> start_state
      ; 2, 3, 0, 1 -> 0
      ; 3, 0, 1, 2 -> 3
      ; 0, 1, 2, 3 -> 2
      ; 1, 2, 3, 0 -> 1
      ; any other order -> -1
      start_state[check_camera] = (where(mean_order eq correct_order[0, check_camera]))[0]
      if (~array_equal(shift(mean_order, -start_state[check_camera]), correct_order[*, check_camera])) then begin
        start_state[check_camera] = -1L
      endif
      is_valid = 0B
    endelse
  endfor
  return, is_valid
end


; main-level example program

root = '/hao/dawn/Data/KCor/raw/20201018/level0'
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
