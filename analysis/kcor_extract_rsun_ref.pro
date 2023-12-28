; docformat = 'rst'

function kcor_extract_rsun_ref, filename
  compile_opt strictarr

  header = headfits(filename)
  dsun_obs    = sxpar(header, 'DSUN_OBS')
  plate_scale = sxpar(header, 'CDELT1')
  rcam_radius = sxpar(header, 'RCAM_RAD')
  tcam_radius = sxpar(header, 'TCAM_RAD')
  radius      = (rcam_radius + tcam_radius) / 2.0

  rsun_ref = dsun_obs * tan(radius * plate_scale / 60.0 / 60.0 * !dtor)
  return, rsun_ref
end


; main-level example program

files = file_search('????????_??????_kcor_l2.fts.gz', count=n_files)
for f = 0L, n_files - 1 do begin
  print, files[f], kcor_extract_rsun_ref(files[f]), format='%s: %g'
endfor

end
