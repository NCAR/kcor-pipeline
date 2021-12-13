; docformat = 'rst'

;+
; Lock/unlock a raw directory.
;
; :Returns:
;   availability before operations, i.e., if `available = kcor_state(/lock)`
;   returns whether the raw directory was available before trying to lock it
;
; :Keywords:
;   lock : in, optional, type=boolean
;     set to try to obtain a lock on the `date_dir` in the raw
;     directory
;   unlock : in, optional, type=boolean
;     set to unlock a `date_dir` in the raw directory
;   processed : in, optional, type=boolean
;     set to set a lock indicating the directory has been processed
;   first_image : in, optional, type=boolean
;     set to return first image state instead of lock state; call when
;     processing a good science image; 0=haven't skipped a good science
;     image, 1=have already skipped the first science image, keep remaining
;   run : in, required, type=object
;     `kcor_run` object
;-
function kcor_state, lock=lock, $
                     unlock=unlock, $
                     processed=processed, $
                     first_image=first_image, $
                     set_first_image=set_first_image, $
                     run=run
  compile_opt strictarr, logical_predicate
  on_error, 2

  logger_name = run.logger_name

  if (keyword_set(first_image)) then begin
    raw_dir = filepath(run.date, root=run->config('processing/raw_basedir'))
    state_file = filepath('.first_image', root=raw_dir)

    if (~file_test(state_file)) then begin
      mg_log, 'writing first image file', name=logger_name, /debug
      openw, lun, state_file, /get_lun
      printf, lun, mg_pid()
      free_lun, lun
      return, 0B
    endif else begin
      return, 1B
    endelse
  endif

  if (run->config('processing/lock_raw')) then begin
    raw_dir = filepath(run.date, root=run->config('processing/raw_basedir'))
    lock_file = filepath('.lock', root=raw_dir)
    processed_file = filepath('.processed', root=raw_dir)

    mg_log, 'checking %s', lock_file, name=logger_name, /debug
    mg_log, 'lock file: %s', file_test(lock_file) ? 'present' : 'not present', $
            name=logger_name, /debug
    mg_log, 'processed file: %s', file_test(processed_file) ? 'present' : 'not present', $
            name=logger_name, /debug
    available = ~file_test(lock_file) && ~file_test(processed_file)

    if (keyword_set(lock)) then begin
      if (available) then begin
        mg_log, 'writing lock file', name=logger_name, /debug
        openw, lun, lock_file, /get_lun
        printf, lun, mg_pid()
        free_lun, lun
      endif else begin
        mod_time = systime(0, file_modtime(lock_file))
        mg_log, 'lock file mod time: %s', mod_time, name=logger_name, /debug
      endelse
      mg_log, '%savailable', available ? '' : 'not ', name=logger_name, /debug
      return, available
    endif

    if (keyword_set(unlock)) then begin
      locked = file_test(lock_file)
      if (locked) then begin
        mg_log, 'removing lock file', name=logger_name, /debug
        file_delete, lock_file
      endif
      return, locked
    endif

    if (keyword_set(processed)) then begin
      mg_log, 'writing processed file', name=logger_name, /debug
      openw, lun, processed_file, /get_lun
      printf, lun, mg_pid()
      free_lun, lun
      return, 1B
    endif
  endif else begin
    available = 1B
  endelse

  return, available
end
