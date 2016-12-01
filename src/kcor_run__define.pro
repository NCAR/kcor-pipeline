; docformat = 'rst'

;+
; Class representing a KCor processing run.
;-


;= helper methods

;+
; Setup logging.
;
; :Params:
;   date : in, required, type=string
;     date in the form 'YYYYMMDD'
;-
pro kcor_run::setup_loggers, date
  compile_opt strictarr

  ; setup logging
  log_fmt = '%(time)s %(levelshortname)s: %(routine)s: %(message)s'
  log_time_fmt = '(C(CYI4, "-", CMOI2.2, "-", CDI2.2, " " CHI2.2, ":", CMI2.2, ":", CSI2.2))'
  mg_log, name='kcor/cal', logger=logger
  self->getProperty, log_level=log_level, log_dir=log_dir

  if (~file_test(log_dir, /directory)) then file_mkdir, log_dir
  logger->setProperty, format=log_fmt, $
                       time_format=log_time_fmt, $
                       level=log_level, $
                       filename=filepath(date + '.log', root=log_dir)
end


;= property access

;+
; Get properties.
;-
pro kcor_run::getProperty, binary_dir=binary_dir, $
                           mlso_url=mlso_url, $
                           doi_url=doi_url, $
                           npick=npick, $
                           cal_out_dir=cal_out_dir, $
                           raw_basedir=raw_basedir, $
                           process_basedir=process_basedir, $
                           log_dir=log_dir, $
                           log_level=log_level, $
                           database_config_filename=database_config_filename, $
                           database_config_section=database_config_section, $
                           notification_email=notification_email
  compile_opt strictarr

  if (arg_present(binary_dir)) then binary_dir = mg_src_root()

  ; mission
  if (arg_present(mlso_url)) then begin
    mlso_url = self.options->get('mlso_url', section='mission')
  endif
  if (arg_present(doi_url)) then begin
    doi_url = self.options->get('doi_url', section='mission')
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
    database_config_filename =  self.options->get('config_filename', section='database')
  endif
  if (arg_present(database_config_section)) then begin
    database_config_section =  self.options->get('config_section', section='database')
  endif

  ; notifications
  if (arg_present(notification_email)) then begin
    notification_email = self.options->get('email', section='notifications')
  endif
end


;= lifecycle methods

;+
; Free resources.
;-
pro kcor_run::cleanup
  compile_opt strictarr

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

  self.options = mg_read_config(config_filename)

  self->setup_loggers, date

  return, 1
end


;+
; Define instance variables.
;-
pro kcor_run__define
  compile_opt strictarr

  !null = {kcor_run, inherits IDL_Object, $
           options: obj_new()}
end
