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
function kcor_run::epoch, name, time=time, error=error
  compile_opt strictarr
  on_error, 2

  error = 0L

  if (n_elements(time) gt 0L) then begin
    hst_time = kcor_ut2hst(time)
    datetime = self.date + '.' + hst_time
  endif

  ; handle 'cal_file' when using pipeline cal files
  if (strlowcase(name) eq 'cal_file') then begin
    if (n_elements(time) eq 0L) then begin
      dt = self.epochs.datetime
      hst_time = dt->strftime('%H%M%S')
    endif else hst_time = kcor_ut2hst(time)

    calfile = self->_find_calfile(self.date, hst_time)
    if (calfile eq '') then error = 1L
    return, calfile
  endif

  value = self.epochs->get(name, datetime=datetime)

  ; handle 'cal_file' when using hard-coded cal files
  if (strlowcase(name) eq 'cal_file') then begin
    cal_file_glob_pattern = value
    cal_out_dir = self->config('calibration/out_dir')
    cal_search_spec = filepath(cal_file_glob_pattern, root=cal_out_dir)

    calfiles = file_search(cal_search_spec, count=n_calfiles)
    if (n_calfiles eq 0L) then message, 'unable to find cal file'
    return, file_basename(calfiles[-1])
  endif

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
  if (self->config('logging/report_pid')) then begin
    log_fmt = '[%(pid)s] %(time)s %(levelshortname)s: %(routine)s: %(message)s'
  endif else begin
    log_fmt = '%(time)s %(levelshortname)s: %(routine)s: %(message)s'
  endelse

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

  ; can setup other loggers just by changing MODE property
  if (self.mode ne 'eod' && self.mode ne 'realtime') then begin
    mg_log, name='kcor/' + self.mode, logger=logger
    log_filename = filepath(string(self.date, self.mode, format='(%"%s.%s.log")'), $
                            root=log_dir)
    if (keyword_set(rotate_logs)) then begin
      mg_rotate_log, log_filename, max_version=max_log_version
    endif
    logger->setProperty, format=log_fmt, $
                         time_format=log_time_fmt, $
                         level=log_level, $
                         filename=log_filename
  endif
end


;= variables for template of report

