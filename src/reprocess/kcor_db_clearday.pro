; docformat = 'rst'

;+
; Remove the entries in the database for a given date.
;
; :Params:
;   db : in, required, type=MGdbMySQL object
;     database object
;   date : in, required, type=string
;     date to process in the form "YYYYMMDD"
;   db_name : in, required, type=string
;     database name to remove entries from
;-
pro kcor_db_clearday, db, date, db_name
  compile_opt strictarr

  year    = strmid(date, 0, 4)   ; yyyy
  month   = strmid(date, 4, 2)   ; mm
  day     = strmid(date, 6, 2)   ; dd

  db->execute, 'DELETE FROM %s WHERE date_obs like ''%s''', $
               db_name, string(year, month, day, format='(%"%s-%s-%s%%")'), $
               status=status, $
               error_message=error_message, $
               sql_statement=sql_cmd
  if (status eq 0L) then begin
    mg_log, '%s database cleared for %s', db_name, date, $
            name='kcor/reprocess', /info
  endif else begin
    mg_log, 'sql_cmd: %s', sql_cmd, name='kcor/reprocess', /warn
    mg_log, 'status: %d, error message: %s', status, error_message, $
            name='kcor/reprocess', /warn
  endelse
end
