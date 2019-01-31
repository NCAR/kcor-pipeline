; docformat = 'rst'

;+
; Class representing a KCor processing run.
;-

;+
; Find a pipeline generated calibration file that is the closest, but not later
; than given date/time.
;
; :Returns:
;   string, base filename of calibration file or '' for not found
;
; :Params:
;   date : in, required, type=string
;     date to check for, in the form "YYYYMMDD"
;   hst_time : in, required, type=string
;     HST time to check for, in the form "HHMMSS"
;-
function kcor_run::_find_calfile, date, hst_time
  compile_opt strictarr

  re = '([[:digit:]]{8})_([[:digit:]]{6})_kcor_cal.*.\.ncdf'
  self->getProperty, cal_out_dir=cal_out_dir
  epoch_version = self->epoch('cal_epoch_version')

  cal_format = '(%"*kcor_cal_v%s_*.ncdf")'
  cal_search_spec = filepath(string(epoch_version, format=cal_format), $
                             root=cal_out_dir)

  calfiles = file_basename(file_search(cal_search_spec, count=n_calfiles))

  now_date = long(kcor_decompose_date(date))
  now_time = long(kcor_decompose_time(hst_time))
  ; remember to add 10 hours for HST to UT conversion
  now = julday(now_date[1], now_date[2], now_date[0], $
               now_time[0] + 10, now_time[1], now_time[2])

  closest_file = ''
  time_diff = 1000.0D   ; start with 1000 day old file

  ; loop through files to find closest
  for c = 0L, n_calfiles - 1L do begin
    if (stregex(calfiles[c], re, /boolean)) then begin
      tokens = stregex(calfiles[c], re, /subexpr, /extract)
      cal_date = long(kcor_decompose_date(tokens[1]))
      cal_time = long(kcor_decompose_time(tokens[2]))
      jd = julday(cal_date[1], cal_date[2], cal_date[0], $
                  cal_time[0], cal_time[1], cal_time[2])
      if (abs(now - jd) lt time_diff) then begin
        closest_file = calfiles[c]
        time_diff = now - jd
      endif
    endif
  endfor

  return, closest_file
end


;= API

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

  if (n_elements(time) gt 0L) then begin
    hst_time = kcor_ut2hst(time)
    datetime = self.date + '.' + hst_time
  endif

  if (strlowcase(name) eq 'cal_file') then begin
    if (self.epochs->get('use_pipeline_calfiles', datetime=datetime)) then begin
      if (n_elements(datetime) eq 0L) then begin
        dt = self.epochs.datetime
        datetime = dt->strftime('%Y%m%d.%H%M%S')
      endif

      return, self->_find_calfile(self.date, hst_time)
    endif
  endif

  value = self.epochs->get(name, datetime=datetime)

  return, value
end


;+
; Get a config file value.
;
; :Returns:
;   value of the correct type
;
; :Params:
;   name : in, required, type=string
;     section and option name in the form "section/option"
;-
function kcor_run::config, name
  compile_opt strictarr
  on_error, 2

  tokens = strsplit(name, '/', /extract, count=n_tokens)
  if (n_tokens ne 2) then message, 'bad format for config option name'

  value = self.options->get(tokens[1], section=tokens[0], found=found)

  return, value
end


;= helper methods

