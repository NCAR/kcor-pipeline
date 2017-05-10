; docformat = 'rst'

function kcor_collect_synoptic, start_date, end_date, radius=radius, times=times, run=run
  compile_opt strictarr

  n_bins = 720
  _radius = n_elements(radius) eq 0L ? 1.8 : radius

  jd_start = julday(strmid(start_date, 4, 2), $
                    strmid(start_date, 6, 2), $
                    strmid(start_date, 0, 4))
  jd_end   = julday(strmid(end_date, 4, 2), $
                    strmid(end_date, 6, 2), $
                    strmid(end_date, 0, 4))

  ; find number of days
  n_days = jd_end - jd_start + 1.0D
  mg_log, '%d days to check', n_days, /info

  ; allocate results
  map = fltarr(n_days, n_bins)
  times = lonarr(n_days, 6)

  for d = 0L, n_days - 1L do begin
    caldat, jd_start + d, month, day, year

    mg_log, 'checking %04d%02d%02d', year, month, day, /info

    l1_files = file_search(filepath('*_*_kcor_l1.fts.gz', $
                                    subdir=string(year, month, day, $
                                                  format='(%"%04d/%02d/%02d")'), $
                                    root='/hao/acos'), $
                           count=n_l1_files)
    if (n_l1_files lt 20) then continue

    filename = l1_files[19]
    basename = file_basename(filename)

    hour  = long(strmid(basename, 9, 2))
    min   = long(strmid(basename, 11, 2))
    sec   = long(strmid(basename, 13, 2))

    times[d, 0] = year
    times[d, 1] = month
    times[d, 2] = day
    times[d, 3] = hour
    times[d, 4] = min
    times[d, 5] = sec

    fhour = hour + min / 60.0 + sec / 60.0 / 60.0
    sun, year, month, day, fhour, sd=rsun, pa=pangle, la=bangle

    sun_pixels = rsun / run->epoch('plate_scale')

    image = readfits(filename, header, /silent)

    map[d, *] = kcor_annulus_gridmeans(image, _radius, sun_pixels, nbins=n_bins)
  endfor

  return, map
end


; main-level program


start_date = '20140427'
end_date = '20170509'
radius = '1.08'

config_filename = filepath('kcor.mgalloy.mahi.latest.cfg', $
                           subdir=['..', 'config'], $
                           root=mg_src_root())

run = kcor_run(start_date, config_filename=config_filename)

map = kcor_collect_synoptic(start_date, end_date, radius=float(radius), times=times, run=run)
output_filename = string(radius, format='(%"synoptic-map-%sR.sav")')
save, map, times, filename=output_filename
mg_log, 'output in %s', output_filename, /info

end
