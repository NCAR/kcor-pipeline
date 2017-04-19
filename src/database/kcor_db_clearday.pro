; docformat = 'rst'

;+
; Delete entries for a day, e.g., before reprocessing that day.
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;   obsday_index : in, required, type=integer
;     index into mlso_numfiles database table
;   database : in, optional, type=MGdbMySql object
;     database connection to use
;   log_name : in, required, type=string
;     name of log to send log messages to
;-
pro kcor_db_clearday, run=run, $
                      database=database, $
                      obsday_index=obsday_index, $
                      log_name=log_name
  compile_opt strictarr

  ; Note: The connect procedure accesses DB connection information in the file
  ;       .mysqldb. The "config_section" parameter specifies which group of data
  ;       to use.
  if (obj_valid(database)) then begin
    db = database

    db->getProperty, host_name=host
    mg_log, 'using connection to %s', host, name=log_name, /debug
  endif else begin
    db = mgdbmysql()
    db->connect, config_filename=run.database_config_filename, $
                 config_section=run.database_config_section

    db->getProperty, host_name=host
    mg_log, 'connected to %s...', host, name=log_name, /info
  endelse

  mg_log, 'clearing entries for obsday index %d', obsday_index, $
          name=log_name, /info

  ; zero num_kcor_pb and num_kcor_nrgf in mlso_numfiles
  mg_log, 'zeroing KCor values for mlso_numfiles table', name=log_name, /info
  db->execute, 'UPDATE mlso_numfiles SET num_kcor_pb_fits=''0'', num_kcor_nrgf_fits=''0'', num_kcor_pb_lowresgif=''0'', num_kcor_pb_fullresgif=''0'', num_kcor_nrgf_lowresgif=''0'', num_kcor_nrgf_fullresgif=''0'' WHERE day_id=''%d''', $
               obsday_index, $
               status=status, error_message=error_message, sql_statement=sql_cmd
  if (status ne 0L) then begin
    mg_log, 'error zeroing values in mlso_numfiles table', name=log_name, /error
    mg_log, 'status: %d, error message: %s', status, error_message, $
            name=log_name, /error
    mg_log, 'SQL command: %s', sql_cmd, name=log_name, /error
  endif

  ; kcor_img
  mg_log, 'clearing kcor_img table', name=log_name, /info
  db->execute, 'DELETE FROM kcor_img WHERE obs_day=''%s''', obsday_index, $
               status=status, error_message=error_message, sql_statement=sql_cmd
  if (status ne 0L) then begin
    mg_log, 'error clearing kcor_im table', name=log_name, /error
    mg_log, 'status: %d, error message: %s', status, error_message, $
            name=log_name, /error
    mg_log, 'SQL command: %s', sql_cmd, name=log_name, /error
  endif

  ; kcor_eng
  mg_log, 'clearing kcor_eng table', name=log_name, /info
  db->execute, 'DELETE FROM kcor_eng WHERE obs_day=''%s''', obsday_index, $
               status=status, error_message=error_message, sql_statement=sql_cmd
  if (status ne 0L) then begin
    mg_log, 'error clearing kcor_eng table', name=log_name, /error
    mg_log, 'status: %d, error message: %s', status, error_message, $
            name=log_name, /error
    mg_log, 'SQL command: %s', sql_cmd, name=log_name, /error
  endif

  ; mlso_sgs
  mg_log, 'clearing mlso_sgs table', name=log_name, /info
  db->execute, 'DELETE FROM mlso_sgs WHERE obs_day=''%s'' AND source=''k''', $
               obsday_index, $
               status=status, error_message=error_message, sql_statement=sql_cmd
  if (status ne 0L) then begin
    mg_log, 'error clearing mlso_sgs table', name=log_name, /error
    mg_log, 'status: %d, error message: %s', status, error_message, $
            name=log_name, /error
    mg_log, 'SQL command: %s', sql_cmd, name=log_name, /error
  endif

  ; kcor_cal
  mg_log, 'clearing kcor_cal table', name=log_name, /info
  db->execute, 'DELETE FROM kcor_cal WHERE obs_day=''%s''', $
               obsday_index, $
               status=status, error_message=error_message, sql_statement=sql_cmd
  if (status ne 0L) then begin
    mg_log, 'error clearing kcor_cal table', name=log_name, /error
    mg_log, 'status: %d, error message: %s', status, error_message, $
            name=log_name, /error
    mg_log, 'SQL command: %s', sql_cmd, name=log_name, /error
  endif

  done:
  if (~obj_valid(database)) then obj_destroy, db

  mg_log, 'done', name=log_name, /info
end


; main-level example

date = '20161127'

run = kcor_run(date, $
               config_filename=filepath('kcor.mgalloy.mahi.latest.cfg', $
                                        subdir=['..', '..', 'config'], $
                                        root=mg_src_root()))

obsday_index = mlso_obsday_insert(date, run=run, database=db)
kcor_db_clearday, run=run, database=db, obsday_index=obsday_index

obj_destroy, db

end