;+
; Setup logging.
;
; :Keywords:
;   rotate_logs : in, optional, type=boolean
;     set to rotate logs
;-
pro kcor_run::setup_loggers, rotate_logs=rotate_logs
  compile_opt strictarr

  ; setup logging
  log_fmt = '%(time)s %(levelshortname)s: %(routine)s: %(message)s'
  log_time_fmt = '(C(CYI4, "-", CMOI2.2, "-", CDI2.2, " " CHI2.2, ":", CMI2.2, ":", CSI2.2))'

  self->getProperty, log_level=log_level, log_dir=log_dir
  if (~file_test(log_dir, /directory)) then file_mkdir, log_dir

  self->getProperty, max_log_version=max_log_version, mode=mode, reprocess=reprocess

  mg_log, name='kcor/cal', logger=logger
  log_filename = filepath(self.date + '.eod.log', root=log_dir)
  if (keyword_set(rotate_logs) && mode eq 'eod') then begin
    mg_rotate_log, log_filename, max_version=max_log_version
  endif
  logger->setProperty, format=log_fmt, $
                       time_format=log_time_fmt, $
                       level=log_level, $
                       filename=log_filename

  mg_log, name='kcor/eod', logger=logger
  log_filename = filepath(self.date + '.eod.log', root=log_dir)
  if (keyword_set(rotate_logs) && mode eq 'eod') then begin
    mg_rotate_log, log_filename, max_version=max_log_version
  endif
  logger->setProperty, format=log_fmt, $
                       time_format=log_time_fmt, $
                       level=log_level, $
                       filename=log_filename

  mg_log, name='kcor/rt', logger=logger
  log_filename = filepath(self.date + '.realtime.log', root=log_dir)
  if (keyword_set(rotate_logs) && mode eq 'realtime') then begin
    mg_rotate_log, log_filename, max_version=max_log_version
  endif
  logger->setProperty, format=log_fmt, $
                       time_format=log_time_fmt, $
                       level=log_level, $
                       filename=log_filename

  mg_log, name='kcor/noformat', logger=logger
  log_filename = filepath(self.date + '.realtime.log', root=log_dir)
  if (keyword_set(rotate_logs) && mode eq 'realtime') then begin
    mg_rotate_log, log_filename, max_version=max_log_version
  endif
  logger->setProperty, format='%(message)s', $
                       level=log_level, $
                       filename=log_filename

  mg_log, name='kcor/reprocess', logger=logger
  log_filename = filepath(self.date + '.reprocess.log', root=log_dir)
  if (keyword_set(rotate_logs) && mode eq 'realtime' && reprocess) then begin
    mg_rotate_log, log_filename, max_version=max_log_version
  endif
  logger->setProperty, format=log_fmt, $
                       time_format=log_time_fmt, $
                       level=log_level, $
                       filename=log_filename
end


;= property access

;+
; Set properties.
;-
pro kcor_run::setProperty, time=time, mode=mode
  compile_opt strictarr

  if (n_elements(mode) gt 0L) then begin
    self.mode = mode
    self.log_name = self.mode eq 'realtime' ? 'kcor/rt' : 'kcor/eod'
  endif

  if (n_elements(time) gt 0L) then begin
    if (strlen(time) eq 6) then begin
      self.epochs->setProperty, datetime=self.date + '.' + kcor_ut2hst(time)
    endif else begin
      hour   = strmid(time, 11, 2)
      minute = strmid(time, 14, 2)
      second = strmid(time, 17, 2)
      hst_time  = kcor_ut2hst(hour + minute + second)
      self.epochs->setProperty, datetime=self.date + '.' + hst_time
    endelse
  endif
end


