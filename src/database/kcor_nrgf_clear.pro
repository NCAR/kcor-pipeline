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
pro kcor_nrgf_clear, run=run, $
                     database=db, $
                     obsday_index=obsday_index, $
                     log_name=log_name
  compile_opt strictarr

  mg_log, 'clearing NRGF from kcor_img table', name=log_name, /info
  db->execute, 'DELETE FROM kcor_img WHERE producttype=''nrgf'' AND obs_day=%d', $
               obsday_index, $
               status=status, error_message=error_message, sql_statement=sql_cmd
  if (status ne 0L) then begin
    mg_log, 'error clearing kcor_img table', name=log_name, /error
    mg_log, 'status: %d, error message: %s', status, error_message, $
            name=log_name, /error
    mg_log, 'SQL command: %s', sql_cmd, name=log_name, /error
  endif

  db->execute, 'UPDATE mlso_numfiles SET num_kcor_nrgf_fits=''%d'', num_kcor_nrgf_lowresgif=''%d'', num_kcor_nrgf_fullresgif=''%d'' WHERE day_id=''%d''', $
               0, 0, 0, $
               obsday_index, $
               status=status, error_message=error_message, sql_statement=sql_cmd
  if (status ne 0L) then begin
    mg_log, 'error updating mlso_numfiles table', name=log_name, /error
    mg_log, 'status: %d, error message: %s', status, error_message, $
            name=log_name, /error
    mg_log, 'SQL command: %s', sql_cmd, name=log_name, /error
  endif

end
