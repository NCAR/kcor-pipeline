; docformat = 'rst'

;+
; Class representing a KCor processing run.
;-


;= helper methods

;+
; Lookup a value for a single parameter based on the date in the `epochs.cfg`
; configuration file.
;
; :Private:
;
; :Returns:
;   by default returns a string, unless `TYPE` is specified
;
; :Params:
;   option : in, required, type=string
;     option name
;   date : in, required, type=string
;     date on which to check for the value in the form "YYYYMMDD"
;
; :Keywords:
;   found : out, optional, type=boolean
;     set to a named variable to retrieve whether the option was found
;   type : in, optional, type=integer
;     `SIZE` type to retrieve value as
;   _extra : in, optional, type=keywords
;     keywords to `MGffOptions::get` such as `BOOLEAN` and `EXTRACT`
;-
function kcor_run::_readepoch, option, date, $
                               found=found, $
                               type=type, $
                               _extra=e
  compile_opt strictarr

  found = 1B
  dates = self.epochs->sections()
  dates = dates[sort(dates)]
  date_index = value_locate(dates, date)
  for d = date_index, 0L, -1L do begin
    option_value = self.epochs->get(option, section=dates[d], $
                                    found=option_found, type=type, _extra=e)
    if (option_found) then begin
      return, option_value
    endif
  endfor

  found = 0B
  return, !null
end


;+
; Setup logging.
;
; :Params:
;   date : in, required, type=string
;     date in the form 'YYYYMMDD'
;-
pro kcor_run::setup_loggers
  compile_opt strictarr

  ; setup logging
  log_fmt = '%(time)s %(levelshortname)s: %(routine)s: %(message)s'
  cal_log_fmt = '%(time)s %(levelshortname)s: %(message)s'
  log_time_fmt = '(C(CYI4, "-", CMOI2.2, "-", CDI2.2, " " CHI2.2, ":", CMI2.2, ":", CSI2.2))'

  self->getProperty, log_level=log_level, log_dir=log_dir
  if (~file_test(log_dir, /directory)) then file_mkdir, log_dir

  mg_log, name='kcor', logger=logger
  logger->setProperty, format=log_fmt, $
                       time_format=log_time_fmt, $
                       level=log_level, $
                       filename=filepath(self.date + '.log', root=log_dir)

  mg_log, name='kcor/cal', logger=logger
  logger->setProperty, format=cal_log_fmt, $
                       time_format=log_time_fmt, $
                       level=log_level, $
                       filename=filepath(self.date + '.calibration.log', root=log_dir)

  mg_log, name='kcor/eod', logger=logger
  logger->setProperty, format=log_fmt, $
                       time_format=log_time_fmt, $
                       level=log_level, $
                       filename=filepath(self.date + '.eod.log', root=log_dir)

  mg_log, name='kcor/dbinsert', logger=logger
  logger->setProperty, format=log_fmt, $
                       time_format=log_time_fmt, $
                       level=log_level, $
                       filename=filepath(self.date + '.dbinsert.log', root=log_dir)
end


;= property access

;+
; Get properties.
;-
pro kcor_run::getProperty, binary_dir=binary_dir, $
                           mlso_url=mlso_url, $
                           doi_url=doi_url, $
                           gunzip=gunzip, $
                           npick=npick, $
                           cal_out_dir=cal_out_dir, $
                           raw_basedir=raw_basedir, $
                           process_basedir=process_basedir, $
                           archive_dir=archive_dir, $
                           log_dir=log_dir, $
                           log_level=log_level, $
                           database_config_filename=database_config_filename, $
                           database_config_section=database_config_section, $
                           notification_email=notification_email, $
                           update_database=update_database, $
                           use_default_darks=use_default_darks
  compile_opt strictarr

  if (arg_present(binary_dir)) then binary_dir = mg_src_root()

  ; mission
  if (arg_present(mlso_url)) then begin
    mlso_url = self.options->get('mlso_url', section='mission')
  endif
  if (arg_present(doi_url)) then begin
    doi_url = self.options->get('doi_url', section='mission')
  endif

  ; externals
  if (arg_present(gunzip)) then begin
    gunzip = self.options->get('gunzip', section='externals')
  endif

  ; calibration
  if (arg_present(npick)) then begin
    npick = self.options->get('npick', section='calibration', $
                              type=3, default=10000L)
  endif
  if (arg_present(cal_out_dir)) then begin
    cal_out_dir = self.options->get('out_dir', section='calibration')
  endif

  ; processing
  if (arg_present(raw_basedir)) then begin
    raw_basedir = self.options->get('raw_basedir', section='processing')
  endif
  if (arg_present(process_basedir)) then begin
    process_basedir = self.options->get('process_basedir', section='processing')
  endif

  ; results
  if (arg_present(archive_dir)) then begin
    archive_dir = self.options->get('archive_dir', section='results')
  endif

  ; logging
  if (arg_present(log_dir)) then begin
    log_dir = self.options->get('log_dir', section='logging')
  endif
  if (arg_present(log_level)) then begin
    log_level = self.options->get('level', section='logging', $
                                  type=3, default=4L)
  endif

  ; database
  if (arg_present(database_config_filename)) then begin
    database_config_filename = self.options->get('config_filename', section='database')
  endif
  if (arg_present(database_config_section)) then begin
    database_config_section = self.options->get('config_section', section='database')
  endif

  ; notifications
  if (arg_present(notification_email)) then begin
    notification_email = self.options->get('email', section='notifications')
  endif

  ; actions
  if (arg_present(update_database)) then begin
    update_database = self.options->get('update_database', section='actions', $
                                        /boolean, default=1B)
  endif

  ; epochs file
  if (arg_present(use_default_darks)) then begin
    use_default_darks = self->_readepoch('use_default_darks', self.date, /boolean)
  endif
end


;= lifecycle methods

;+
; Free resources.
;-
pro kcor_run::cleanup
  compile_opt strictarr

  mg_log, /quit
  obj_destroy, self.options
end


;+
; Create `kcor_run` object.
;
; :Returns:
;   1 if successful, 0 otherwise
;
; :Params:
;   date : in, required, type=string
;     date in the form 'YYYYMMDD'
;-
function kcor_run::init, date, config_filename=config_filename
  compile_opt strictarr

  self.date = date

  self.options = mg_read_config(config_filename)
  self.epochs = mg_read_config(filepath('epochs.cfg', root=mg_src_root()))

  self->setup_loggers

  return, 1
end


;+
; Define instance variables.
;-
pro kcor_run__define
  compile_opt strictarr

  !null = {kcor_run, inherits IDL_Object, $
           date: '', $
           options: obj_new(), $
           epochs: obj_new()}
end
