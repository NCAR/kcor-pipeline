; docformat = 'rst'

;+
; Create report (web page) of the day results.
;
; :Params:
;   date : in, required, type=date
;     date in the form 'YYYYMMDD' to process
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;-
pro kcor_report_results, date, run=run
  compile_opt strictarr

  template_filename = filepath('index.tt', $
                               subdir='html', $
                               root=run.resources_dir)
  template = mgfftemplate(template_filename)

  output_filename = filepath('index.html', $
                             subdir=date, $
                             root=run->config('processing/raw_basedir'))

  mg_log, 'creating end-of-day report...', name='kcor/eod', /info
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
