; docformat = 'rst'


pro kcor_rt, date, config_filename=config_filename
  compile_opt strictarr

  print, date, config_filename, format='(%"running %s with config_filename %s")'
end
