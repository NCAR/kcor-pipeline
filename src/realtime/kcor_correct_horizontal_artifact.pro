; docformat = 'rst'

;+
; Interpolate image on given lines from the pixels directly above and below.
;
; :Params:
;   im : in, out, required, type="fltarr(nx, ny, 4, 2)"
;     raw image to correct
;   lines : in, required, type=lonarr
;     horizontal lines to correct
;   cameras : in, required, type=lonarr
;     cameras to correct, either `!null`, `[0]`, `[1]`, or `[0, 1]`
;-
pro kcor_correct_horizontal_artifact, im, lines, cameras
  compile_opt strictarr

  dims = size(im, /dimensions)

  for l = 0L, n_elements(lines) - 1L do begin
    for p = 0L, dims[2] - 1L do begin
      for c = 0L, n_elements(cameras) - 1L do begin
        im[*, lines[l], p, cameras[c]] = !values.f_nan
        interp = mean(reform(im[*, $
                                (lines[l] - 1) > 0:(lines[l] + 1) < (dims[1] - 1), $
                                p, $
                                cameras[c]]), $
                      dimension=2, /nan)
        im[*, lines[l], p, cameras[c]] = interp
      endfor
    endfor
  endfor
end
