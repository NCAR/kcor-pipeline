; docformat = 'rst'

pro kcor_annual_image_scale_plot, year, database=db, run=run
  compile_opt strictarr

  output_basename = string(year, format='(%"%s.kcor.yearly.image_scale.gif")')

  end_date = year + '1231'
  is_leap_year = mg_is_leap_year(long(year))
  n_days = is_leap_year ? 366 : 365
  kcor_rolling_image_scale_plot, end_date, n_days=n_days, database=db, run=run, $
                                 output_basename=output_basename

  annual_basedir = run->config('results/annual_basedir')
  if (n_elements(annual_basedir) gt 0L) then begin
    if (~file_test(annual_basedir, /directory)) then file_mkdir, annual_basedir
    annual_dir = filepath(year, root=annual_basedir)
    if (~file_test(annual_dir, /directory)) then file_mkdir, annual_dir

    output_filename = filepath(output_basename, $
                               subdir=[run.date, 'p'], $
                               root=run->config('processing/raw_basedir'))

    file_copy, output_filename, annual_dir
  endif
end


; main-level example program

; date = '20221231'
date = '20151231'
config_basename = 'kcor.reprocessing.cfg'
config_filename = filepath(config_basename, $
                           subdir=['..', '..', '..', 'kcor-config'], $
                           root=mg_src_root())

run = kcor_run(date, mode='test', config_filename=config_filename)

db = kcordbmysql()
db->connect, config_filename=run->config('database/config_filename'), $
             config_section=run->config('database/config_section')

kcor_annual_image_scale_plot, strmid(date, 0, 4), database=db, run=run

obj_destroy, [db, run]

end
