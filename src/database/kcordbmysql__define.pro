; docformat = 'rst'

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


function kcordbmysql::init, log_filename=log_filename, _extra=e
  compile_opt strictarr

  status = self->mgdbmysql::init(_extra=e)
  if (status ne 1) then return, status

  if (n_elements(log_filename) gt 0L) then begin
    openu, lun, log_filename, /get_lun, /append
    self.lun = lun
  endif else self.lun = -1L

  return, 1
end


pro kcordbmysql__define
  compile_opt strictarr

  !null = { KCordbMySQL, inherits MGdbMySQL, $
            lun: 0L }
end
