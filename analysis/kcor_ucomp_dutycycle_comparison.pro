; docformat = 'rst'

pro kcor_ucomp_dutycycle_comparison, kcor_savefile, ucomp_savefile
  compile_opt strictarr

  restore, kcor_savefile, /verbose
  kcor_dates = dates               ; Julian date for each day
  kcor_start_times = start_times   ; Julian date of start time for each day
  kcor_end_times = end_times       ; Julian date of end time for each day
  kcor_n_images = n_images         ; number of good images for each day
  kcor_times = times               ; hours into UT day for each image

  restore, ucomp_savefile, /verbose
  ucomp_dates = dates
  ucomp_start_times = start_times
  ucomp_end_times = end_times
  ucomp_n_images = n_images
  ucomp_times = times

  ; adjust to HST
  kcor_hst_start_times  = kcor_start_times - 10.0 / 24.0
  kcor_hst_end_times    = kcor_end_times - 10.0 / 24.0
  ucomp_hst_start_times = ucomp_start_times - 10.0 / 24.0
  ucomp_hst_end_times   = ucomp_end_times - 10.0 / 24.0

  date_range = [min([kcor_dates, ucomp_dates]), $
                max([kcor_dates, ucomp_dates])]
  time_range = [6.0, 20.0]

  month_ticks = mg_tick_locator(date_range, /months)
  n_months = n_elements(month_ticks)
  if (n_months eq 0L) then begin
    month_ticks = 1L
  endif else begin
    max_ticks = 7
    n_minor = n_months / max_ticks > 1
    month_ticks = month_ticks[0:*:n_minor]
  endelse

  !null = label_date(date_format='%M %Y')
  usersym, 2.0 * [-1.0, 1.0], fltarr(2), thick=2.0

  use_ps = 1B

  if (keyword_set(use_ps)) then begin
    basename = 'duty-cycle-comparison'
    mg_psbegin, filename=basename + '.ps', /color, bits_per_pixel=24, $
                xsize=10.0, ysize=7.5, /inches, $
                /landscape, xoffset=0.25, yoffset=10.5
    charsize = 1.0
    font = 1
    symsize = 0.25
    axis_color = '000000'x
    kcor_start_color = '0000ff'x
    kcor_end_color = '8080ff'x
    ucomp_start_color = 'ff0000'x
    ucomp_end_color = 'ff8080'x
  endif else begin
    window, xsize=1200, ysize=700, /free
    charsize = 1.25
    font = -1
    symsize = 0.25
    axis_color = 'ffffff'x
    kcor_start_color = '0000ff'x
    kcor_end_color = '8080ff'x
    ucomp_start_color = '00ff00'x
    ucomp_end_color = '80ff80'x
  endelse

  mg_decomposed, 1, old_decomposed=odec

  plot, date_range, time_range, /nodata, $
        xstyle=1, xrange=date_range, xtickformat='label_date', $
        xtickv=month_ticks, xticks=n_elements(month_ticks) - 1L, xminor=n_minor, $
        xtitle='Dates', $
        ystyle=1, yrange=time_range, yticks=(time_range[1] - time_range[0]) / 2, yminor=2, $
        ytitle='HST time', $
        font=font, charsize=charsize, color=axis_color, $
        title='KCor and UCoMP start (box)/end (line) times of good science images'

  ; convert to hours into the observing day; 0.5 needed because the Julian day
  ; starts at noon
  kcor_obsday_start_times  = 24.0 * (kcor_hst_start_times - long(kcor_hst_start_times) - 0.5D)
  kcor_obsday_end_times    = 24.0 * (kcor_hst_end_times - long(kcor_hst_end_times - 0.5D) - 0.5D)
  ucomp_obsday_start_times = 24.0 * (ucomp_hst_start_times - long(ucomp_hst_start_times) - 0.5D)
  ucomp_obsday_end_times   = 24.0 * (ucomp_hst_end_times - long(ucomp_hst_end_times - 0.5D) - 0.5D)

  oplot, kcor_dates, kcor_obsday_start_times, $
         psym=6, symsize=symsize, color=kcor_start_color
  oplot, kcor_dates, kcor_obsday_end_times, $
         psym=8, symsize=symsize, color=kcor_end_color

  oplot, ucomp_dates, ucomp_obsday_start_times, $
         psym=6, symsize=symsize, color=ucomp_start_color
  oplot, ucomp_dates, kcor_obsday_end_times, $
         psym=8, symsize=symsize, color=ucomp_end_color

  xyouts, 0.85, 0.85, /normal, 'KCor', color=kcor_start_color
  xyouts, 0.85, 0.85 - 0.025, /normal, 'UCoMP', color=ucomp_start_color

  if (keyword_set(use_ps)) then begin
    mg_psend
  endif

  done:
  device, decomposed=odec
end


; main-level example program

kcor_savefile = 'duty-cycle-info.sav'
ucomp_savefile = filepath(kcor_savefile, $
                          subdir=['..', '..', 'ucomp-pipeline', 'analysis'], $
                          root=mg_src_root())
kcor_ucomp_dutycycle_comparison, kcor_savefile, ucomp_savefile

end
