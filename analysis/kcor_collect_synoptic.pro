; docformat = 'rst'

;+
; :Params:
;   start_date : in, required, type=string
;     start date in the form "YYYYMMDD"
;   end_date : in, required, type=string
;     end date in the form "YYYYMMDD"
;
; :Keywords:
;   radius : in, optional, type=float, default=1.8
;   times : out, optional, type=dblarr
;   cadence : in, optional, type=integer, default=24
;     number of images per day
;   run : in, required, type=object
;     KCor run object
;-
function kcor_collect_synoptic, start_date, end_date, $
                                radius=radius, times=times, cadence=cadence, $
                                run=run
  compile_opt strictarr

  _cadence = n_elements(cadence) eq 0L ? 24L : cadence

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
  map = fltarr(n_days * _cadence, n_bins)
  times = lonarr(n_days, 6)

  for d = 0L, n_days - 1L do begin
    caldat, jd_start + d, month, day, year

    mg_log, 'checking %04d%02d%02d', year, month, day, /info

    times[d, 0] = year
    times[d, 1] = month
    times[d, 2] = day

    l2_files = file_search(filepath('*_*_kcor_l2.fts.gz', $
                                    subdir=string(year, month, day, $
                                                  format='(%"%04d/%02d/%02d")'), $
                                    root='/hao/acos'), $
                           count=n_l2_files)

    for i = 0L, _cadence - 1L do begin
    filename = l2_files[19]
    basename = file_basename(filename)

    hour  = long(strmid(basename, 9, 2))
    min   = long(strmid(basename, 11, 2))
    sec   = long(strmid(basename, 13, 2))

    times[d, 3] = hour
    times[d, 4] = min
    times[d, 5] = sec

    fhour = hour + min / 60.0 + sec / 60.0 / 60.0
    sun, year, month, day, fhour, sd=rsun, pa=pangle, la=bangle

    sun_pixels = rsun / run->epoch('plate_scale')

    image = readfits(filename, header, /silent)

    map[d, *] = kcor_annulus_gridmeans(image, _radius, sun_pixels, nbins=n_bins)

    endfor
  endfor

  return, map
end


; main-level program


start_date = '20140427'
end_date = '20170509'
;radii = ['1.1', '1.3', '1.8']
radii = ['1.12', '1.15']

config_filename = filepath('kcor.reprocess.cfg', $
                           subdir=['..', 'config'], $
                           root=mg_src_root())

run = kcor_run(start_date, config_filename=config_filename)

for r = 0L, n_elements(radii) - 1L do begin
  mg_log, 'starting for radius %sR', radii[r], /info
  map = kcor_collect_synoptic(start_date, end_date, $
                              radius=float(radii[r]), $
                              times=times, $
                              run=run)
  output_filename = string(radii[r], format='(%"synoptic-map-%sR.sav")')
  save, map, times, filename=output_filename
  mg_log, 'output in %s', output_filename, /info
endfor

obj_destroy, run

end
