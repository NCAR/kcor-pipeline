; docformat = 'rst'

;+
; Send the heartbeat alert.
;-
pro kcor_cme_send_heartbeat
  compile_opt strictarr
  @kcor_cme_det_common

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
      last_heartbeat_jd = julday()
      issue_time = string(last_heartbeat_jd + 10.0D / 24.0D, format=iso8601_fmt)

      mg_log, 'creating heartbeat...', name='kcor/cme', /info
      last_data_time = tai2utc(utc2tai(date_diff[-1].date_obs), /truncate, /ccsds) + 'Z'
      mode = run->config('cme/mode')
      heartbeat_json = kcor_cme_alert_heartbeat(issue_time, $
                                                last_data_time, $
                                                ~cme_occurring, $
                                                mode)

      json_filename = kcor_cme_alert_filename(last_data_time, issue_time)
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

      if (n_elements(alerts_dir)) then file_copy, json_filename, alerts_dir

      file_delete, json_filename, /allow_nonexistent
    endif
  endif
end
