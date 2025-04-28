; docformat = 'rst'

;+
; Compute the mean pB value in a polar grid defined by the `n_angles`, `radii`,
; and `radius_width`.
;
; :Returns:
;   `fltarr(n_angles, n_radii)`
;
; :Params:
;   pB : in, required, type="fltarr(nx, ny)"
;     pB data to average
;   date : in, required, type=structure
;     parsed date obs with `year`, `month`, `day`, and `ehour` fields
;   radii : in, required, type=fltarr
;     the radii to check in R_sun
;   radius_width : in, required, type=float
;     annulus has inside radius of `radii - radius_width / 2.0` and outside
;     radius of `radii + radius_width / 2.0`
;   plate_scale : in, required, type=float
;-
function kcor_plot_l2_mean_pB, pB, date, $
                               radii, radius_width, $
                               plate_scale
  compile_opt strictarr

  ; calculate emphemeris information
  sun, date.year, date.month, date.day, date.ehour, sd=rsun
  sun_pixels = rsun / plate_scale

  n_radii = n_elements(radii)

  ; compute x-y coordinates in R_sun

  center_x = 511.5
  center_y = 511.5
  dims = size(pB, /dimensions)

  x = rebin(reform(findgen(dims[0]) - center_x, dims[0], 1), dims[0], dims[1])
  x /= sun_pixels

  y = rebin(reform(findgen(dims[1]) - center_y, 1, dims[1]), dims[0], dims[1])
  y /= sun_pixels

  ; compute radius-theta coordinates in R_sun and radians
  radius = sqrt(x^2 + y^2)

  ; compute mean
  mean_pb = fltarr(n_radii)
  for r = 0L, n_radii - 1L do begin
    ind = where((radius gt (radii[r] - radius_width / 2.0)) $
                and (radius lt (radii[r] + radius_width / 2.0)), n_pixels)
    mean_pb[r] = n_pixels eq 0L ? !values.f_nan : mean(pb[ind])
  endfor

  return, mean_pb
end


