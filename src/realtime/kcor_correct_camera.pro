; docformat = 'rst'

;+
; Corrects nonlinear camera.
;
; :Params:
;   im : in, required, type="uint(1024, 1024)"
;     image to correct
;   header : in, required, type=strarr
;     FITS header for `im`
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;-
function kcor_correct_camera, im, header, numsum, run=run
  compile_opt strictarr

  return, im
end
