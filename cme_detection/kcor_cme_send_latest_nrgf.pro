; docformat = 'rst'

;+
; Send latest NRGF file.
;-
pro kcor_cme_send_latest_nrgf
  compile_opt strictarr
  @kcor_cme_det_common

  ftp_url = run->config('cme/ftp_images_url')
  if (n_elements(ftp_url) eq 0L) then begin
    mg_log, 'no FTP images URL, skipping', name='kcor/cme', /debug
    goto, done
  endif

  ftp_from_email = run->config('cme/from_email')
  if (n_elements(ftp_from_email) eq 0L) then ftp_from_email = ''

  nrgf_age_threshold = 10.0   ; minutes
  current_time = kcor_cme_current_time(run=run)
  latest_nrgf_filename = kcor_cme_find_latest_nrgf(current_time, age=age)
  found_nrgf = n_elements(latest_nrgf_filename) gt 0L
  if (found_nrgf && (age lt nrgf_age_threshold * 60.0)) then begin
    ; send latest NRGF to FTP site
    kcor_cme_ftp_transfer, ftp_url, latest_nrgf_filename, ftp_from_email, $
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

  done:
end
