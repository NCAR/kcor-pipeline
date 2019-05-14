; docformat = 'rst'

pro kcor_report_results, date, run=run
  compile_opt strictarr

  template_filename = filepath('index.tt', $
                               subdir='html', $
                               root=run.resources_dir)
  template = mgfftemplate(template_filename)

  output_filename = filepath('index.html', $
                             subdir=date, $
                             root=run->config('processing/raw_basedir'))

  template->process, run, output_filename

  obj_destroy, template
end


; main-level example program

date = '20190508'
config_filename = filepath('kcor.latest.cfg', $
                           subdir=['..', '..', 'config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename, mode='eod')
if (obj_valid(run)) then begin
  kcor_report_results, date, run=run
  obj_destroy, run
endif

end