;+
; Plot quantities in L2 files, such as sky transmission.
;
; :Keywords:
;   run : in, required, type=object
;     KCor run object
;-
pro kcor_plot_l2, run=run
  compile_opt strictarr

  original_device = !d.name
  skytrans_range = [0.8, 1.2]

  base_dir  = run->config('processing/raw_basedir')
  date_dir  = filepath(run.date, root=base_dir)
  plots_dir = filepath('p', root=date_dir)
  l2_dir    = filepath('level2', root=date_dir)

  logger_name = 'kcor/eod'

  mg_log, 'starting...', name=logger_name, /info

  l2_files = file_search(filepath('*_*_kcor_l2_pb.fts.gz', root=l2_dir), $
                         count=n_l2_files)
  if (n_l2_files eq 0L) then begin
    mg_log, 'no L2 files to plot', name=logger_name, /warn
    goto, done
  endif

  radii = [1.11, 1.3, 1.5, 1.8]   ; R_sun
  radius_width = 0.01
  yranges = [[1.0e-07, 7.0e-07], $
             [3.0e-08, 3.0e-07], $
             [5.0e-09, 1.5e-07], $
             [1.0e-09, 5.0e-08]]
  plate_scale = run->epoch('plate_scale')

  dates = strarr(n_l2_files)
  times = strarr(n_l2_files)
  float_times = fltarr(n_l2_files)
  skytrans = fltarr(n_l2_files)
  mean_pb = fltarr(n_elements(radii), n_l2_files)
  for f = 0L, n_l2_files - 1L do begin
    fits_open, l2_files[f], fcb
    fits_read, fcb, pB, header
    fits_close, fcb

    date_obs = sxpar(header, 'DATE-OBS')
    date = kcor_parse_dateobs(date_obs, hst_date=hst_date)
    dates[f] = string(date.year, date.month, date.day, format='(%"%04d%02d%02d")')
    times[f] = string(date.hour, date.minute, date.second, format='(%"%02d%02d%02d")')
    float_times[f] = hst_date.ehour + 10.0

    strans = fxpar(header, 'SKYTRANS', /null)
    skytrans[f] = n_elements(strans) eq 0L ? !values.f_nan : strans

    mean_pb[*, f] = kcor_plot_l2_mean_pb(pB, date, $
                                         radii, radius_width, $
                                         plate_scale)
  endfor

  !null = where(finite(skytrans) eq 0L, n_nan)
  !null = where(skytrans lt skytrans_range[0], n_lt)
  !null = where(skytrans gt skytrans_range[1], n_gt)

  n_bad = n_nan + n_lt + n_gt
  if (n_bad gt 0L) then begin
    mg_log, '%d out of range sky transmission values', n_bad, $
            name=logger_name, /warn
  endif

  charsize = 1.15

  set_plot, 'Z'
  device, set_resolution=[772, 500], decomposed=0, set_colors=256, $
          z_buffering=0
  loadct, 0, /silent

  plot, float_times, skytrans, $
        title=string(run.date, format='(%"Sky transmission correction for %s")'), $
        xtitle='Hours [UT]', $
        yrange=skytrans_range, ystyle=1, $
        ytitle='Sky trans @ flat image / sky trans @ science image', $
        background=255, color=0, charsize=charsize, psym=1

  im = tvrd()
  write_gif, filepath(string(run.date, format='(%"%s.kcor.skytrans-correct.gif")'), $
                      root=plots_dir), $
             im

  ; plot average pB over the day at several heights

  device, set_resolution=[772, 500], decomposed=0, set_colors=256, z_buffering=0

  engineering_basedir = run->config('results/engineering_basedir')

  for r = 0L, n_elements(radii) - 1L do begin
    plot, float_times, reform(mean_pb[r, *]), $
          title=string(radii[r], run.date, $
                       format='(%"KCor mean pB @ %0.2f R_sun for %s")'), $
          xmargin=[11, 3], xticklen=1.0, xtitle='Hours [UT]', $
          yticklen=1.0, yrange=yranges[*, r], ystyle=1, ytitle='pB', $
          ytickformat='(E0.1)', $
          background=255, color=200, charsize=charsize, psym=1

    plot, float_times, reform(mean_pb[r, *]), /noerase, $
          title=string(radii[r], run.date, $
                       format='(%"KCor mean pB @ %0.2f R_sun for %s")'), $
          xmargin=[11, 3], xticklen=0.025, xtitle='Hours [UT]', $
          yticklen=0.03, yrange=yranges[*, r], ystyle=1, ytitle='pB', $
          ytickformat='(E0.1)', $
          color=0, charsize=charsize, psym=1

    im = tvrd()
    mean_pb_filename = filepath(string(run.date, radii[r], $
                                       format='(%"%s.kcor.mean-pb-%0.2f.gif")'), $
                                root=plots_dir)
    write_gif, mean_pb_filename, im

    if (n_elements(engineering_basedir) gt 0L) then begin
      engineering_dir = filepath('', $
                                 subdir=kcor_decompose_date(run.date), $
                                 root=engineering_basedir)
      if (~file_test(engineering_dir, /directory)) then file_mkdir, engineering_dir
      mg_log, 'distributing mean pB GIF at %0.2f R_sun...', radii[r], $
              name='kcor/eod', /info
      file_copy, mean_pb_filename, engineering_dir, /overwrite
    endif

    openw, lun, filepath(string(run.date, radii[r], $
                                format='(%"%s.kcor.mean-pb-%0.2f.txt")'), $
                         root=plots_dir), $
           /get_lun

    printf, lun, 'This text file contains calibrated polarization brightness (pB) measurements of'
    printf, lun, 'the low corona from the Mauna Loa Solar Observatory K-Coronagraph (K-Cor) over'
    printf, lun, 'one observing day. Each measurement is the azimuthally-averaged (i.e. averaged'
    printf, lun, 'over all angles around the corona) pB measurement at the height indicated in the'
    printf, lun, 'table.'
    printf, lun
    printf, lun, 'Date', 'Time', 'pB intensity', 'Height', $
            format='(%"%-15s   %-15s   %-15s   %-22s")'
    printf, lun, '[yr mm dd]', '[hr mm ss]', '[B/Bsun]', '[Rsun from sun center]', $
            format='(%"%-15s   %-15s   %-15s   %-22s")'
    printf, lun, string(bytarr(15) + (byte('-'))[0]), $
                 string(bytarr(15) + (byte('-'))[0]), $
                 string(bytarr(15) + (byte('-'))[0]), $
                 string(bytarr(22) + (byte('-'))[0]), $
                 format='(%"%-15s   %-15s   %-15s   %-22s")'
    for i = 0L, n_elements(mean_pb[r, *]) - 1L do begin
      printf, lun, dates[i], times[i], mean_pb[r, i], radii[r], $
              format='(%"%-15s   %-15s   %15.5g   %22.2f")'
    endfor
    free_lun, lun
  endfor

  done:
  set_plot, original_device

  mg_log, 'done', name=logger_name, /info
end


; main-level program

date = '20210106'
config_filename = filepath('kcor.latest.cfg', $
                           subdir=['..', '..', 'config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)
kcor_plot_l2, run=run
obj_destroy, run

end
