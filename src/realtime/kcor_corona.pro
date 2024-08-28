; docformat = 'rst'

;+
; Calculate an estimate of the corona from polarization data.
;
; :Returns:
;   fltarr(nx, ny)
;
; :Params:
;   im : in, required, type="fltarr(nx, ny, 4)"
;     image data for one camera
;
; :Keywords:
;   angles : in, optional, type=boolean
;     use angles for
;-
function kcor_corona, im, angles=angles
  compile_opt strictarr

  _im = float(im)
  q = reform(_im[*, *, 0, *] - _im[*, *, 3, *])
  u = reform(_im[*, *, 1, *] - _im[*, *, 2, *])

  if (keyword_set(angles)) then begin
    n_dims = size(im, /n_dimensions)
    dims = size(im, /dimensions)
    xsize = dims[0]
    ysize = dims[1]

    x = dindgen(xsize, ysize) mod xsize
    y = transpose(dindgen(ysize, xsize) mod ysize)
    theta = atan(- y, - x)
    theta += !dpi
    theta = reverse(theta)
    if (n_dims eq 4) then theta = rebin(theta, xsize, ysize, 2L)

    pb = 0.5 * q * cos(2.0 * theta) + 0.5 * u * sin(2.0 * theta)
  endif else begin
    pb = sqrt(q^2 + u^2)
  endelse

  return, pb
end
