; docformat = 'rst'


;+
; :Params:
;   level : in, required, type=integer
;     level 1 or 2
;
; :Keywords:
;   run : in, required, type=object
;     KCor run object
;-
pro kcor_redogifs_level, level, run=run
  compile_opt strictarr

  filenames = file_search(filepath(string(level, format='(%"*_kcor_l%d.fts.gz")'), $
                                      subdir=[run.date, $
                                              string(level, format='(%"level%d")')], $
                                      root=run->config('processing/raw_basedir')), $
                             count=n_files)
  if (n_files eq 0L) then begin
    mg_log, 'no level %d files, exiting', level, name=run.logger_name, /warn
    return
  endif else begin
    mg_log, 'producing GIFs for %d level %d files', n_files, level, $
            name=run.logger_name, /info
  endelse

  for f = 0L, n_elements(filenames) - 1L do begin
    corona = readfits(filenames[f], header)
    date_obs = sxpar(header, 'DATE-OBS')
    date_struct = kcor_parse_dateobs(date_obs)
    run.time = date_obs

    kcor_create_gif, filenames[f], corona, date_obs, $
                     level=level, /nomask, $
                     run=run, log_name=run.logger_name
    kcor_create_gif, filenames[f], corona, date_obs, $
                     level=level, $
                     run=run, log_name=run.logger_name

    kcor_cropped_gif, corona, run.date, date_struct, $
                      level=level, /nomask, $
                      run=run, log_name=run.logger_name
    kcor_cropped_gif, corona, run.date, date_struct, $
                      level=level, $
                      run=run, log_name=run.logger_name
  endfor
end


;+
; Redo the pB GIFs for the day (normal and cropped).
;
; :Params:
;   date : in, required, type=string
;     date in the form YYYYMMDD
;
; :Keywords:
;   config_filename : in, required, type=string
;     config filename
;-
pro kcor_redogifs, date, config_filename=config_filename
  compile_opt strictarr

  run = kcor_run(date, config_filename=config_filename, mode='eod')

  mg_log, 'starting creating GIFs for %d', date, name=run.logger_name, /info

  kcor_redogifs_level, 1L, run=run
  kcor_redogifs_level, 2L, run=run

  ; TODO: make sure to create GIFs of the daily and 2 min averages also

  mg_log, 'done', name=run.logger_name, /info

  obj_destroy, run
end
