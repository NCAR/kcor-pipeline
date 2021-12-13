; docformat = 'rst'

;+
; Command to push a file to the FTP server::
;
;   curl --ssl -k --user anonymous:<your email> <FTP URL> -T <filename>
;
; :Params:
;   ftp_url : in, required, type=string
;     FTP address
;   filename : in, required, type=string
;     filename of file to transfer
;   email : in, required, type=string
;     email address of sender
;
; :Keywords:
;   status : out, optional, type=integer
;     set to a named variable to retrieve the status of the transfer, 0 for
;     success, other codes for errors
;   error_msg : out, optional, type=string
;     set to a named variable to retrieve the error message if `STATUS` was not
;     0
pro kcor_cme_ftp_transfer, ftp_url, filename, email, $
                           status=status, error_msg=error_msg
  compile_opt strictarr

  ; TODO: need a silent option to not show progress
  cmd = string(email, ftp_url, filename, $
               format='(%"curl --ssl -k --user anonymous:%s %s -T %s")')
  spawn, cmd, stdout, error_msg, exit_status=status
end

; main-level example program
date = '20210628'
config_basename = 'kcor.cme.cfg'
config_filename = filepath(config_basename, subdir=['..', 'config'], root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)

event_time     = '2021-06-28T13:45:00Z'
issue_time     = '2021-06-28T13:47:00Z'
last_data_time = '2021-06-28T13:46:15Z'

heartbeat_string = kcor_cme_alert_heartbeat(issue_time, last_data_time, !true)
alert_filename = kcor_cme_alert_filename(event_time, issue_time)

kcor_cme_alert_text2file, heartbeat_string, alert_filename
print, alert_filename, format='(%"Alert filename: %s")'

ftp_url = run->config('cme/ftp_alerts_url')
ftp_from_email = run->config('cme/from_email')
print, ftp_url, format='(%"FTP URL: %s")'
print, ftp_from_email, format='(%"FTP from email: %s")'

;kcor_cme_ftp_transfer, ftp_url, alert_filename, ftp_from_email, $
;                       status=status, error_msg=error_msg

;print, status, format='(%"FTP status: %d")'
;if (status ne 0L) then print, error_msg

;file_delete, alert_filename
; $ cat /usr/tmp/mlso_kcor.2021-06-28T134500Z.2021-06-28T134700Z.json
; {"sep_forecast_submission":{"model":{"short_name":"MLSO K-Cor","spase_id":"spase://CCMC/SimulationModel/MLSO/K-Cor/AutomatedCMEDetection"},"issue_time":"2021-06-28T13:47:00Z","mode":"nowcast","inputs":{"coronagraph":{"observatory":"MLSO","instrument":"K-Cor"},"products":{"product":"White Light","last_data_time":"2021-06-28T13:46:15Z"}},"observations":{"all_clear":{"all_clear_boolean":true,"all_clear_type":"cme"}}}}

obj_destroy, run

end
