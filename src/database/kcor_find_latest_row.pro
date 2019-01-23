; docformat = 'rst'

;+
; Find the latest row of the kcor_hw table.
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;   database : in, optional, type=MGdbMySql object
;     database connection to use
;   log_name : in, required, type=string
;     log name to use for logging, i.e., "kcor/rt", "kcor/eod", etc.
;-
function kcor_find_latest_row, run=run, database=database, $
                               log_name=log_name, $
                               error=error
  compile_opt strictarr

  error = 0L

  if (obj_valid(database)) then begin
    db = database

    db->getProperty, host_name=host
    mg_log, 'using connection to %s', host, name=log_name, /debug
  endif else begin
    db = mgdbmysql()
    db->connect, config_filename=run.database_config_filename, $
                 config_section=run.database_config_section

    db->getProperty, host_name=host
    mg_log, 'connected to %s', host, name=log_name, /info
  endelse

  q = 'select * from kcor_hw where date = (select max(date) from kcor_hw)'
  latest_proc_date = db->query(q, status=status, error_message=error_msg)

  if (status ne 0L) then begin
    error = 1L
    mg_log, 'problem querying database', name=logger_name, /error
    mg_log, error_msg, name=logger_name, /error

    return, !null
  endif

  done:
  if (~obj_valid(database)) then obj_destroy, db

  return, n_elements(latest_proc_date) eq 0L ? !null : latest_proc_date[0]
end


; main-level example program

date = '20180208'
config_filename = filepath('kcor.mgalloy.mahi.latest.cfg', $
                           subdir=['..', '..', 'config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)

help, kcor_find_latest_sw(run=run, database=database, log_name=log_name)

end
