; docformat = 'rst'

;+
; Create various annual movies for #462.
;-
pro kcor_annual_movies, year, run=run
  compile_opt strictarr

  patterns = ['*_kcor_l2_pb_avg.gif', $
              '*_kcor_l2_pb_avg_enhanced.gif', $
              '*_kcor_l2_nrgf_avg.gif', $
              '*_kcor_l2_nrgf_avg_enhanced.gif']

  for p = 0L, n_elements(patterns) - 1L do begin
    pattern = patterns[p]

    mp4_basename = year + strmid(file_basename(pattern, '.gif'), 1) + '.mp4'
    agif_basename = year + strmid(file_basename(pattern, '.gif'), 1) + '_movie.gif'

    start_date = year + '0101'
    end_date = strtrim(long(year) + 1L, 2) + '0101'

    date = start_date
    i = 0
    gif_filenames = strarr(366)

    while (date ne end_date) do begin
      date_l2_dir = filepath('level2', subdir=date, root=run->config('processing/raw_basedir'))

      if (~file_test(date_l2_dir, /directory)) then begin
        date = kcor_increment_date(date)
        continue
      endif

      l2_filenames = file_search(filepath(pattern, root=date_l2_dir), count=n_l2_files)

      if (n_l2_files gt 0L) then begin
        gif_filenames[i] = l2_filenames[0]
        i += 1
      endif

      date = kcor_increment_date(date)
    endwhile

    gif_filenames = gif_filenames[0:i - 1]

    l2_dir = filepath('level2', subdir=run.date, root=run->config('processing/raw_basedir'))
    if (~file_test(l2_dir, /directory)) then file_mkdir, l2_dir
    cd, l2_dir

    annual_basedir = run->config('results/annual_basedir')
    if (n_elements(annual_basedir) gt 0L) then begin
      if (~file_test(annual_basedir, /directory)) then file_mkdir, annual_basedir
      annual_dir = filepath(year, root=annual_basedir)
      if (~file_test(annual_dir, /directory)) then file_mkdir, annual_dir
    endif

    mg_log, 'creating %s...', mp4_basename, name=run.logger_name, /info
    mp4_filename = filepath(mp4_basename, root=l2_dir)
    kcor_create_mp4, gif_filenames, mp4_filename, run=run, status=status
    if (n_elements(annual_basedir) gt 0L) then file_copy, mp4_filename, annual_dir, /overwrite

    mg_log, 'creating %s...', agif_basename, name=run.logger_name, /info
    agif_filename = filepath(agif_basename, root=l2_dir)
    kcor_create_animated_gif, gif_filenames, agif_basename, run=run, status=status
    if (n_elements(annual_basedir) gt 0L) then file_copy, agif_filename, annual_dir, /overwrite
  endfor
end


; main-level example
years = ['2013', '2014', '2015', '2016', '2017', '2018', '2019', '2020', '2021', '2022']

years = ['2017']
config_basename = 'kcor.latest.cfg'
config_filename = filepath(config_basename, $
                           subdir=['..', '..', '..', 'kcor-config'], $
                           root=mg_src_root())

run = kcor_run(years[0] + '0101', config_filename=config_filename, mode='script')
annual_basedir = run->config('results/annual_basedir')

for y = 0L, n_elements(years) - 1L do begin
  kcor_annual_movies, years[y], run=run
endfor

obj_destroy, run

end
