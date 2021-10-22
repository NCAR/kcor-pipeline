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

  if (run->config('eod/produce_report')) then begin
    mg_log, 'generating report...', name='kcor/eod', /info
  endif else begin
    mg_log, 'skipping report generation', name='kcor/eod', /info
    goto, done
  endelse

  ; copy logs over to home directory
  logs = ['reprocess', 'realtime', 'eod']
  for f = 0L, n_elements(logs) - 1L do begin
    basename = string(date, logs[f], format='(%"%s.%s.log")')
    log_dir = filepath(strmid(run.date, 0, 4), root=run->config('logging/basedir'))
    if (~file_test(log_dir, /directory)) then file_mkdir, log_dir
    log_filename = filepath(basename, root=log_dir)
    if (file_test(log_filename, /regular)) then begin
      dst_filename = filepath(file_basename(basename, '.log') + '.olog', $
                              subdir=date, $
                              root=run->config('processing/raw_basedir'))
      if (file_test(dst_filename)) then file_delete, dst_filename
      file_copy, log_filename, dst_filename
    endif
  endfor

  ; generate report
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

  done:
  mg_log, 'done', name='kcor/eod', /info
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
