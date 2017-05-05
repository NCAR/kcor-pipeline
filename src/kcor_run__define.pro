; docformat = 'rst'

;+
; Class representing a KCor processing run.
;-


;= API

;+
; Write the values used from the epochs file to the given filename.
;
; :Params:
;   filename : in, optional, type=string, default=stdout
;     filename to write epoch values to, default is to print to stdout
;-
pro kcor_run::write_epochs, filename, time=time
  compile_opt strictarr

  if (n_elements(filename) gt 0L) then begin
    openw, lun, filename, /get_lun
  endif else begin
    lun = -1   ; stdout
  endelse

  printf, lun, $
          'plate_scale', self->epoch('plate_scale', time=time), $
          format='(%"%-30s : %0.3f")'
  printf, lun, $
          'use_default_darks', $
          self->epoch('use_default_darks', time=time) ? 'YES' : 'NO', $
          format='(%"%-30s : %s")'
  printf, lun, $
          'phase', self->epoch('phase', time=time), $
          format='(%"%-30s : %f")'
  printf, lun, $
          'bias', self->epoch('bias', time=time), $
          format='(%"%-30s : %f")'
  printf, lun, $
          'sky_factor', self->epoch('sky_factor', time=time), $
          format='(%"%-30s : %f")'
;  printf, lun, 'bopal', bopal, format='(%"%-30s : %f")'
  printf, lun, $
          'gbuparams_filename', $
          self->epoch('gbuparams_filename', time=time), $
          format='(%"%-30s : %s")'
  printf, lun, $
          'distortion_correction_filename', $
          self->epoch('distortion_correction_filename', time=time), $
          format='(%"%-30s : %s")'
  printf, lun, $
          'cal_file', self->epoch('cal_file', time=time), $
          format='(%"%-30s : %s")'
  printf, lun, $
          'mlso_url', self->epoch('mlso_url', time=time), $
          format='(%"%-30s : %s")'
  printf, lun, $
          'doi_url', self->epoch('doi_url', time=time), $
          format='(%"%-30s : %s")'

  if (n_elements(filename) gt 0L) then free_lun, lun
end


;= helper methods

;+
; Lookup a value for a single parameter based on the date in the `epochs.cfg`
; configuration file.
;
; :Private:
;
; :Returns:
;   returns a string by default, unless `TYPE` (or `BOOLEAN`, `FLOAT`, etc.) is
;   specified
;
; :Params:
;   option : in, required, type=string
;     option name
;   date : in, required, type=string
;     date on which to check for the value in the form "YYYYMMDD"
;   time : in, required, type=string
;     time on which to check for the value in the form "HHMMSS"
;
; :Keywords:
;   found : out, optional, type=boolean
;     set to a named variable to retrieve whether the option was found
;   type : in, optional, type=integer
;     `SIZE` type to retrieve value as
;   _extra : in, optional, type=keywords
;     keywords to `MGffOptions::get` such as `BOOLEAN` and `EXTRACT`
;-
function kcor_run::_readepoch, option, date, time, $
                               found=found, $
                               type=type, $
                               _extra=e
  compile_opt strictarr

  found = 1B
  dates = self.epochs->sections()
  dates = dates[sort(dates)]
  date_index = value_locate(dates, date + '.' + time)

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
;-
pro kcor_run::setup_loggers
  compile_opt strictarr

  ; setup logging
  log_fmt = '%(time)s %(levelshortname)s: %(routine)s: %(message)s'
  log_time_fmt = '(C(CYI4, "-", CMOI2.2, "-", CDI2.2, " " CHI2.2, ":", CMI2.2, ":", CSI2.2))'

  self->getProperty, log_level=log_level, log_dir=log_dir
  if (~file_test(log_dir, /directory)) then file_mkdir, log_dir

  mg_log, name='kcor', logger=logger
  logger->setProperty, format=log_fmt, $
                       time_format=log_time_fmt, $
                       level=log_level, $
                       filename=filepath(self.date + '.log', root=log_dir)

  mg_log, name='kcor/cal', logger=logger
  logger->setProperty, format=log_fmt, $
                       time_format=log_time_fmt, $
                       level=log_level, $
                       filename=filepath(self.date + '.eod.log', root=log_dir)

  mg_log, name='kcor/eod', logger=logger
  logger->setProperty, format=log_fmt, $
                       time_format=log_time_fmt, $
                       level=log_level, $
                       filename=filepath(self.date + '.eod.log', root=log_dir)

  mg_log, name='kcor/rt', logger=logger
  logger->setProperty, format=log_fmt, $
                       time_format=log_time_fmt, $
                       level=log_level, $
                       filename=filepath(self.date + '.realtime.log', root=log_dir)

  mg_log, name='kcor/noformat', logger=logger
  logger->setProperty, format='%(message)s', $
                       level=log_level, $
                       filename=filepath(self.date + '.realtime.log', root=log_dir)

  mg_log, name='kcor/reprocess', logger=logger
  logger->setProperty, format=log_fmt, $
                       time_format=log_time_fmt, $
                       level=log_level, $
                       filename=filepath(self.date + '.reprocess.log', root=log_dir)
