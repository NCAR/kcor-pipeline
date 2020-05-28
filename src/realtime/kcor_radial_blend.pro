; docformat = 'rst'

;+
; Blend two images at a given radius.
;
; Uses a radial logistic function to smoothly blend the two images.
;
; :Returns:
;   image of the same size as the input images, `fltarr(m, n)`
;
; :Params:
;   outer_image : in, required, type="fltarr(m, n)"
;     image to use outside `radius`
;   inner_image : in, required, type="fltarr(m, n)"
;     image to use inside `radius`
;   dividing_radius : in, required, type=float
;     dividing radius [pixels]
;
; :Keywords:
;   growth_rate : in, optional, type=float, default=1.0
;     growth rate of logistic function
;-
function kcor_radial_blend, outer_image, inner_image, dividing_radius, $
                            growth_rate=growth_rate
  compile_opt strictarr

  dims = size(outer_image, /dimensions)
  nx = dims[0]
  ny = dims[1]
  x = rebin(reform(findgen(nx) - float(nx - 1L) / 2.0, nx, 1L), nx, ny)
  y = rebin(reform(findgen(ny) - float(ny - 1L) / 2.0, 1L, ny), nx, ny)

  r = sqrt(x^2 + y^2)

  ; use a logistic function of radius as the blending function:
  ;
  ;   a(r) = L / (1 + exp(-k * (r - x0)))
  ;
  ; where L = 1.0, r0 = midpoint, i.e., occulter radius + epsilon, and 
  ; k = growth rate/steepness

  k = n_elements(growth_rate) eq 0L ? 1.0 : growth_rate
  a = 1.0 / (1.0 + exp(- k * (r - dividing_radius)))

  ; blend and return
  return, a * outer_image + (1.0 - a) * inner_image
end


; main-level example program
nx = 1024L
ny = 1024L
scale = 8L
radius = 100.0
growth_rates = [1.0, 0.5, 0.25]

outer = fltarr(nx, ny)
inner = fltarr(nx, ny) + 1.0

snx = 50L
sny = 50L
sxc = 412L
syc = 512L
window, xsize=scale * snx * n_elements(growth_rates), ysize=scale * sny, /free

for r = 0L, n_elements(growth_rates) - 1L do begin
  blend = kcor_radial_blend(outer, inner, radius, growth_rate=growth_rates[r])
  sub = blend[sxc - snx / 2:sxc + snx / 2 - 1, syc - sny / 2:syc + sny / 2 - 1]
  tv, bytscl(congrid(sub, scale * snx, scale * sny), min=0.0, max=1.0), r
endfor

;window, xsize=scale * nx, ysize=scale * ny, /free
;tv, bytscl(congrid(blend, scale * nx, scale * ny))

end
