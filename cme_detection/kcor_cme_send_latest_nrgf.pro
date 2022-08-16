; docformat = 'rst'

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

  ; find latest NRGF image
  glob = filepath('*_kcor_l2_nrgf.gif', $
                  subdir=kcor_decompose_date(simple_date), $
                  root=run->config('results/nrgf_basedir'))
  nrgf_filenames = file_search(glob, count=n_nrgf_files)
  if (n_nrgf_files eq 0L) then goto, done
  latest_nrgf_filename = nrgf_filenames[-1]

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

  done:
end
