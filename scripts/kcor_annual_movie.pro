; docformat = 'rst'

;+
; Create various annual movies for #462.
;-
pro kcor_annual_movie, year, pattern, run=run
  compile_opt strictarr

  mp4_filename = year + strmid(file_basename(pattern, '.gif'), 1) + '.mp4'

  start_date = year + '0101'
  end_date = strtrim(long(year) + 1L, 2) + '0101'

  date = start_date
  i = 0
  gif_filenames = strarr(366)

  while (date ne end_date) do begin
    run.date = date
    l2_dir = filepath('level2', subdir=date, root=run->config('processing/raw_basedir'))
    print, date, l2_dir, format='%s -> %s'

    if (~file_test(l2_dir, /directory)) then begin
      date = kcor_increment_date(date)
      continue
    endif

    l2_filenames = file_search(filepath(pattern, root=l2_dir), count=n_l2_files)
    print, n_l2_files, format='%d matching files'

    if (n_l2_files gt 0L) then begin
      gif_filenames[i] = l2_filenames[0]
      i += 1
    endif

    date = kcor_increment_date(date)
  endwhile

  gif_filenames = gif_filenames[0:i - 1]
  print, mp4_filename, format='creating %s...'
  kcor_create_mp4, gif_filenames, mp4_filename, run=run, status=status
  print, status, format='status: %d'
end


; main-level example

years = ['2013', '2014', '2015', '2016', '2017', '2018', '2019', '2020', '2021', '2022']
patterns = ['*_kcor_l2_pb_avg.gif', $
            '*_kcor_l2_pb_avg_enhanced.gif', $
            '*_kcor_l2_nrgf_avg.gif', $
            '*_kcor_l2_nrgf_avg_enhanced.gif']

config_basename = 'kcor.reprocess.cfg'
config_filename = filepath(config_basename, $
                           subdir=['..', '..', 'kcor-config'], $
                           root=mg_src_root())

run = kcor_run(years[0] + '0101', config_filename=config_filename, mode='script')

for y = 0L, n_elements(years) - 1L do begin
  for p = 0L, n_elements(patterns) - 1L do begin
    kcor_annual_movie, years[y], patterns[p], run=run
  endfor
endfor

obj_destroy, run

end
