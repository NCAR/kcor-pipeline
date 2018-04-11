; docformat = 'rst'


;+
; Read the times from one of the quality `.ls` files.
;
; :Returns:
;    `fltarr` of decimal HST times from given file
;
; :Params:
;   type_filename : in, required, type=string
;     quality `.ls` filename
;-
function kcor_quality_plot_read, type_filename
  compile_opt strictarr

  n_lines   = file_lines(type_filename)
  if (n_lines eq 0L) then return, !null

  hst_times = fltarr(n_lines)
  openr, lun, type_filename, /get_lun
  line = ''
  for t = 0L, n_lines - 1L do begin
    readf, lun, line
    hst_time = kcor_ut2hst(strmid(line, 9, 6))
    hst_times[t] = float(strmid(hst_time, 0, 2)) $
                     + float(strmid(hst_time, 2, 2)) / 60.0 $
                     + float(strmid(hst_time, 4, 2)) / 60.0 / 60.0
  endfor
  free_lun, lun

  return, hst_times
end


;+
; Make a histogram plot of the raw files from the day, color coded by quality
; type.
;
; :Params:
;   q_dir : in, required, type=string
;     quality directory, i.e., `q` subdir
;   output_filename : in, required, type=string
;     filename for output PNG
;-
pro kcor_quality_plot, q_dir, output_filename
  compile_opt strictarr

  mg_log, 'producing end-of-day quality plot...', name='kcor/eod', /info

  types = ['oka', 'brt', 'cal', 'cld', 'dev', 'dim', 'nsy', 'sat']
  n_types = n_elements(types)
  type_filenames = filepath(types + '.ls', root=q_dir)

  start_time = 06   ; 24-hour time
  end_time   = 19   ; 24-hour time
  increment  = 15   ; minutes
  max_images = 4 * increment
  n_bins = long((end_time  - start_time) / (increment / 60.0))

  histograms = lonarr(n_types, n_bins)
  for t = 0L, n_types - 1L do begin
    if (~file_test(type_filenames[t])) then continue
    hst_times = kcor_quality_plot_read(type_filenames[t])
    if (n_elements(hst_times) gt 0L) then begin
      histograms[t, *] = histogram(hst_times, $
                                   min=start_time, $
                                   max=end_time - increment / 60.0, $
                                   nbins=n_bins, $
                                   locations=locations)
    endif
  endfor

  original_device = !d.name
  set_plot, 'Z'
  device, set_resolution=[800, 150], set_pixel_depth=24, decomposed=1
  tvlct, original_rgb, /get
  loadct, 41, /silent
  tvlct, rgb, /get

  ;colors = mg_rgb2index(rgb[bytscl(bindgen(n_types)), *])
  colors = mg_color(['orange', 'slateblue', 'yellow', 'red', $
                     'darkgrey', 'blanchedalmond', 'dodgerblue', 'aquamarine'], $
                    /index)
  sums = total(histograms, 2, /preserve_type)
  mg_stacked_histplot, (increment / 60.0) * findgen(n_bins) + start_time, $
                       histograms, $
                       axis_color='000000'x, $
                       background='ffffff'x, color=colors, /fill, $
                       xstyle=9, xticks=end_time - start_time, xminor=4, $
                       ystyle=9, yrange=[0, max_images], yticks=4, $
                       xtitle='Time (HST)', ytitle='# of images', $
                       position=[0.075, 0.15, 0.85, 0.95]

  square = mg_usersym(/square, /fill)
  mg_legend, item_name=types + ' ' + strtrim(sums, 2), $
             item_color=colors, $
             item_psym=square, $
             item_symsize=1.5, $
             color='000000'x, $
             position=[0.86, 0.15, 0.95, 0.95]

  im = tvrd(true=1)
  tvlct, original_rgb
  set_plot, original_device
  write_png, output_filename, im
end


; main-level example program

kcor_quality_plot, '/Users/mgalloy/Desktop/q', 'quality.png'

end
