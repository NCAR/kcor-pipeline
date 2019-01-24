; docformat = 'rst'

;+
; Insert a value into the MLSO kcor_sw database table.
;
; :Params:
;   date : in, type=string
;     date in the form 'YYYYMMDD'
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;   database : in, optional, type=MGdbMySql object
;     database connection to use
;   log_name : in, required, type=string
;     log name to use for logging, i.e., "kcor/rt", "kcor/eod", etc.
;   sw_index : out, optional, type=long
;     set to a named variable to retrieve the kcor_sw table index of the entry
;     just added
;
; :Examples:
;   For example::
;
;     kcor_sw_insert, '20170204', run=run, obsday_index=obsday_index
;
;
; :Author: 
;   Andrew Stanger
;   HAO/NCAR  K-coronagraph
;
; :History:
;   11 Sep 2015 IDL procedure created.
;               Use /hao/mlsodata1/Data/KCor/raw/yyyymmdd for L1 fits files.
;   15 Sep 2015 Use /hao/acos/year/month/day directory    for L1 fits files.
;   28 Sep 2015 Remove bitpix, xdim, ydim fields.
;   15 Mar 2017 Edits by D Kolinski to align inserts with kcor_sw db table and
;               to check for changes in field values compared to previous
;               database entries to determine whether a new entry is needed.
;-
pro kcor_sw_insert, date, run=run, $
                    database=database, $
                    sw_index=sw_index, $
                    log_name=log_name
  compile_opt strictarr
  on_error, 2

  ; connect to MLSO database.

  ; Note: The connect procedure accesses DB connection information in the file
  ;       .mysqldb. The "config_section" parameter specifies
  ;       which group of data to use.

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

  sw_index = 0L   ; updated with correct index if all goes well
  sw_version = kcor_find_code_version(revision=sw_revision)

  date_format = '(C(CYI, "-", CMOI2.2, "-", CDI2.2, "T", CHI2.2, ":", CMI2.2, ":", CSI2.2))'
  proc_date = string(julday(), format=date_format)

  ; check to see if passed observation day date is already in the kcor_sw table
  q = 'select count(sw_id) from kcor_sw where sw_version=''%s'' and sw_revision=''%s'''
  sw_id_results = db->query(q, sw_version, sw_revision)
  sw_id_count = sw_id_results.count_sw_id_

  if (sw_id_count eq 0L) then begin
    mg_log, 'inserting a new kcor_sw row', name=log_name, /info

    fields = ['date', $
              'proc_date', $
              'sw_version', $
              'sw_revision']
    db->execute, 'INSERT INTO kcor_sw (%s) VALUES (''%s'', ''%s'', ''%s'', ''%s'') ', $
                 strjoin(fields, ', '), $
                 date, $
                 proc_date, $
                 sw_version, $
                 sw_revision, $
                 status=status, error_message=error_message, sql_statement=sql_cmd
    if (status ne 0L) then begin
      mg_log, '%d, error message: %s', status, error_message, $
              name=log_name, /error
      mg_log, 'sql_cmd: %s', sql_cmd, name=log_name, /error
    endif

    sw_index  = db->query('select last_insert_id()')
  endif else begin
    ; if it is in the database, get the corresponding sw_id
    q = 'select sw_id from kcor_sw where sw_version=''%s'' and sw_revision=''%s'''
    sw_results = db->query(q, sw_version, sw_revision)
    sw_index = sw_results.sw_id
  endelse

  done:
  if (~obj_valid(database)) then obj_destroy, db
  mg_log, 'done', name=log_name, /info
end


; main-level example program

date = '20180208'
config_filename = filepath('kcor.mgalloy.mahi.latest.cfg', $
                           subdir=['..', '..', 'config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)

obsday_index = mlso_obsday_insert(date, run=run, database=db)
kcor_sw_insert, date, l1_files, run=run, database=db, obsday_index=obsday_index

obj_destroy, run

end