; docformat = 'rst'

;+
; Extract a radial intensity profile from a FITS file.
;
; :Params:
;   filename : in, required, type=string
;     filename of FITS file to extract intensity from
;   plate_scale : in, required, type=float
;     plate scale
;
; :Keywords:
;   radii : out, optional, type=fltarr
;     set to a named variable to retrieve the radius values the intensity was
;     extracted at
;   standard_deviation : out, optional, type=fltarr
;     set to a named variable to retrieve the standard deviation of intensity
;     profile
;-
function kcor_extract_radial_intensity, filename, plate_scale, $
                                        radii=radii, $
                                        standard_deviation=standard_deviation

  image = readfits(filename, header, /silent)
  cx = sxpar(header, 'CRPIX1') - 1.0   ; convert from FITS convention to
  cy = sxpar(header, 'CRPIX2') - 1.0   ; IDL convention

  date_obs = sxpar(header, 'DATE-OBS', count=qdate_obs)
    
  ; normalize odd values for date/times
  date_obs = kcor_normalize_datetime(date_obs)

  year   = long(strmid(date_obs,  0, 4))
  month  = long(strmid(date_obs,  5, 2))
  day    = long(strmid(date_obs,  8, 2))
  hour   = long(strmid(date_obs, 11, 2))
  minute = long(strmid(date_obs, 14, 2))
  second = long(strmid(date_obs, 17, 2))

  fhour = hour + minute / 60.0 + second / 60.0 / 60.0
  mlso_sun, year, month, day, fhour, sd=rsun, pa=pangle, la=bangle

  sun_pixels = rsun / plate_scale
  
  ; angles for full circle in radians
  theta = findgen(360) * !dtor

  n_radii = 90
  start_radius = 1.05
  radius_step = 0.02
  radii = radius_step * findgen(n_radii) + start_radius
  intensity = fltarr(n_radii)
  standard_deviation = fltarr(n_radii)
  for r = 0L, n_radii - 1L do begin
    x = sun_pixels * radii[r] * cos(theta) + cx
    y = sun_pixels * radii[r] * sin(theta) + cy
    intensity[r] = mean(image[round(x), round(y)])
    standard_deviation[r] = stddev(image[round(x), round(y)])
  endfor

  return, intensity
end
