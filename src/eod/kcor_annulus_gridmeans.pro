; docformat = 'rst'

;+
; Find means of polar coordinate grid for a single annulus at a given solar radii.
;
; :Returns:
;   `fltarr(nbins)`
;
; :Params:
;   image : in, required, type="fltarr(n, n)"
;     image to find the annular grid means from
;   radius : in, required, type=float
;     number of solar radii to create annulus at
;   sun_pixels : in, required, type=float
;     number of pixels corresponding to a solar radius
;
; :Keywords:
;   nbins : in, optional, type=integer, default=720
;     number of azimuthal bins
;-
function kcor_annulus_gridmeans, image, radius, sun_pixels, nbins=nbins
  compile_opt strictarr

  _nbins = n_elements(nbins) eq 0L ? 720L : nbins
  gridmeans = fltarr(_nbins)

  width = 0.02

  dims = size(image, /dimensions)
  n = dims[0]

  d = mg_dist(n, /center, theta=theta)

  ind = where((d gt (sun_pixels * (radius - width))) $
                and (d lt (sun_pixels * (radius + width))), $
              count)
  h = histogram(theta[ind], nbins=_nbins, min=0.0, binsize=2.0 * !pi / _nbins, reverse_indices=ri)

  for i = 0L, _nbins - 1L do begin
    if (ri[i] ne ri[i + 1]) then begin
      gridmeans[i] = mean(image[ind[ri[ri[i]:ri[i + 1] - 1]]])
    endif
  endfor

  return, gridmeans
end
