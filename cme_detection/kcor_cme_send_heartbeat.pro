; docformat = 'rst'

;+
; Send the heartbeat alert.
;-
pro kcor_cme_send_heartbeat
  compile_opt strictarr
  @kcor_cme_det_common

  kcor_cme_send_latest_nrgf

  iso8601_fmt = '(C(CYI4.4, "-", CMOI2.2, "-", CDI2.2, "T", CHI2.2, ":", CMI2.2, ":", CSI2.2, "Z"))'
  wait_time = run->config('cme/wait_time')
  heartbeat_interval = run->config('cme/heartbeat_interval')

  alerts_basedir = run->config('cme/alerts_basedir')
  if (n_elements(alerts_basedir) gt 0L) then begin
    alerts_dir = filepath('', $
                          subdir=kcor_decompose_date(simple_date), $
                          root=alerts_basedir)
    if (~file_test(alerts_dir, /directory)) then file_mkdir, alerts_dir
  endif

  ftp_url = run->config('cme/ftp_alerts_url')

  seconds_since_last_heartbeat = (julday() - last_heartbeat_jd) * 24.0 * 60.0 * 60.0
  mg_log, 'last heartbeat %0.1f secs ago', seconds_since_last_heartbeat, $
          name='kcor/cme', /debug

  if (n_elements(alerts_dir) gt 0L || n_elements(ftp_url)) then begin
    if ((seconds_since_last_heartbeat gt heartbeat_interval) $
          && (n_elements(date_diff) gt 0L)) then begin
      issue_time = kcor_cme_current_time(run=run)
      json_filename = kcor_cme_alert_filename(last_data_time, issue_time)
      json_basename = file_basename(json_filename)

      if (n_elements(alerts_dir) gt 0L $
            && file_test(filepath(json_basename, root=alerts_dir), /regular)) then begin
        mg_log, 'already sent heartbeat at this time, skipping...', name='kcor/cme', /warn
        mg_log, 'last data time: %s', last_data_time, name='kcor/cme', /debug
        mg_log, 'issue time: %s', issue_time, name='kcor/cme', /debug
        return
      endif

      if (n_elements(last_heartbeat_last_data_time) gt 0L $
            && (last_data_time eq last_heartbeat_last_data_time)) then begin
        mg_log, 'no new data since last heartbeat, skipping', name='kcor/cme', /debug
        mg_log, 'last data time: %s', last_data_time, name='kcor/cme', /debug
        mg_log, 'issue time: %s', issue_time, name='kcor/cme', /debug
        return
      endif else last_heartbeat_last_data_time = last_data_time

      last_heartbeat_jd = julday()

      mg_log, 'creating heartbeat...', name='kcor/cme', /info

      mode = run->config('cme/mode')
      heartbeat_json = kcor_cme_alert_heartbeat(issue_time, $
                                                last_sci_data_time, $
                                                ~cme_occurring, $
                                                mode)

      kcor_cme_alert_text2file, heartbeat_json, json_filename

      if (n_elements(ftp_url)) then begin
        ftp_from_email = run->config('cme/from_email')
        if (n_elements(ftp_from_email) eq 0L) then ftp_from_email = ''
        kcor_cme_ftp_transfer, ftp_url, json_filename, ftp_from_email, $
                               status=ftp_status, $
                               error_msg=ftp_error_msg, $
                               cmd=ftp_cmd
        if (ftp_status ne 0L) then begin
          mg_log, 'FTP transferred with error %d', ftp_status, name='kcor/cme', /error
          mg_log, 'FTP command: %s', ftp_cmd, name='kcor/cme', /error
          for e = 0L, n_elements(ftp_error_msg) - 1L do begin
            mg_log, ftp_error_msg[e], name='kcor/cme', /error
          endfor
        endif
      endif

      if (n_elements(alerts_dir) gt 0L) then file_copy, json_filename, alerts_dir

      file_delete, json_filename, /allow_nonexistent
    endif
  endif
end
