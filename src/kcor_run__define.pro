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
  cal_out_dir = self->config('calibration/out_dir')
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

  if (strlowcase(name) eq 'cal_file') then begin
    if (self.epochs->get('use_pipeline_calfiles', datetime=datetime)) then begin
      if (n_elements(time) eq 0L) then begin
        dt = self.epochs.datetime
        hst_time = dt->strftime('%H%M%S')
      endif else hst_time = kcor_ut2hst(time)

      return, self->_find_calfile(self.date, hst_time)
    endif
  endif

  if (n_elements(time) gt 0L) then begin
    hst_time = kcor_ut2hst(time)
    datetime = self.date + '.' + hst_time
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

  if (name eq 'processing/raw_basedir' && n_elements(value) eq 0L) then begin
    routing_file = self.options->get('routing_file', section='processing')
    if (n_elements(routing_file) eq 0L) then message, 'processing/raw_basedir not set'
    value = kcor_get_route(routing_file, self.date)
    if (n_elements(value) eq 0L) then begin
      message, string(self.date, format='(%"%s not found in routing file")')
    endif
  endif

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

  log_level = self->config('logging/level')
  log_dir   = self->config('logging/dir')
  if (~file_test(log_dir, /directory)) then file_mkdir, log_dir

  max_log_version = self->config('logging/max_version')
  mode            = self.mode
  reprocess       = self->config('realtime/reprocess')

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
                           mode=mode
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

  ; setup config options
  config_spec_filename = filepath('kcor.spec.cfg', $
                                  subdir=['..', 'config'], $
                                  root=mg_src_root())

  self.options = mg_read_config(config_filename, spec=config_spec_filename, $
                                error=error, errmsg=errmsg)
  if (error ne 0) then message, errmsg
  config_valid = self.options->is_valid(error_msg=error_msg)
  if (~config_valid) then begin
    mg_log, 'invalid configuration file', name=logger_name, /critical
    mg_log, '%s', error_msg, name=logger_name, /critical
    return, 0
  endif

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
  reprocess = self->config('realtime/reprocess')
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

help, run->config('verification/min_compression_ratio')
help, run->config('verification/max_compression_ratio')

obj_destroy, run

end
