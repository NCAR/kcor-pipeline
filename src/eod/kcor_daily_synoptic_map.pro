; docformat = 'rst'

;+
; Create a synoptic plot for the current day.
; 
; :Keywords:
;   radius : in, optional, type=float, default=1.3
;     radius used for map [Rsun]
;   run : in, required, type=object]
;     KCor run object
;-
pro kcor_daily_synoptic_map, radius=radius, run=run
  compile_opt strictarr

  logger_name = run.logger_name

  ; get all L2 files
  l2_glob = filepath('*_kcor_l2.fts.gz', $
                     subdir=[run.date, 'level2'], $
                     root=run->config('processing/raw_basedir'))
  files = file_search(l2_glob, count=n_files)
  if (n_files eq 0L) then begin
    mg_log, 'no L2 files for daily synoptic map', name=logger_name, /warn
    goto, done
  endif else begin
    mg_log, 'producing map from %d L2 files', n_files, $
            name=logger_name, /info
  endelse

  _radius = n_elements(radius) eq 0L ? 1.3 : radius
  start_hour = 6
  end_hour = 18
  n_bins = 1080 ;720
  n_angles = 720

  map = fltarr(n_bins, n_angles)
  counts = lonarr(n_bins)

  sgsrazr = fltarr(n_files)
  sgsdeczr = fltarr(n_files)
  bin_indices = lonarr(n_files)

  for f = 0L, n_files - 1L do begin
    im = readfits(files[f], header, /silent)

    sgsrazr[f] = fxpar(header, 'SGSRAZR', /nan)
    sgsdeczr[f] = fxpar(header, 'SGSDECZR', /nan)

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
    sun, year, month, day, fhour, sd=rsun

    run.time = date_obs
    sun_pixels = rsun / run->epoch('plate_scale')

    r = kcor_annulus_gridmeans(im, _radius, sun_pixels, nbins=n_angles)

    ; place r in the right place in the map
    jd = julday(month, day, year, hour, minute, second) - 10.0 / 24.0
    caldat, jd, hst_month, hst_day, hst_year, hst_hour, hst_minute, hst_second

    mins = 60 * (hst_hour - start_hour) + hst_minute + hst_second / 60.0
    i = long(n_bins * mins / (end_hour - start_hour) / 60L)
    map[i, *] += r
    counts[i] += 1
    bin_indices[f] = i
  endfor

  counts[where(counts eq 0L, /null)] = 1L
  map /= rebin(reform(counts, n_bins, 1), n_bins, n_angles)

  ; display map
  original_device = !d.name
  set_plot, 'Z'
  device, set_resolution=[n_bins + 80, n_angles + 160]

  device, get_decomposed=original_decomposed
  tvlct, rgb, /get
  device, decomposed=0

  range = mg_range(map)
  if (range[0] lt 0.0) then begin
    minv = 0.0
    maxv = range[1]

    loadct, 0, /silent
    foreground = 0
    background = 255
  endif else begin
    minv = 0.0
    maxv = range[1]

    loadct, 0, /silent
    foreground = 0
    background = 255
  endelse

  razr_diffs = sgsrazr[1:-1] - sgsrazr[0:-2]
  deczr_diffs = sgsdeczr[1:-1] - sgsdeczr[0:-2]
  pointing_diffs = razr_diffs or deczr_diffs
  pointing_changes_indices = where(pointing_diffs, n_pointing_changes)

  if (n_pointing_changes gt 0L) then begin
    normalized_bins = (bin_indices[pointing_changes_indices] + 1) / float(n_bins)
    pointing_change_hours = (end_hour - start_hour) * normalized_bins + start_hour
  endif

  north_up_map = shift(map, 0, -180)
  east_limb = reverse(north_up_map[*, 0:359], 2)
  west_limb = north_up_map[*, 360:*]

  charsize = 1.0
  smooth_kernel = [11, 1]

  title = string(_radius, $
                 long(kcor_decompose_date(run.date)), $
                 format='(%"Synoptic map for %0.2f Rsun on %04d-%02d-%02d")')
  erase, background
  mg_image, reverse(east_limb, 1), $
            reverse((end_hour - start_hour) * findgen(n_bins) / (n_bins - 1.0) + start_hour), $
            xrange=[end_hour, start_hour], $
            xtyle=1, xtitle='HST time (markers indicate pointing changes)', $
            min_value=minv, max_value=maxv, $
            /axes, yticklen=-0.005, xticklen=-0.01, $
            color=foreground, background=background, $
            title=string(title, format='(%"%s (East limb)")'), $
            position=[0.05, 0.55, 0.97, 0.95], /noerase, $
            yticks=4, ytickname=['S', 'SE', 'E', 'NE', 'N'], yminor=4, $
            charsize=charsize
  if (n_pointing_changes gt 0L) then begin
    plots, pointing_change_hours, $
           fltarr(n_pointing_changes) - 8.0, $
           color=128, $
           psym=5, symsize=0.7
  endif

  mg_image, reverse(west_limb, 1), $
            reverse((end_hour - start_hour) * findgen(n_bins) / (n_bins - 1.0) + start_hour), $
            xrange=[end_hour, start_hour], $
            xstyle=1, xtitle='HST time (markers indicate pointing changes)', $
            min_value=minv, max_value=maxv, $
            /axes, yticklen=-0.005, xticklen=-0.01, $
            color=foreground, background=background, $
            title=string(title, format='(%"%s (West limb)")'), $
            position=[0.05, 0.05, 0.97, 0.45], /noerase, $
            yticks=4, ytickname=['S', 'SW', 'W', 'NW', 'N'], yminor=4, $
            charsize=charsize
  if (n_pointing_changes gt 0L) then begin
    plots, pointing_change_hours, $
           fltarr(n_pointing_changes) - 8.0, $
           color=128, $
           psym=5, symsize=0.7
  endif

  im = tvrd()

  p_dir = filepath('p', subdir=run.date, root=run->config('processing/raw_basedir'))
  if (~file_test(p_dir, /directory)) then file_mkdir, p_dir

  output_filename = filepath(string(run.date, $
                                    100.0 * _radius, $
                                    format='(%"%s.daily.synoptic.r%03d.gif")'), $
                             root=p_dir)
  write_gif, output_filename, im, rgb[*, 0], rgb[*, 1], rgb[*, 2]

  mkhdr, primary_header, map, /extend
  sxdelpar, primary_header, 'DATE'
  fxaddpar, primary_header, 'NAXIS1', n_bins, $
            ' number of time divisions of the observing day'
  fxaddpar, primary_header, 'NAXIS2', n_angles, $
            ' number of angular divisions of annulus'
  sxaddpar, primary_header, 'DATE-OBS', $
            string(long(kcor_decompose_date(run.date)), $
                   format='(%"%04d-%02d-%02dT06:00:00")'), $
            ' [HST] start of synoptic map', after='EXTEND'
  sxaddpar, primary_header, 'DATE-END', $
            string(long(kcor_decompose_date(run.date)), $
                   format='(%"%04d-%02d-%02dT18:00:00")'), $
            ' [HST] end of synoptic map', after='DATE-OBS'
  sxaddpar, primary_header, 'START_HR', start_hour, $
            ' [HST] decimal start hour of map', $
            format='(F0.2)', after='DATE-END'
  sxaddpar, primary_header, 'END_HR', end_hour, $
            ' [HST] decimal end hour of map', $
            format='(F0.2)', after='START_HR'
  sxaddpar, primary_header, 'HEIGHT', _radius, $
            ' [Rsun] height of annulus +/- 0.02 Rsun', $
            format='(F0.2)', after='END_HR'

  fits_filename = filepath(string(run.date, $
                                  100.0 * _radius, $
                                  format='(%"%s.daily.synoptic.r%03d.fts")'), $
                           root=p_dir)
  writefits, fits_filename, map, primary_header

  mkhdr, counts_header, counts
  fxaddpar, counts_header, 'XTENSION', 'IMAGE', ' extension type', $
            before='BITPIX'
  fxaddpar, counts_header, 'EXTNAME', 'Counts', after='NAXIS1'
  sxdelpar, counts_header, 'DATE'
  writefits, fits_filename, counts, counts_header, /append

  ; clean up
  done:
  if (n_elements(rgb) gt 0L) then tvlct, rgb
  if (n_elements(original_decomposed) gt 0L) then device, decomposed=original_decomposed
  if (n_elements(original_device) gt 0L) then set_plot, original_device

  mg_log, 'done', name=logger_name, /info
end


; main-level example

;dates = '202001' + ['01', '02', '04', '05', '06', '08', '17', '18', '19', '20']
dates = ['20200118']
for d = 0L, n_elements(dates) - 1L do begin
  config_filename = filepath('kcor.reprocess.cfg', $
                             subdir=['..', '..', 'config'], $
                             root=mg_src_root())
  run = kcor_run(dates[d], config_filename=config_filename)

  kcor_daily_synoptic_map, run=run

  obj_destroy, run
endfor

end