end


;= property access

;+
; Set properties.
;-
pro kcor_run::setProperty, time=time, mode=mode
  compile_opt strictarr

  if (n_elements(mode) gt 0L) then begin
    self.mode = mode
  endif

  if (n_elements(time) gt 0L) then begin
    if (strlen(time) eq 6) then begin
      self.time = kcor_ut2hst(time)
    endif else begin
      hour   = strmid(time, 11, 2)
      minute = strmid(time, 14, 2)
      second = strmid(time, 17, 2)
      self.time = kcor_ut2hst(hour + minute + second)
    endelse
    log_name = self.mode eq 'realtime' ? 'kcor/rt' : 'kcor/eod'
  endif
end


;+
; Get properties.
;-
pro kcor_run::getProperty, config_contents=config_contents, $
                           date=date, $
                           pipe_dir=pipe_dir, $
                           resources_dir=resources_dir, $
                           gzip=gzip, $
                           gunzip=gunzip, $
                           npick=npick, $
                           cal_basedir=cal_basedir, $
                           cal_out_dir=cal_out_dir, $
                           bias_dir=bias_dir, $
                           flat_dir=flat_dir, $
                           mask_dir=mask_dir, $
                           raw_basedir=raw_basedir, $
                           process_basedir=process_basedir, $
                           lock_raw=lock_raw, $
                           archive_basedir=archive_basedir, $
                           movie_dir=movie_basedir, $
                           fullres_basedir=fullres_basedir, $
                           croppedgif_basedir=croppedgif_basedir, $
                           nrgf_basedir=nrgf_basedir, $
                           nrgf_remote_dir=nrgf_remote_dir, $
                           nrgf_remote_server=nrgf_remote_server, $
                           hpss_gateway=hpss_gateway, $
                           log_dir=log_dir, $
                           log_level=log_level, $
                           database_config_filename=database_config_filename, $
                           database_config_section=database_config_section, $
                           notification_email=notification_email, $
                           send_notifications=send_notifications, $
                           update_database=update_database, $
                           update_remote_server=update_remote_server, $
                           reduce_calibration=reduce_calibration, $
                           send_to_hpss=send_to_hpss
  compile_opt strictarr

  if (arg_present(config_contents)) then begin
    config_contents = reform(self.options->_toString(/substitute))
  endif

  if (arg_present(date)) then date = self.date
  if (arg_present(pipe_dir)) then pipe_dir = self.pipe_dir
  if (arg_present(resources_dir)) then begin
    resources_dir = filepath('resources', root=self.pipe_dir)
  endif

  ; externals
  if (arg_present(gzip)) then begin
    gzip = self.options->get('gzip', section='externals')
  endif
  if (arg_present(gunzip)) then begin
    gunzip = self.options->get('gunzip', section='externals')
  endif

  ; calibration
  if (arg_present(npick)) then begin
    npick = self.options->get('npick', section='calibration', $
                              type=3, default=10000L)
  endif
  if (arg_present(cal_basedir)) then begin
    cal_basedir = self.options->get('basedir', section='calibration')
  endif
  if (arg_present(cal_out_dir)) then begin
    cal_out_dir = self.options->get('out_dir', section='calibration')
  endif
  if (arg_present(bias_dir)) then begin
    bias_dir = self.options->get('bias_dir', section='calibration')
  endif
  if (arg_present(flat_dir)) then begin
    flat_dir = self.options->get('flat_dir', section='calibration')
  endif
  if (arg_present(mask_dir)) then begin
    mask_dir = self.options->get('mask_dir', section='calibration')
  endif

  ; processing
  if (arg_present(raw_basedir)) then begin
    raw_basedir = self.options->get('raw_basedir', section='processing')
  endif
  if (arg_present(process_basedir)) then begin
    process_basedir = self.options->get('process_basedir', section='processing')
  endif
  if (arg_present(lock_raw)) then begin
    lock_raw = self.options->get('lock_raw', section='processing', /boolean, $
                                 default=1B)
  endif

  ; results
  if (arg_present(archive_basedir)) then begin
    archive_basedir = self.options->get('archive_basedir', section='results')
  endif
  if (arg_present(movie_basedir)) then begin
    movie_basedir = self.options->get('movie_basedir', section='results')
  endif
  if (arg_present(fullres_basedir)) then begin
    fullres_basedir = self.options->get('fullres_basedir', section='results')
  endif
  if (arg_present(croppedgif_basedir)) then begin
    croppedgif_basedir = self.options->get('croppedgif_basedir', section='results')
  endif
  if (arg_present(nrgf_basedir)) then begin
    nrgf_basedir = self.options->get('nrgf_basedir', section='results')
  endif
  if (arg_present(nrgf_remote_dir)) then begin
    nrgf_remote_dir = self.options->get('nrgf_remote_dir', section='results')
  endif
  if (arg_present(nrgf_remote_server)) then begin
    nrgf_remote_server = self.options->get('nrgf_remote_server', section='results')
  endif
  if (arg_present(hpss_gateway)) then begin
    hpss_gateway = self.options->get('hpss_gateway', section='results')
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
  if (arg_present(update_database)) then begin
    update_database = self.options->get('update_database', section='database', $
                                        /boolean, default=1B)
  endif
  if (arg_present(database_config_filename)) then begin
    database_config_filename = self.options->get('config_filename', section='database')
  endif
  if (arg_present(database_config_section)) then begin
    database_config_section = self.options->get('config_section', section='database')
  endif

  ; notifications
  if (arg_present(notification_email)) then begin
    notification_email = self.options->get('email', section='notifications', default='')
  endif
  if (arg_present(send_notifications)) then begin
    send_notifications = self.options->get('send_notifications', section='notifications', $
                                           /boolean, default=1B)
  endif

  ; realtime
  if (arg_present(update_remote_server)) then begin
    update_remote_server = self.options->get('update_remote_server', section='realtime', $
                                             /boolean, default=1B)
  endif

  ; end-of-day
  if (arg_present(reduce_calibration)) then begin
    reduce_calibration = self.options->get('reduce_calibration', section='eod', $
                                           /boolean, default=1B)
  endif
  if (arg_present(send_to_hpss)) then begin
    send_to_hpss = self.options->get('send_to_hpss', section='eod', $
                                     /boolean, default=1B)
  endif
