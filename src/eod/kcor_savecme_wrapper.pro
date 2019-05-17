; docformat = 'rst'

;+
; Wrapper to save the CME results.
;
; :Params:
;   date : in, required, type=string
;     date in the form 'YYYYMMDD'
;
; :Keywords:
;   config_filename : in, required, type=string
;     filename of config file
;-
pro kcor_savecme_wrapper, date, config_filename=config_filename
  compile_opt strictarr

  run = kcor_run(date, config_filename=config_filename, mode='eod')
  logger_name = 'kcor/' + run.mode
  mg_log, 'saving CME results', name=logger_name, /info

  save_basedir = run->config('results/save_basedir')
  if (save_basedir eq '') then begin
    mg_log, 'no save basedir, exiting', name=logger_name, /warn
    goto, done
  endif

  save_dir = filepath(date, root=save_basedir)

  dirs = ['hpr', 'hpr_diff']
  for d = 0L, n_elements(dirs) - 1L do begin
    src_dir = filepath('', $
                       subdir=kcor_decompose_date(date), $
                       root=run->config('cme/' + dirs[d] + '_dir'))
    file_copy, src_dir, filepath(dirs[d], root=save_dir), /recursive
  endfor

  ; handle movie directory a bit differently
  movies = file_search(filepath(string(date, format='(%"%s_kcor_cme_detection.*")'), $
                                root=run->config('cme/movie_dir')), $
                       count=n_movies)
  if (n_movies gt 0L) then begin
    file_copy, movies, filepath('cme_movies', root=save_dir), /overwrite
  endif

  done:
  mg_log, 'done', name=logger_name, /info
  if (obj_valid(run)) then obj_destroy, run
end
