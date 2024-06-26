; docformat = 'rst'

function kcor_timehistogram_readoka, raw_basedir, date, count=count
  compile_opt strictarr

  count = 0L
  oka_filename = filepath('oka.ls', subdir=[date, 'q'], root=raw_basedir)
  if (~file_test(oka_filename, /regular)) then return, !null

  ; read oka.ls file
  count = file_lines(oka_filename)
  if (count eq 0L) then return, !null
  filenames = strarr(count)
  openr, lun, oka_filename, /get_lun
  readf, lun, filenames
  free_lun, lun

  ; create decimal hours
  times = strmid(filenames, 9, 6)
  times = long(kcor_decompose_time(times))
  times[0, *] = (times[0, *] - 10 + 24) mod 24   ; convert to HST
  times = times[0, *] + (times[1, *] + times[2, *] / 60.0) / 60.0

  return, reform(times)
end


pro kcor_timehistogram, raw_basedirs, for_dates
  compile_opt strictarr

  ; collect data
  times_list = list()
  for r = 0L, n_elements(raw_basedirs) - 1L do begin
    print, raw_basedirs[r], format='(%"checking %s...")'
    dates = file_search(filepath('????????', root=raw_basedirs[r]), count=n_dates)
    for d = 0L, n_dates - 1L do begin
      print, file_basename(dates[d]), format='(%"  %s")'
      if (~file_test(dates[d], /directory)) then continue
      date_files = kcor_timehistogram_readoka(raw_basedirs[r], $
                                              file_basename(dates[d]), $
                                              count=n_date_files)
      if (n_date_files gt 0L) then times_list->add, date_files, /extract
    endfor
  endfor
  times = times_list->toArray()

  n_total = n_elements(times)
  !null = where(times gt 14.0, n_later_than_14)

  title = string(for_dates, format='(%"# of good files by time %s")')
  start_time = 6.0
  end_time = 19.0
  h = histogram(times, min=start_time, binsize=0.25, locations=locs)
  window, xsize=1024, ysize=512, /free, $
          title=title
  plot, locs, h, psym=10, $
        xtitle='HST time', $
        xrange=[start_time, end_time], xstyle=9, xticks=end_time - start_time, xminor=4, $
        ytitle='# of good files', ystyle=9, $
        title=title, $
        color='000000'x, background='ffffff'x
  xyouts, 0.975, 0.85, /normal, alignment=1.0, $
          string(n_later_than_14, n_total, 100.0 * n_later_than_14 / n_total, $
                 format='(%"%d of %d images (%0.1f%%) later than 1400 HST")'), $
          color='000000'x, charsize=1.5
end

; main-level example program

;raw_basedirs = ['/hao/kaula1/Data/KCor/raw/2013', $
;                '/hao/kaula1/Data/KCor/raw/2014', $
;                '/hao/mlsodata3/Data/KCor/raw/2015', $
;                '/hao/mlsodata2/Data/KCor/raw/2016', $
;                '/hao/sunrise/Data/KCor/raw/2017', $
;                '/hao/sunrise/Data/KCor/raw/2018', $
;                '/hao/mlsodata1/Data/KCor/raw']
raw_basedirs = ['/hao/mlsodata2/Data/KCor/raw/2016', $
                '/hao/sunrise/Data/KCor/raw/2017']
kcor_timehistogram, raw_basedirs, 'for 2016-2017'

end
