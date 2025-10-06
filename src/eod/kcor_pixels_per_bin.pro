; docformat = 'rst'

;+
; Determine the number of pixels per annular bin.
;
; :Returns:
;   float
;
; :Params:
;   radius : in, required, type=float
;     center radius of annulus in Rsun
;   half_width : in, required, type=float
;     half of width in radial directional
;   sun_pixels : in, required, type=float
;     number of pixels corresponding to a solar radius
;   n_bins : in, required, type=long
;     number of radial bins
;
; :Keywords:
;   dimensions : in, optional, type=fltarr(2), default="[1024, 1024]"
;     dimensions of image
;-
function kcor_pixels_per_bin, radius, half_width, sun_pixels, n_bins, $
                              dimensions=dimensions
  compile_opt strictarr

  n = n_elements(dimensions) eq 0L ? 1024L : dimensions[0]

  d = mg_dist(n, /center)
  !null = where((d gt (sun_pixels * (radius - half_width))) $
                 and (d lt (sun_pixels * (radius + half_width))), $
                n_total_pixels)

  return, float(n_total_pixels) / float(n_bins)
end


; main-level example program

plate_scale = 5.557

sun, 2025, 10, 2, (16 + 52 / 60.0) / 24.0, sd=radsun, dist=dist_au
sun_pixels = radsun / plate_scale

n_bins = 720
radii = [1.11, 1.15, 1.20, 1.35, 1.50, 1.75, 2.00, 2.25, 2.50]
half_width = 0.01

print, plate_scale, width, n_bins, $
       format='for plate_scale: %0.3f arcsec/pixel, width: %0.2f Rsun, n_bins: %d...'
for r = 0L, n_elements(radii) - 1L do begin
  pixels_per_bin = kcor_pixels_per_bin(radii[r], half_width, sun_pixels, n_bins)
  print, radii[r],  pixels_per_bin, format='radius %0.2f Rsun -> %0.1f pixels/bin'
endfor

; for plate_scale: 5.557 arcsec/pixel, width: 0.02 Rsun, n_bins: 720...
; radius 1.11 Rsun -> 11.6 pixels/bin
; radius 1.15 Rsun -> 11.9 pixels/bin
; radius 1.20 Rsun -> 12.4 pixels/bin
; radius 1.35 Rsun -> 14.1 pixels/bin
; radius 1.50 Rsun -> 15.5 pixels/bin
; radius 1.75 Rsun -> 18.2 pixels/bin
; radius 2.00 Rsun -> 20.6 pixels/bin
; radius 2.25 Rsun -> 23.4 pixels/bin
; radius 2.50 Rsun -> 25.9 pixels/bin

end
