; docformat = 'rst'

;+
; Create mask for KCor image given geometry information about the occulter and
; field stop: x-center, y-center, and radius of the occulter and the radius of
; the field stop.
;
; :Returns:
;   `bytarr(xsize, ysize)`
;
; :Params:
;   xcenter : in, required, type=float
;     x-coordinate of the occulter center
;   ycenter : in, required, type=float
;     y-coordinate of the occulter center
;   occulter_radius : in, required, type=float
;     radius of the occulter
;   field_radius : in, required, type=float
;     radius of the field stop
;
; :Keywords:
;   dimensions : in, optional, type=lonarr(2), default="[1024, 1024]"
;     dimensions of the output mask
;-
function kcor_geometry_mask, xcenter, ycenter, occulter_radius, field_radius, $
                             dimensions=dimensions
  compile_opt strictarr

  dims = n_elements(dimensions) eq 0L ? [1024L, 1024L] : dimensions

  x = rebin(reform(findgen(dims[0]), dims[0], 1) - xcenter, dims[0], dims[1])
  y = rebin(reform(findgen(dims[1]), 1, dims[1]) - ycenter, dims[0], dims[1])
  r = sqrt(x^2 + y^2)

  field_mask = r lt field_radius
  occulter_mask = r gt occulter_radius
  mask = field_mask and occulter_mask

  return, mask
end


; main-level example program

xcenter = 505.43103
ycenter = 512.70161
occulter_radius = 179.04439
field_radius = 504.0

mg_image, bytscl(kcor_geometry_mask(xcenter, ycenter, occulter_radius, field_radius))

end
