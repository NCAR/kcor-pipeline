; docformat = 'rst'

;+
; Send alerts for human observer initiated CME.
;
; :Params:
;   observing_date : in, required, type=string
;     HST date in the form "YYYYMMDD"
;   issue_time : in, required, string
;     UT date/time of CME
;   position_angle : in, required, type=float
;     position angle measured CCW from N
;   list_dir : in, required, type=string
;     directory to write/update list file
;
; :Keywords:
;   comment : in, optional, type=string
;     free form comment from observer
;-
pro kcor_cme_human, observing_date, start_time, position_angle, width, list_dir, $
                    comment=comment, line=line
  compile_opt strictarr
  @kcor_cme_det_common

  ; add to list of human alerts already sent
  human_sent_basename = string(observing_date, format='(%"%s.kcor.cme.human-sent.txt")')
  human_sent_filename = filepath(human_sent_basename, root=list_dir)

  openu, lun, human_sent_filename, /get_lun, /append
  printf, lun, line
  free_lun, lun

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
    mode = run->config('cme/mode')
    alert_ut_date = kcor_cme_ut_date(start_time, simple_date)
    alert_ut_datetime = string(alert_ut_date, start_time, $
                               format='(%"%sT%sZ")')
    alert_json = kcor_cme_alert_human(issue_time, $
                                      alert_ut_datetime, $
                                      position_angle, $
                                      ~cme_occurring, $
                                      mode, $
                                      comment=comment)

    json_filename = kcor_cme_alert_filename(alert_ut_datetime, issue_time)
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
