; docformat = 'rst'

pro kcordbmysql::report_error, sql_statement=sql_cmd, $
                               status=status, $
                               error_message=error_message
  compile_opt strictarr

  if (status ne 0L) then begin
    mg_log, 'error with SQL statement', name=self.logger_name, /error
    mg_log, 'status: %d', status, name=self.logger_name, /error
    mg_log, '%s', error_message, name=self.logger_name, /error
    mg_log, 'SQL command: %s', sql_cmd, name=self.logger_name, /error
  endif
end


pro kcordbmysql::report_warnings, n_warnings=n_warnings
  compile_opt strictarr

  if (n_warnings gt 0L) then begin
    mg_log, '%d warnings', n_warnings, name=self.logger_name, /warn
    warnings = self->query('show warnings', status=status)
    if (status ne 0L) then begin
      mg_log, 'error retrieving warnings', name=self.logger_name, /error
    endif

    for w = 0L, n_warnings - 1L do begin
      mg_log, '%s [%d]: %s', $
              warnings[w].level, warnings[w].code, warnings[w].message, $
              name=self.logger_name, /warn
    endfor
  endif
end


pro kcordbmysql::report_statement, mysql_statement
  compile_opt strictarr

  if (self.lun ge 0L) then printf, self.lun, mysql_statement
end


pro kcordbmysql::setProperty, _extra=e
  compile_opt strictarr

  if (n_elements(e) gt 0L) then self->mgdbmysql::setProperty, _extra=e
end


pro kcordbmysql::getProperty, _ref_extra=e
  compile_opt strictarr

  if (n_elements(e) gt 0) then self->mgdbmysql::getProperty, _strict_extra=e
end


pro kcordbmysql::cleanup
  compile_opt strictarr

  if (self.lun ge 0L) then free_lun, self.lun
  self->mgdbmysql::cleanup
end


function kcordbmysql::init, logger_name=logger_name, $
                            log_filename=log_filename, $
                            _extra=e
  compile_opt strictarr

  status = self->mgdbmysql::init(_extra=e)
  if (status ne 1) then return, status

  if (n_elements(logger_name) gt 0L) then self.logger_name = logger_name

  if (n_elements(log_filename) gt 0L) then begin
    openu, lun, log_filename, /get_lun, /append
    self.lun = lun
  endif else self.lun = -1L

  return, 1
end


pro kcordbmysql__define
  compile_opt strictarr

  !null = { KCordbMySQL, inherits MGdbMySQL, $
            lun: 0L, $
            logger_name: '' }
end


; main-level example

; the below generates a warning because of date_obs has seconds=60
db = kcordbmysql()
db->connect, config_filename='/home/mgalloy/.mysqldb', $
             config_section='mgalloy@webdev'
db->execute, 'insert into kcor_img (file_name, date_obs, date_end, obs_day, carrington_rotation, level, quality, producttype, filetype, numsum, exptime) values (''%s'', ''%s'', ''%s'', %d, %d, %d, %d, %d, %d, %d, %f)', $
             '20131025_171960_kcor_l1', $
             '2013-10-25 17:19:60', $
             '2013-10-25 17:19:44', $
             1300, 2142, 1, 75, 1, 1, 512, 0.0001, $
             status=status
last_insert_id = db->query('select last_insert_id()')
db->execute, 'delete from kcor_img where img_id=%d', last_insert_id.last_insert_id__

obj_destroy, db

end
