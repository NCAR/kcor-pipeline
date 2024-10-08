; docformat = 'rst'


;+
; Helper routine to clear a table for a given day.
;
; :Params:
;   table : in, required, type=string
;     table to clear, i.e., kcor_img, kcor_eng, etc.
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;   obsday_index : in, required, type=integer
;     index into mlso_numfiles database table
;   database : in, optional, type=KCordbMySql object
;     database connection to use
;   log_name : in, required, type=string
;     name of log to send log messages to
;-
pro kcor_db_clearday_cleartable, table, $
                                 obsday_index=obsday_index, $
                                 database=db, $
                                 log_name=log_name
  compile_opt strictarr

  mg_log, 'clearing %s table', table, name=log_name, /info
  db->execute, 'delete from %s where obs_day=%d', $
               table, obsday_index, $
               status=status, $
               n_affected_rows=n_affected_rows
  if (status eq 0L) then begin
    mg_log, '%d rows deleted', n_affected_rows, name=log_name, /info
  endif
end


;+
; Delete entries for a day, e.g., before reprocessing that day.
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;   obsday_index : in, required, type=integer
;     index into mlso_numfiles database table
;   database : in, optional, type=KCordbMySql object
;     database connection to use
;   log_name : in, required, type=string
;     name of log to send log messages to
;   calibration : in, optional, type=boolean
;     set to just clear the calibration for a day
;-
pro kcor_db_clearday, run=run, $
                      database=db, $
                      obsday_index=obsday_index, $
                      log_name=log_name, $
                      calibration=calibration
  compile_opt strictarr

  db->getProperty, host_name=host
  mg_log, 'using connection to %s', host, name=log_name, /debug

  day = db->query('select * from mlso_numfiles where day_id=%d', obsday_index, $
                  status=status, error_message=error_message, sql_statement=sql_cmd)
  if (status ne 0L) then begin
    mg_log, 'error querying mlso_numfiles table', name=log_name, /error
    mg_log, 'status: %d, error message: %s', status, error_message, $
            name=log_name, /error
    mg_log, 'SQL command: %s', sql_cmd, name=log_name, /error
  endif

  mg_log, 'clearing entries for obsday index %d (%s)', $
          obsday_index, day[0].obs_day, $
          name=log_name, /info

  ; zero num_kcor_pb and num_kcor_nrgf in mlso_numfiles
  if (not keyword_set(calibration)) then begin
    mg_log, 'zeroing KCor values for mlso_numfiles table', name=log_name, /info
    fields = 'num_kcor_' + ['pb_fits', $
                            'pb_avg_fits', $
                            'pb_extavg_fits', $
                            'pb_lowresgif', $
                            'pb_avg_lowresgif', $
                            'pb_fullresgif', $
                            'pb_avg_fullresgif', $
                            'nrgf_fits', $
                            'nrgf_avg_fits', $
                            'nrgf_extavg_fits', $
                            'nrgf_lowresgif', $
                            'nrgf_fullresgif']
    fields_expression = strjoin(fields + '=0', ', ')
    db->execute, 'update mlso_numfiles set %s where day_id=''%d''', $
                 fields_expression, $
                 obsday_index, $
                 status=status, error_message=error_message, sql_statement=sql_cmd
    if (status ne 0L) then begin
      mg_log, 'error zeroing values in mlso_numfiles table', name=log_name, /error
      mg_log, 'status: %d, error message: %s', status, error_message, $
              name=log_name, /error
      mg_log, 'SQL command: %s', sql_cmd, name=log_name, /error
    endif

    ; mlso_sgs
    mg_log, 'clearing mlso_sgs table', name=log_name, /info
    db->execute, 'delete from mlso_sgs where obs_day=%d and source=''k''', $
                 obsday_index, $
                 status=status, error_message=error_message, sql_statement=sql_cmd, $
                 n_affected_rows=n_affected_rows
    if (status ne 0L) then begin
      mg_log, 'error clearing mlso_sgs table', name=log_name, /error
      mg_log, 'status: %d, error message: %s', status, error_message, $
              name=log_name, /error
      mg_log, 'SQL command: %s', sql_cmd, name=log_name, /error
    endif else begin
      mg_log, '%d rows deleted', n_affected_rows, name=log_name, /info
    endelse

    kcor_db_clearday_cleartable, 'kcor_img', $
                                 obsday_index=obsday_index, $
                                 database=db, $
                                 log_name=log_name
    kcor_db_clearday_cleartable, 'kcor_raw', $
                                 obsday_index=obsday_index, $
                                 database=db, $
                                 log_name=log_name
    kcor_db_clearday_cleartable, 'kcor_eng', $
                                 obsday_index=obsday_index, $
                                 database=db, $
                                 log_name=log_name
    kcor_db_clearday_cleartable, 'kcor_sci', $
                                 obsday_index=obsday_index, $
                                 database=db, $
                                 log_name=log_name
  endif

  kcor_db_clearday_cleartable, 'kcor_cal', $
                               obsday_index=obsday_index, $
                               database=db, $
                               log_name=log_name

  done:
  mg_log, 'done', name=log_name, /info
end


; main-level example

if (n_elements(date) eq 0L) then date = '20180208'

run = kcor_run(date, $
               config_filename=filepath('kcor.mgalloy.mahi.latest.cfg', $
                                        subdir=['..', '..', 'config'], $
                                        root=mg_src_root()))

obsday_index = mlso_obsday_insert(date, run=run, database=db)
kcor_db_clearday, run=run, database=db, obsday_index=obsday_index

obj_destroy, db

end