;+
; Get properties.
;-
pro kcor_run::getProperty, config_contents=config_contents, $
                           date=date, $
                           config_filename=config_filename, $
                           pipe_dir=pipe_dir, $
                           resources_dir=resources_dir, $
                           mode=mode, $

                           gzip=gzip, $
                           gunzip=gunzip, $
                           convert=convert, $
                           ffmpeg=ffmpeg, $
                           mencoder=mencoder, $
                           hsi=hsi, $
                           npick=npick, $
                           cal_basedir=cal_basedir, $
                           cal_out_dir=cal_out_dir, $
                           correct_camera=correct_camera, $
                           camera_correction_dir=camera_correction_dir, $
                           raw_basedir=raw_basedir, $
                           process_basedir=process_basedir, $
                           lock_raw=lock_raw, $
                           archive_basedir=archive_basedir, $
                           fullres_basedir=fullres_basedir, $
                           croppedgif_basedir=croppedgif_basedir, $
                           hv_basedir=hv_basedir, $
                           nrgf_basedir=nrgf_basedir, $
                           nrgf_remote_dir=nrgf_remote_dir, $
                           nrgf_remote_server=nrgf_remote_server, $
                           raw_remote_dir=raw_remote_dir, $
                           raw_remote_server=raw_remote_server, $
                           min_compression_ratio=min_compression_ratio, $
                           max_compression_ratio=max_compression_ratio, $
                           ssh_key=ssh_key, $
                           hpss_gateway=hpss_gateway, $
                           save_basedir=save_basedir, $
                           log_dir=log_dir, $
                           log_level=log_level, $
                           max_log_version=max_log_version, $
                           engineering_dir=engineering_dir, $
                           hpr_dir=hpr_dir, $
                           hpr_diff_dir=hpr_diff_dir, $
                           cme_movie_dir=cme_movie_dir, $
                           cme_stop_time=cme_stop_time, $
                           cme_wait_time=cme_wait_time, $
                           cme_email=cme_email, $
                           cme_from_email=cme_from_email, $
                           database_config_filename=database_config_filename, $
                           database_config_section=database_config_section, $
                           notification_email=notification_email, $
                           send_notifications=send_notifications, $
                           update_database=update_database, $
                           reprocess=reprocess, $
                           update_processing=update_processing, $
                           update_remote_server=update_remote_server, $
                           skypol_method=skypol_method, $
                           sine2theta_nparams=sine2theta_nparams, $
                           cameras=cameras, $
                           shift_center=shift_center, $
                           center_offset=center_offset, $
                           distribute=distribute, $
                           diagnostics=diagnostics, $
                           reduce_calibration=reduce_calibration, $
                           send_to_archive=send_to_archive, $
                           send_to_hpss=send_to_hpss, $
                           validate_t1=validate_t1, $
                           produce_plots=produce_plots, $
                           catalog_files=catalog_files, $
                           create_daily_movies=create_daily_movies, $
                           diff_average_interval=diff_average_interval, $
                           diff_cadence=diff_cadence, $
                           diff_interval=diff_interval, $
                           diff_good_max=diff_good_max, $
                           diff_pass_max=diff_pass_max, $
                           diff_threshold_intensity=diff_threshold_intensity, $
                           average_interval=average_interval, $
                           daily_average_interval=daily_average_interval
  compile_opt strictarr

  if (arg_present(config_contents)) then begin
    config_contents = reform(self.options->_toString(/substitute))
  endif

  if (arg_present(date)) then date = self.date
  if (arg_present(config_filename)) then config_filename = self.config_filename

  if (arg_present(pipe_dir)) then pipe_dir = self.pipe_dir
  if (arg_present(resources_dir)) then begin
    resources_dir = filepath('resources', root=self.pipe_dir)
  endif

  if (arg_present(mode)) then mode = self.mode

  ; externals
  if (arg_present(gzip)) then begin
    gzip = self.options->get('gzip', section='externals')
  endif
  if (arg_present(gunzip)) then begin
    gunzip = self.options->get('gunzip', section='externals')
  endif
  if (arg_present(convert)) then begin
    convert = self.options->get('convert', section='externals')
  endif
  if (arg_present(ffmpeg)) then begin
    ffmpeg = self.options->get('ffmpeg', section='externals')
  endif
  if (arg_present(mencoder)) then begin
    mencoder = self.options->get('mencoder', section='externals')
  endif
  if (arg_present(hsi)) then begin
    hsi = self.options->get('hsi', section='externals')
  endif

  ; calibration
  if (arg_present(npick)) then begin
    npick = self.options->get('npick', section='calibration', $
                              type=3, default=50000L)
  endif
  if (arg_present(cal_basedir)) then begin
    cal_basedir = self.options->get('basedir', section='calibration')
  endif
  if (arg_present(cal_out_dir)) then begin
    cal_out_dir = self.options->get('out_dir', section='calibration')
  endif
  if (arg_present(camera_correction_dir)) then begin
    camera_correction_dir = self.options->get('camera_correction_dir', $
                                              section='calibration')
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
  if (arg_present(fullres_basedir)) then begin
    fullres_basedir = self.options->get('fullres_basedir', section='results')
  endif
  if (arg_present(croppedgif_basedir)) then begin
    croppedgif_basedir = self.options->get('croppedgif_basedir', section='results')
  endif
  if (arg_present(hv_basedir)) then begin
    hv_basedir = self.options->get('hv_basedir', section='results', default='')
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
  if (arg_present(ssh_key)) then begin
    ssh_key = self.options->get('ssh_key', section='results', default='')
  endif
  if (arg_present(hpss_gateway)) then begin
    hpss_gateway = self.options->get('hpss_gateway', section='results', default='')
  endif
  if (arg_present(save_basedir)) then begin
    save_basedir = self.options->get('save_basedir', section='results', default='')
  endif

  ; logging
  if (arg_present(log_dir)) then begin
    log_dir = self.options->get('log_dir', section='logging')
  endif
  if (arg_present(log_level)) then begin
    log_level = self.options->get('level', section='logging', $
                                  type=3, default=4L)
  endif
  if (arg_present(max_log_version)) then begin
    max_log_version = self.options->get('max_log_version', section='logging', $
                                        type=3, default=10L)
  endif

  ; engineering
  if (arg_present(engineering_dir)) then begin
    engineering_dir = self.options->get('engineering_dir', section='engineering')
  endif

  ; cme
  if (arg_present(hpr_dir)) then begin
    hpr_dir = self.options->get('hpr_dir', section='cme')
  endif
  if (arg_present(hpr_diff_dir)) then begin
    hpr_diff_dir = self.options->get('hpr_diff_dir', section='cme')
  endif
  if (arg_present(cme_movie_dir)) then begin
    cme_movie_dir = self.options->get('movie_dir', section='cme')
  endif
  if (arg_present(cme_stop_time)) then begin
    cme_stop_time = self.options->get('stop_time', section='cme', default='180000')
  endif
  if (arg_present(cme_wait_time)) then begin
    cme_wait_time = self.options->get('wait_time', section='cme', default=15.0, type=4)
  endif
  if (arg_present(cme_email)) then begin
    cme_email = self.options->get('email', section='cme')
  endif
  if (arg_present(cme_from_email)) then begin
    cme_from_email = self.options->get('from_email', section='cme', default='')
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
  if (arg_present(reprocess)) then begin
    reprocess = self.options->get('reprocess', section='realtime', $
                                  /boolean, default=0B)
  endif
  if (arg_present(update_processing)) then begin
    update_processing = self.options->get('update_processing', section='realtime', $
                                          /boolean, default=0B)
  endif
  if (arg_present(update_remote_server)) then begin
    update_remote_server = self.options->get('update_remote_server', section='realtime', $
                                             /boolean, default=1B)
  endif
  if (arg_present(skypol_method)) then begin
    skypol_method = self.options->get('skypol_method', section='realtime', $
                                      default='subtraction')
  endif
  if (arg_present(sine2theta_nparams)) then begin
    sine2theta_nparams = self.options->get('sine2theta_nparams', section='realtime', $
                                           type=3, default=2)
  endif
  if (arg_present(cameras)) then begin
    cameras = self.options->get('cameras', section='realtime', $
                                type=7, default='both')
  endif
  if (arg_present(shift_center)) then begin
    shift_center = self.options->get('shift_center', section='realtime', $
                                     /boolean, default=1B)
  endif
  if (arg_present(center_offset)) then begin
    center_offset = self.options->get('center_offset', section='realtime', $
                                      type=4, /extract, default=fltarr(2))
  endif
  if (arg_present(distribute)) then begin
    distribute = self.options->get('distribute', section='realtime', $
                                   /boolean, default=1B)
  endif
  if (arg_present(diagnostics)) then begin
    diagnostics = self.options->get('diagnostics', section='realtime', $
                                    /boolean, default=0B)
  endif

  ; end-of-day
  if (arg_present(reduce_calibration)) then begin
    reduce_calibration = self.options->get('reduce_calibration', section='eod', $
                                           /boolean, default=1B)
  endif
  if (arg_present(send_to_archive)) then begin
    send_to_archive = self.options->get('send_to_archive', section='eod', $
                                        /boolean, default=1B)
  endif
  if (arg_present(send_to_hpss)) then begin
    send_to_hpss = self.options->get('send_to_hpss', section='eod', $
                                     /boolean, default=1B)
  endif
  if (arg_present(validate_t1)) then begin
    validate_t1 = self.options->get('validate_t1', section='eod', $
                                     /boolean, default=1B)
  endif
  if (arg_present(produce_plots)) then begin
    produce_plots = self.options->get('produce_plots', section='eod', $
                                      /boolean, default=1B)
  endif
  if (arg_present(catalog_files)) then begin
    catalog_files = self.options->get('catalog_files', section='eod', $
                                      /boolean, default=1B)
  endif
  if (arg_present(create_daily_movies)) then begin
    create_daily_movies = self.options->get('create_daily_movies', section='eod', $
                                            /boolean, default=1B)
  endif

  ; difference movies
  if (arg_present(diff_average_interval)) then begin
    diff_average_interval = self.options->get('average_interval', $
                                              section='differences', $
                                              type=4, default=120.0)
  endif
  if (arg_present(diff_cadence)) then begin
    diff_cadence = self.options->get('cadence', $
                                     section='differences', $
                                     type=4, default=300.0)
  endif
  if (arg_present(diff_interval)) then begin
    diff_interval = self.options->get('interval', $
                                      section='differences', $
                                      type=4, default=600.0)
  endif
  if (arg_present(diff_good_max)) then begin
    diff_good_max = self.options->get('good_max', $
                                      section='differences', $
                                      type=3, default=100L)
  endif
  if (arg_present(diff_pass_max)) then begin
    diff_pass_max = self.options->get('pass_max', $
                                      section='differences', $
                                      type=3, default=250L)
  endif
  if (arg_present(diff_threshold_intensity)) then begin
    diff_threshold_intensity = self.options->get('threshold_intensity', $
                                                 section='differences', $
                                                 type=4, default=1.0e-8)
  endif

  ; averages
  if (arg_present(average_interval)) then begin
    average_interval = self.options->get('interval', $
                                         section='averaging', $
                                         type=4, default=180.0)
  endif
  if (arg_present(daily_average_interval)) then begin
    daily_average_interval = self.options->get('daily_interval', $
                                               section='averaging', $
                                               type=4, default=900.0)
  endif

  ; verification
  if (arg_present(raw_remote_dir)) then begin
    raw_remote_dir = self.options->get('raw_remote_dir', section='verification')
  endif
  if (arg_present(raw_remote_server)) then begin
    raw_remote_server = self.options->get('raw_remote_server', section='verification')
  endif
  if (arg_present(min_compression_ratio)) then begin
    min_compression_ratio = self.options->get('min_compression_ratio', $
                                              section='verification', $
                                              type=4, default=0.99)
  endif
  if (arg_present(max_compression_ratio)) then begin
    max_compression_ratio = self.options->get('max_compression_ratio', $
                                              section='verification', $
                                              type=4, default=1.01)
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
function kcor_run::init, date, $
                         config_filename=config_filename, $
                         mode=mode
  compile_opt strictarr
  on_error, 2

  self.date = date
  self.pipe_dir = file_expand_path(filepath('..', root=mg_src_root()))

  if (~file_test(config_filename)) then message, config_filename + ' not found'
  self.config_filename = config_filename

  self.options = mg_read_config(config_filename, error=error, errmsg=errmsg)
  if (error ne 0) then message, errmsg

  ; setup config options
  ;config_spec_filename = filepath('ucomp.spec.cfg', $
  ;                                subdir=['..', 'config'], $
  ;                                root=mg_src_root())

  ;self.options = mg_read_config(config_filename, spec=config_spec_filename, $
  ;                              error=error, errmsg=errmsg)
  ;if (error ne 0) then message, errmsg
  ;config_valid = self.options->is_valid(error_msg=error_msg)
  ;if (~config_valid) then begin
  ;  mg_log, 'invalid configuration file', name=logger_name, /critical
  ;  mg_log, '%s', error_msg, name=logger_name, /critical
  ;  return, 0
  ;endif

  ; setup epoch reading
  epochs_filename = filepath('epochs.cfg', root=mg_src_root())
  epochs_spec_filename = filepath('epochs.spec.cfg', root=mg_src_root())

  self.epochs = mgffepochparser(epochs_filename, epochs_spec_filename)
  epochs_valid = self.epochs->is_valid(error_msg=error_msg)
  if (~epochs_valid) then begin
    mg_log, 'invalid epochs file', name=logger_name, /critical
    mg_log, '%s', error_msg, name=logger_name, /critical
    return, 0
  endif
  self.epochs->setProperty, datetime=date + '.000000'

  ; rotate the logs if this is a reprocessing
  self->setProperty, mode=mode
  self->getProperty, reprocess=reprocess
  self->setup_loggers, rotate_logs=reprocess

  return, 1
end


;+
; Define instance variables.
;-
pro kcor_run__define
  compile_opt strictarr

  !null = {kcor_run, inherits IDL_Object, $
           date:            '', $
           config_filename: '', $
           mode:            '', $   ; realtime or eod
           log_name:        '', $
           pipe_dir:        '', $
           options:         obj_new(), $
           epochs:          obj_new()}
end


; main-level example program

; example of creating a run object

date = '20180212'
config_filename = filepath('kcor.mgalloy.mahi.latest.cfg', $
                           subdir=['..', 'config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)

help, run.min_compression_ratio
help, run.max_compression_ratio

obj_destroy, run

end
