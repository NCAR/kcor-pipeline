; docformat = 'rst'

function kcor_annulus_gridmeans, image, radius, sun_pixels
  compile_opt strictarr

  nbins = 720
  gridmeans = fltarr(nbins)

  width = 0.1

  dims = size(image, /dimensions)
  n = dims[0]

  d = mg_dist(n, /center, theta=theta)

  ind = where((d gt (sun_pixels * (radius - width))) $
                and (d lt (sun_pixels * (radius + width))), $
              count)
  h = histogram(theta[ind], nbins=nbins, min=0.0, max=2.0 * !pi, reverse_indices=ri)

  for i = 0L, 719L do begin
    if (ri[i] ne ri[i + 1]) then begin
      gridmeans[i] = mean(image[ind[ri[ri[i]:ri[i + 1] - 1]]])
    endif
  endfor

  return, gridmeans
end
