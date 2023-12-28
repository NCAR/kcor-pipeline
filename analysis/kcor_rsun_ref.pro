; docformat = 'rst'

function kcor_extract_rsun_ref, filename
  compile_opt strictarr

  radius = (radius_0 + radius_1) / 2.0
  rsun_ref = dist_au * au_to_meters * tan(run->epoch('plate_scale') * radius / 60.0 / 60.0)

  header = headfits(filename)
  dsun_obs    = sxpar(header, 'DSUN_OBS')
  plate_scale = sxpar(header, 'CDELT1')
  rcam_radius = sxpar(header, 'RCAM_RAD')
  tcam_radius = sxpar(header, 'TCAM_RAD')
  radius      = (rcam_radius + tcam_radius) / 2.0

  rsun_ref = dsun_obs * tan(radius * plate_scale / 60.0 / 60.0 * !dtor)
  return, rsun_ref
end

