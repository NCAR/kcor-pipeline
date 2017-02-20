; docformat = 'rst'

;+
; Apply distortion correction to the sub-images `dat1` and `dat2` given the
; distortion coefficients.
;
; :Params:
;   dat1 : in, required, type=array
;     image from camera 0
;   dat1 : in, required, type=array
;     image from camera 1
;   dx1_c : in, required, type="fltarr(4, 4)"
;     x-coefficents for camera 0 image
;   dy1_c : in, required, type="fltarr(4, 4)"
;     y-coefficents for camera 0 image
;   dx2_c : in, required, type="fltarr(4, 4)"
;     x-coefficents for camera 1 image
;   dy2_c : in, required, type="fltarr(4, 4)"
;     y-coefficents for camera 1 image
;-
pro kcor_apply_dist, dat1, dat2, dx1_c, dy1_c, dx2_c, dy2_c
  compile_opt strictarr

  s = size(dat1)
  nx = s[1]

  x = rebin(findgen(nx), nx, nx)
  y = transpose(x)

  dat1 = interpolate(dat1, $
                     x + kcor_eval_surf(dx1_c, x, y), $
                     y + kcor_eval_surf(dy1_c, x, y), $
                     cubic=-0.5, missing=0.)
  dat2 = interpolate(dat2, $
                     x + kcor_eval_surf(dx2_c, x, y), $
                     y + kcor_eval_surf(dy2_c, x, y), $
                     cubic=-0.5, missing=0.)
end