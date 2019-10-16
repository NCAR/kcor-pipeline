; docformat = 'rst'

;+
; Correct lines for a given 1024x1024 image.
;
; :Params:
;   im : in, out, required, type="fltarr(nx, ny, 4, 2)"
;     raw image to correct
;   lines : in, required, type=lonarr
;     horizontal lines to correct
;   pol_state : in, required, type=integer
;     pol state index to correct in `im`: 0, 1, 2, or 3
;   camera : in, required, type=integer
;     camera index to correct in `im`: 0 or 1
;-
pro kcor_correct_horizontal_artifact_image, im, lines, pol_state, camera
  compile_opt strictarr

  dims = size(im, /dimensions)
  _im = float(im)

  for l = 0L, n_elements(lines) - 1L do begin
    _im[*, lines[l], pol_state, camera] = !values.f_nan
    interp = mean(reform(_im[*, $
                             (lines[l] - 1) > 0:(lines[l] + 1) < (dims[1] - 1), $
                             pol_state, $
                             camera]), $
                  dimension=2, /nan)

    _im[*, lines[l], pol_state, camera] = interp
  endfor

  im = fix(_im, type=size(im, /type))
end


;+
; Interpolate image on given lines from the pixels directly above and below.
;
; Note: current method will not work on lines 0 or 1023.

; :Params:
;   im : in, out, required, type="fltarr(nx, ny, 4, 2)"
;     raw image to correct
;   cam0_lines : in, required, type=lonarr
;     horizontal lines to correct in camera 0
;   cam1_lines : in, required, type=lonarr
;     horizontal lines to correct in camera 1
;-
pro kcor_correct_horizontal_artifact, im, cam0_lines, cam1_lines
  compile_opt strictarr

  dims = size(im, /dimensions)
  n_pol_states = dims[2]

  for p = 0L, n_pol_states - 1L do begin
    kcor_correct_horizontal_artifact_image, im, cam0_lines, p, 0
    kcor_correct_horizontal_artifact_image, im, cam1_lines, p, 1
  endfor
end
