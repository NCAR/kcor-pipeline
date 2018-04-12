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

  ; create quality histogram

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

  ; display plot

  original_device = !d.name
  set_plot, 'Z'
  device, set_resolution=[600, 120], set_pixel_depth=24, decomposed=1
  tvlct, original_rgb, /get

  colors = ['00a000'x, $   ; oka
            '00d0ff'x, $   ; brt
            'a06000'x, $   ; cal
            'a9a9a9'x, $   ; cld
            'e6d8ad'x, $   ; dev
            '606060'x, $   ; dim
            '0090d0'x, $   ; nsy
            'ee82ee'x]     ; sat
  sums = total(histograms, 2, /preserve_type)
  mg_stacked_histplot, (increment / 60.0) * findgen(n_bins) + start_time, $
                       histograms, $
                       axis_color='000000'x, $
                       background='ffffff'x, color=colors, /fill, $
                       xstyle=9, xticks=end_time - start_time, xminor=4, $
                       ystyle=9, yrange=[0, max_images], yticks=4, $
                       charsize=0.85, $
                       xtitle='Time (HST)', ytitle='# of images', $
                       position=[0.075, 0.25, 0.85, 0.95]

  present_ind = where(sums gt 0, n_present)
  if (n_present gt 0L) then begin
    square = mg_usersym(/square, /fill)
    mg_legend, item_name=types + ' ' + strtrim(sums, 2), $
               item_color=colors, $
               item_psym=square, $
               item_symsize=1.5, $
               color='000000'x, $
               charsize=0.85, $
               position=[0.875, 0.15, 0.95, 0.95]
  endif

  im = tvrd(true=1)
  tvlct, original_rgb
  set_plot, original_device
  write_png, output_filename, im
end


; main-level example program

q_dir = '/hao/mahidata1/Data/KCor/raw.test/20170821/q'
kcor_quality_plot, q_dir, 'quality.png'

end
