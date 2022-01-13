; docformat = 'rst'

;+
; Publish engineering products for a day that had already been processed.
;
; :Params:
;   date : in, required, type=string
;     date in the form YYYYMMDD
;
; :Keywords:
;   config_filename : in, required, type=string
;     config filename
;-
pro kcor_publish_eng_plots, date, config_filename=config_filename
  compile_opt strictarr

  run = kcor_run(date, config_filename=config_filename, mode='publish')
  mg_log, 'publishing eng plots for %s...', date, name=run.logger_name, /info

  ; make engineering directory, if needed
  eng_basedir = run->config('results/engineering_basedir')
  ;mg_log, 'eng_basedir: %s', eng_basedir, name=run.logger_name, /debug
  eng_dir = filepath('', subdir=kcor_decompose_date(date), root=eng_basedir)
  ;mg_log, 'eng_dir: %s', eng_dir, name=run.logger_name, /debug
  if (~file_test(eng_dir, /directory)) then file_mkdir, eng_dir

  raw_basedir = run->config('processing/raw_basedir')
  p_dir = filepath('p', subdir=date, root=raw_basedir)
  if (~file_test(p_dir)) then goto, done
  cd, p_dir

  ; copy files
  globs = ['*.kcor.radial.intensity.gif', $
           '*.kcor.mean-pb-1.11.gif', $
           '*.kcor.mean-pb-1.30.gif', $
           '*.kcor.mean-pb-1.50.gif', $
           '*.kcor.mean-pb-1.80.gif', $
           '*.kcor.28day.synoptic.r130.gif', $
           '*.kcor.28day.synoptic.r130.fts', $
           '*.sgs.eng.gif', $
           '*.kcor.sgs.seeing.gif', $
           '*.kcor.sgs.sky_transmission_and_seeing.gif']
  for g = 0L, n_elements(globs) - 1L do begin
    files = file_search(globs[g], count=n_files)
    if (n_files gt 0L) then begin
      mg_log, 'copying %s', globs[g], name=run.logger_name, /debug
      file_copy, files, eng_dir, /overwrite
     endif
  endfor

  done:
  obj_destroy, run
end