function kcor_run::getVariable, name, found=found
  compile_opt strictarr

  found = 1B

  raw_basedir = self->config('processing/raw_basedir')
  case strlowcase(name) of
    'date': return, self.date
    'css_location': return, filepath('main.css', $
                                     subdir=['resources', 'html'], $
                                     root=self.pipe_dir)
    'raw_times': begin
        raw_glob = filepath('*.fts*', $
                            subdir=[self.date, 'level0'], $
                            root=raw_basedir)
        raw_files = file_search(raw_glob, count=n_raw_files)
        if (n_raw_files eq 0L) then return, ''

        raw_times = strmid(file_basename(raw_files), 0, 15)

        raw_time_objects = objarr(n_raw_files)
        for f = 0L, n_raw_files - 1L do begin
          raw_time_objects[f] = kcor_time(raw_times[f], run=self)
        endfor
        return, raw_time_objects
      end

    'n_raw_files': begin
        raw_glob = filepath('*.fts*', $
                            subdir=[self.date, 'level0'], $
                            root=raw_basedir)
        raw_files = file_search(raw_glob, count=n_raw_files)
        return, n_raw_files
      end
    'n_l2_files': begin
        l2_glob = filepath('*_kcor_l2.fts*', $
                            subdir=[self.date, 'level2'], $
                            root=raw_basedir)
        l2_files = file_search(l2_glob, count=n_l2_files)
        return, n_l2_files
      end
    'n_nrgf_files': begin
        nrgf_glob = filepath('*_kcor_l2_nrgf.fts*', $
                             subdir=[self.date, 'level2'], $
                             root=raw_basedir)
        nrgf_files = file_search(nrgf_glob, count=n_nrgf_files)
        return, n_nrgf_files
      end

    'observer_log_href': begin
        olog_basedir = self->config('logging/observer_log_basedir')
        date_parts = long(kcor_decompose_date(self.date))
        doy = mg_ymd2doy(date_parts[0], date_parts[1], date_parts[2])
        href = filepath(string(date_parts[0], doy, format='(%"mlso.%04dd%03d.olog")'), $
                        subdir=strtrim(date_parts[0], 2), $
                        root=olog_basedir)
        return, href
      end

    'reprocess_log_href': begin
        basename = string(self.date, format='(%"%s.reprocess.olog")')
        log_filename = filepath(basename, $
                                subdir=self.date, $
                                root=self->config('processing/raw_basedir'))
        return, file_test(log_filename) ? log_filename : ''
      end
    'rt_log_href': begin
        basename = string(self.date, format='(%"%s.realtime.olog")')
        log_filename = filepath(basename, $
                                subdir=self.date, $
                                root=self->config('processing/raw_basedir'))
        return, file_test(log_filename) ? ('./' + basename) : ''
      end
    'eod_log_href': begin
        basename = string(self.date, format='(%"%s.eod.olog")')
        log_filename = filepath(basename, $
                                subdir=self.date, $
                                root=self->config('processing/raw_basedir'))
        return, file_test(log_filename) ? log_filename : ''
      end

    'l0_median_rows_cam0_image_href': begin
        return, string(self.date, format='(%"./p/%d.kcor.l0.medrows.cam0.gif")')
      end
    'l0_median_cols_cam0_image_href': begin
        return, string(self.date, format='(%"./p/%d.kcor.l0.medcols.cam0.gif")')
      end

    'l0_median_rows_cam1_image_href': begin
        return, string(self.date, format='(%"./p/%d.kcor.l0.medrows.cam1.gif")')
      end
    'l0_median_cols_cam1_image_href': begin
        return, string(self.date, format='(%"./p/%d.kcor.l0.medcols.cam1.gif")')
      end

    'l2_median_rows_image_href': begin
        return, string(self.date, format='(%"./p/%d.kcor.l2.medrows.gif")')
      end
    'l2_median_cols_image_href': begin
        return, string(self.date, format='(%"./p/%d.kcor.l2.medcols.gif")')
      end

    'extavg_href': begin
        extavg_glob = filepath('*_kcor_l2_extavg.gif', $
                               subdir=[self.date, 'level2'], $
                               root=raw_basedir)
        extavg_files = file_search(extavg_glob, count=n_extavg_files)
        href = './level2/' + file_basename(extavg_files[0])
        return, href
      end
    'extavg_cropped_href': begin
        extavg_glob = filepath('*_kcor_l2_extavg_cropped.gif', $
                               subdir=[self.date, 'level2'], $
                               root=raw_basedir)
        extavg_files = file_search(extavg_glob, count=n_extavg_files)
        href = './level2/' + file_basename(extavg_files[0])
        return, href
      end

    'nrgf_extavg_href': begin
        extavg_glob = filepath('*_kcor_l2_nrgf_extavg.gif', $
                               subdir=[self.date, 'level2'], $
                               root=raw_basedir)
        extavg_files = file_search(extavg_glob, count=n_extavg_files)
        href = './level2/' + file_basename(extavg_files[0])
        return, href
      end
    'nrgf_extavg_cropped_href': begin
        extavg_glob = filepath('*_kcor_l2_nrgf_extavg_cropped.gif', $
                               subdir=[self.date, 'level2'], $
                               root=raw_basedir)
        extavg_files = file_search(extavg_glob, count=n_extavg_files)
        href = './level2/' + file_basename(extavg_files[0])
        return, href
      end

    'daily_mp4_href': begin
        glob = filepath('*_kcor_l2.mp4', $
                        subdir=[self.date, 'level2'], $
                        root=raw_basedir)
        files = file_search(glob, count=n_files)
        href = n_files eq 0L ? '' : './level2/' + file_basename(files[0])
        return, href
      end
    'daily_croppped_mp4_href': begin
        glob = filepath('*_kcor_l2_cropped.mp4', $
                        subdir=[self.date, 'level2'], $
                        root=raw_basedir)
        files = file_search(glob, count=n_files)
        href = n_files eq 0L ? '' : './level2/' + file_basename(files[0])
        return, href
      end

    'daily_nrgf_mp4_href': begin
        glob = filepath('*_kcor_l2_nrgf.mp4', $
                        subdir=[self.date, 'level2'], $
                        root=raw_basedir)
        files = file_search(glob, count=n_files)
        href = n_files eq 0L ? '' : './level2/' + file_basename(files[0])
        return, href
      end
    'daily_nrgf_croppped_mp4_href': begin
        glob = filepath('*_kcor_l2_nrgf_cropped.mp4', $
                        subdir=[self.date, 'level2'], $
                        root=raw_basedir)
        files = file_search(glob, count=n_files)
        href = n_files eq 0L ? '' : './level2/' + file_basename(files[0])
        return, href
      end
  endcase

  found = 0B
  return, ''
end


;= property access

;+
; Set properties.
;-
pro kcor_run::setProperty, time=time, mode=mode
  compile_opt strictarr

  if (n_elements(mode) gt 0L) then begin
    self.mode = mode
    if (self.mode eq 'realtime') then begin
      self.logger_name = 'kcor/rt'
    endif else self.logger_name = 'kcor/' + mode
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
                           logger_name=logger_name, $
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

  if (arg_present(logger_name)) then logger_name = self.logger_name
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
           logger_name:     '', $
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
