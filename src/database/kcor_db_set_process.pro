; docformat = 'rst'

;+
; Set the process status for the day to "processed" or "processing". Inserts
; the day, if there isn't already a row for the given date.
;
; :Params:
;   process_state : in, required, type=string
;     must be either "processed" or "processing", exactly
;   run : in, required, type=object
;     KCor run object
;
; :Keywords:
;   status : out, optional, type=long
;     set to a named variable to retrieve the status of the database connection,
;     0 for success
;   logger_name : in, optional, type=string
;     name of logger
;-
pro kcor_db_set_process, process_state, run, status=status
  compile_opt strictarr

  if (process_state ne 'processed' and process_state ne 'processing') then begin
    message, string(process_state, format='invalid process state: %s')
  endif

  status = 0L

  if (~run->config('database/update')) then begin
    mg_log, 'not setting state to ''%s''', process_state, name=run.logger_name, /info
    goto, done
  endif

  db = kcordbmysql()
  db->connect, config_filename=run->config('database/config_filename'), $
              config_section=run->config('database/config_section')

  date = run.date
  hdate = string(strmid(date, 0, 4), strmid(date, 4, 2), strmid(date, 6, 2), $
                 format='%s-%s-%s')

  obsday_id = mlso_obsday_insert(date, $
                                 run=run, $
                                 database=db, $
                                 status=db_status, $
                                 log_name=run.logger_name)
  if (db_status ne 0L) then begin
    status or= db_status
    goto, done
  endif

  kcor_sw_insert, date, run=run, $
                  database=db, $
                  sw_index=sw_id, $
                  log_name=run.logger_name

  hostname = mg_hostname()
  iso_format = '(C(CYI, "-", CMOI02, "-", CDI02, "T", CHI02, ":", CMI02, ":", CSI02))'
  now = string(systime(/julian), format=iso_format)

  q = 'select process_id from kcor_process where obsday_id=%d limit 1;'
  processes = db->query(q, obsday_id, status=db_status, count=n_processes)
  if (status ne 0L) then begin
    status or= db_status
    goto, done
  endif

  if (n_processes eq 0L) then begin
    mg_log, 'inserting a new row into kcor_process...', name=run.logger_name, /info
    cmd = 'insert into kcor_process (obsday_id, kcor_sw_id, date_processed, status, hostname) values (%d, %d, ''%s'', ''%s'', ''%s'')'
    db->execute, cmd, obsday_id, sw_id, now, process_state, hostname, status=db_status
  endif else begin
    process_id = processes[0].process_id
    mg_log, 'updating row in kcor_process to %s...', process_state, $
            name=run.logger_name, /info
    cmd = 'update kcor_process set kcor_sw_id=%d, date_processed=''%s'', status=''%s'', hostname=''%s'' where process_id=%d'
    db->execute, cmd, sw_id, now, process_state, hostname, process_id, status=db_status
  endelse

  status or= db_status

  done:
  obj_destroy, db
end