end


;+
; Get epoch value.
;
; :Params:
;   name : in, required, type=string
;     name of epoch entity to query for
;
; :Keywords:
;   time : in, required, type=string
;     time at which epoch value is requested as UT time in the form "HHMMSS"
;-
function kcor_run::epoch, name, time=time
  compile_opt strictarr

  ; times in the epoch file are in HST (observing days)
  if (n_elements(time) eq 0L) then begin
    hst_time = self.time eq '' ? '000000' : self.time
  endif else begin
    hst_time = kcor_ut2hst(time)
  endelse

  case name of
    'mlso_url': return, self->_readepoch('mlso_url', self.date, hst_time, type=7) 
    'doi_url': return, self->_readepoch('doi_url', self.date, hst_time, type=7)
    'plate_scale': return, self->_readepoch('plate_scale', self.date, hst_time, type=4)
    'use_default_darks': begin
        return, self->_readepoch('use_default_darks', self.date, hst_time, /boolean)
      end
    'gpuparams_filename': begin
        return, self->_readepoch('gbuparams_filename', self.date, hst_time, type=7)
      end
    'skypol_bias': return, self->_readepoch('skypol_bias', self.date, hst_time, type=4)
    'sky_factor': return, self->_readepoch('sky_factor', self.date, hst_time, type=4) 
    'distortion_correction_filename': begin
        return, self->_readepoch('distortion_correction_filename', $
                                 self.date, hst_time, type=7)
      end
    'cal_file': return, self->_readepoch('cal_file', self.date, hst_time, type=7)
    '01id': return, self->_readepoch('01id', self.date, hst_time, type=7)
    'default_occulter_size' : return, self->_readepoch('default_occulter_size', $
                                                       self.date, hst_time, type=4)
    'use_default_occulter_size': return, self->_readepoch('use_default_occulter_size', $
                                                          self.date, hst_time, /boolean)
    'header_changes': return, self->_readepoch('header_changes', $
                                               self.date, hst_time, /boolean)
    'mk4-opal': return, self->_readepoch('mk4-opal', self.date, hst_time, type=4) 
    'POC-L10P6-10-1': return, self->_readepoch('POC-L10P6-10-1', self.date, hst_time, type=4) 
  endcase
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
  self.pipe_dir = file_expand_path(filepath('..', root=mg_src_root()))

  if (~file_test(config_filename)) then return, 0
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
           time: '', $   ; UT time
           mode: '', $   ; realtime or eod
           pipe_dir: '', $
           options: obj_new(), $
           epochs: obj_new()}
end
