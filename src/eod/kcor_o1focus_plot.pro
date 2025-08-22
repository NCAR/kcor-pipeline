; docformat = 'rst'

;+
; Create a GIF file of a plot of O1 focus values by time.
;
; :Params:
;   filename : in, required, type=string
;     filename of output GIF file
;   hst_times : in, required, type=fltarr
;     HST times of O1 focus readings
;   o1focus : in, required, type=fltarr
;     O1 focus values
;
; :Keywords:
;   title : in, optional, type=string
;     title of plot
;   run : in, required, type=object
;     KCor run object
;-
pro kcor_o1focus_plot, filename, hst_times, o1focus, title=title, run=run
  compile_opt strictarr

  ; initialize graphics
  original_device = !d.name
  set_plot, 'Z'
  device, get_decomposed=original_decomposed
  device, decomposed=0
  tvlct, original_rgb, /get
  loadct, 0, /silent
  device, set_resolution=[772, 500], set_colors=256, z_buffering=0

  ; display graphics
  time_min = run->epoch('o1focus_tstart')
  time_max = run->epoch('o1focus_tend')
  o1focus_min = min(o1focus) - 0.25
  o1focus_max = max(o1focus) + 0.25
  plot, hst_times, o1focus, $
        xstyle=1, xrange=[time_min, time_max], xtitle='HST time of day', $
        ystyle=1, yrange=[o1focus_min, o1focus_max], ytitle='O1FOCS values [mm]', $
        psym=6, symsize=0.1, $
        color=0, background=255, $
        title=n_elements(title) eq 0L ? '' : title

  ; save image file
  write_gif, filename, tvrd()

  ; cleanup
  done:
  tvlct, original_rgb
  device, decomposed=original_decomposed
  set_plot, original_device
end
