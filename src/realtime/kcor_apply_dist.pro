; docformat = 'rst'

;+
; Apply distortion correction to the sub-images `dat1` and `dat2` given the
; distortion coefficients.
;
; :Requires:
;   IDL 8.2.3
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

  type = size(dat1, /type)
  dims = size(dat1, /dimensions)
  nx = dims[0]
  ny = dims[1]

  x = rebin(dindgen(nx), nx, ny)
  y = rebin(reform(dindgen(ny), 1, ny), nx, ny)

  cubic_coefficient = -0.5
  dat1 = interpolate(double(dat1), $
                     x + kcor_eval_surf(dx1_c, x, y), $
                     y + kcor_eval_surf(dy1_c, x, y), $
                     cubic=cubic_coefficient, missing=0.0, /double)
  dat2 = interpolate(double(dat2), $
                     x + kcor_eval_surf(dx2_c, x, y), $
                     y + kcor_eval_surf(dy2_c, x, y), $
                     cubic=cubic_coefficient, missing=0.0, /double)
  dat1 = fix(dat1, type=type)
  dat2 = fix(dat2, type=type)
end