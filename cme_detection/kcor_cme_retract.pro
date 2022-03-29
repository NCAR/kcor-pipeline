; docformat = 'rst'

;+
; Retract a CME, i.e., add a CME to the retracted list and other associated
; actions.

; :Params:
;   observing_date : in, required, type=string
;     HST date in the form "YYYYMMDD"
;   retract_time : in, required, string
;     UT date/time of CME
;   retract_position_angle : in, required, type=float
;     position angle measured CCW from N
;   list_dir : in, required, type=string
;     directory to write/update list file
;-
pro kcor_cme_retract, observing_date, retract_time, retract_position_angle, list_dir
  compile_opt strictarr
  @kcor_cme_common

  ; add to retracted CME list file
  kcor_cme_update_list, observing_date, $
                        retract_time, $
                        retract_position_angle, $
                        'retracted', $
                        list_dir

  ; send email retracting CME
  kcor_cme_retract_email, retract_time, retract_position_angle

  ; send JSON alert to alerts dir and alerts FTP URL
  alerts_basedir = run->config('cme/alerts_basedir')
  if (n_elements(alerts_basedir) gt 0L) then begin
    alerts_dir = filepath('', $
                          subdir=kcor_decompose_date(simple_date), $
                          root=alerts_basedir)
    if (~file_test(alerts_dir, /directory)) then file_mkdir, alerts_dir
  endif

  ftp_url = run->config('cme/ftp_alerts_url')
  if (n_elements(alerts_dir) gt 0L || n_elements(ftp_url) gt 0L) then begin
    issue_time = kcor_cme_current_time(run=run)
    last_data_time = tai2utc(utc2tai(date_diff[-1].date_obs), /truncate, /ccsds) + 'Z'
    mode = run->config('cme/mode')
    alert_json = kcor_cme_alert_retract(issue_time, last_data_time, ~cme_occurring, mode, $
                                        retract_time=retract_time, $
                                        retract_position_angle=retract_position_angle)

    json_filename = kcor_cme_alert_filename(retract_time, issue_time)
    kcor_cme_alert_text2file, alert_json, json_filename

    if (n_elements(ftp_url) gt 0L) then begin
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
end

