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
;   database : in, optional, type=MGdbMySql object
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
  db->execute, 'DELETE FROM %s WHERE obs_day=%d', $
               table, obsday_index, $
               status=status, error_message=error_message, sql_statement=sql_cmd, $
               n_affected_rows=n_affected_rows
  if (status ne 0L) then begin
    mg_log, 'error clearing %s table', table, name=log_name, /error
    mg_log, 'status: %d, error message: %s', status, error_message, $
            name=log_name, /error
    mg_log, 'SQL command: %s', sql_cmd, name=log_name, /error
  endif else begin
    mg_log, '%d rows deleted', n_affected_rows, name=log_name, /info
  endelse
end


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
;   calibration : in, optional, type=boolean
;     set to just clear the calibration for a day
;-
pro kcor_db_clearday, run=run, $
                      database=database, $
                      obsday_index=obsday_index, $
                      log_name=log_name, $
                      calibration=calibration
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
                            'nrgf_extavg_fits', $
                            'nrgf_lowresgif', $
                            'nrgf_fullresgif']
    fields_expression = strjoin(fields + '=0', ', ')
    db->execute, 'UPDATE mlso_numfiles SET %s WHERE day_id=''%d''', $
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
    db->execute, 'DELETE FROM mlso_sgs WHERE obs_day=''%s'' AND source=''k''', $
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
    kcor_db_clearday_cleartable, 'kcor_eng', $
                                 obsday_index=obsday_index, $
                                 database=db, $
                                 log_name=log_name
    kcor_db_clearday_cleartable, 'kcor_sci', $
                                 obsday_index=obsday_index, $
                                 database=db, $
                                 log_name=log_name

    ; kcor_sw (must do after kcor_eng)
;    mg_log, 'clearing kcor_sw table', name=log_name, /info
;    db->execute, 'DELETE FROM kcor_sw WHERE date=''%s''', $
;                 day[0].obs_day, $
;                 status=status, error_message=error_message, sql_statement=sql_cmd, $
;                 n_affected_rows=n_affected_rows
;    if (status ne 0L) then begin
;      mg_log, 'error clearing kcor_sw table', name=log_name, /error
;      mg_log, 'status: %d, error message: %s', status, error_message, $
;              name=log_name, /error
;      mg_log, 'SQL command: %s', sql_cmd, name=log_name, /error
;    endif else begin
;      mg_log, '%d rows deleted', n_affected_rows, name=log_name, /info
;    endelse
  endif

  kcor_db_clearday_cleartable, 'kcor_cal', $
                               obsday_index=obsday_index, $
                               database=db, $
                               log_name=log_name

  done:
  if (~obj_valid(database)) then obj_destroy, db
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
