; docformat = 'rst'

;+
; Plot quantities in L1.5 files, such as sky transmission.
;
; :Keywords:
;   run : in, required, type=object
;     KCor run object
;-
pro kcor_plot_l1, run=run
  compile_opt strictarr

  original_device = !d.name
  skytrans_range = [0.8, 1.2]

  base_dir  = run->config('processing/raw_basedir')
  date_dir  = filepath(run.date, root=base_dir)
  plots_dir = filepath('p', root=date_dir)
  l1_dir    = filepath('level1', root=date_dir)

  logger_name = 'kcor/eod'

  mg_log, 'starting...', name=logger_name, /info

  l1_files = file_search(filepath('*_*_kcor_l1.5.fts.gz', root=l1_dir), $
                         count=n_l1_files)
  if (n_l1_files eq 0L) then begin
    mg_log, 'no L1 files to plot', name=logger_name, /warn
    goto, done
  endif

  times = fltarr(n_l1_files)
  skytrans = fltarr(n_l1_files)
  for f = 0L, n_l1_files - 1L do begin
    fits_open, l1_files[f], fcb
    fits_read, fcb, im, header, /header_only
    fits_close, fcb

    date_obs = sxpar(header, 'DATE-OBS')
    date = kcor_parse_dateobs(date_obs, hst_date=hst_date)
    times[f] = hst_date.ehour + 10.0

    strans = fxpar(header, 'SKYTRANS', /null)
    skytrans[f] = n_elements(strans) eq 0L ? !values.f_nan : strans
  endfor

  !null = where(finite(skytrans) eq 0L, n_nan)
  !null = where(skytrans lt skytrans_range[0], n_lt)
  !null = where(skytrans gt skytrans_range[1], n_gt)

  n_bad = n_nan + n_lt + n_gt
  if (n_bad gt 0L) then begin
    mg_log, '%d out of range sky transmission values', n_bad, $
            name=logger_name, /error
  endif

  set_plot, 'Z'
  device, set_resolution=[772, 500], decomposed=0, set_colors=256, $
          z_buffering=0
  loadct, 0, /silent

  plot, times, skytrans, $
        title=string(run.date, format='(%"Sky transmission for %s")'), $
        xtitle='Hours [UT]', $
        yrange=skytrans_range, ystyle=1, ytitle='Sky transmission', $
        background=255, color=0, charsize=1.25

  im = tvrd()
  write_gif, filepath(string(run.date, format='(%"%s.kcor.skytrans.gif")'), $
                      root=plots_dir), $
             im

  done:
  set_plot, original_device

  mg_log, 'done', name=logger_name, /info
end


; main-level program

date = '20160603'
config_filename = filepath('kcor.latest.cfg', $
                           subdir=['..', '..', 'config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)
kcor_plot_l1, run=run
obj_destroy, run

end
