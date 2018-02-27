; docformat = 'rst'

;+
; Find the latest `kcor_sw` entry by `proc_date`.
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;   database : in, optional, type=MGdbMySql object
;     database connection to use
;   log_name : in, required, type=string
;     log name to use for logging, i.e., "kcor/rt", "kcor/eod", etc.
;-
function kcor_find_latest_sw, run=run, database=database, log_name=log_name
  compile_opt strictarr

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

  q = 'select * from kcor_sw where proc_date = (select max(proc_date) from kcor_sw)'
  latest_proc_date = db->query(q, fields=fields)

  done:
  if (~obj_valid(database)) then obj_destroy, db

  return, latest_proc_date
end


; main-level example program

date = '20180208'
config_filename = filepath('kcor.mgalloy.mahi.latest.cfg', $
                           subdir=['..', '..', 'config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)

help, kcor_find_latest_sw(run=run, database=database, log_name=log_name)

end
