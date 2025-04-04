; docformat = 'rst'

;+
; Archive KCor L2 products to Campaign Storage.
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;-
pro kcor_archive_l2, run=run
  compile_opt strictarr

  date = run.date

  if (run->config('eod/send_to_campaign')) then begin
    mg_log, 'sending L2 data to Campaign Storage...', name='kcor/eod', /info
  endif else begin
    mg_log, 'not sending L2 data to Campaign Storage', name='kcor/eod', /info
  endelse

  cd, current=cwd

  date_dir = filepath(date, root=run->config('processing/raw_basedir'))
  l2_dir   = filepath('level2', root=date_dir)

  if (~file_test(l2_dir, /directory)) then begin
    file_mkdir, l2_dir
    file_chmod, l2_dir, /a_read, /a_execute, /u_write
  endif

  cd, l2_dir

  tarfile  = string(date, format='(%"%s_kcor_l2.tgz")')
  tarlist  = string(date, format='(%"%s_kcor_l2.tarlist")')

  ; delete old tarball, tarlist
  if (~file_test(tarfile, /regular)) then file_delete, tarfile, /quiet
  if (~file_test(tarlist, /regular)) then file_delete, tarlist, /quiet

  ; create tarball
  file_types = ['*_kcor_l2*.fts*', $
                '*_kcor_minus_*_good.{gif,fts.gz}', $
                '*_kcor_minus_*_pass.{gif,fts.gz}', $
                '*_kcor_minus_*_bad.{gif,fts.gz}', $
                '*_kcor_l2_{pb,nrgf}*.gif', $
                '*.mp4']
  n_file_types = n_elements(file_types)
  file_type_mask = bytarr(n_file_types)
  for f = 0L, n_file_types - 1L do begin
    files = file_search(file_types[f], count=n_files)
    file_type_mask[f] = n_files gt 0L
  endfor

  if (total(file_type_mask, /integer) gt 0L) then begin
    glob = strjoin(file_types[where(file_type_mask)], ' ')
  endif else begin
    glob = ''
  endelse

  if (glob ne '') then begin
    tar_cmd = string(tarfile, glob, format='(%"tar cf %s %s")')
    mg_log, 'creating tarfile %s...', tarfile, name='kcor/eod', /info
    spawn, tar_cmd, result, error_result, exit_status=status
    if (status ne 0L) then begin
      mg_log, 'problem tarring files with command: %s', tar_cmd, $
              name='kcor/eod', /error
      mg_log, '%s', strjoin(error_result, ' '), name='kcor/eod', /error
      goto, done
    endif

    ; fix permissions on tarfile
    if (file_test(tarfile, /user)) then begin
      file_chmod, tarfile, /a_read, /g_write
    endif else begin
      !null = file_test(tarfile, get_mode=mode)
      if (mode and '664' ne '664') then begin
        mg_log, 'bad permissions on %s', tarfile, name='kcor/eod', /warn
      endif
    endelse

    ; create tarlist
    tarlist_cmd = string(tarfile, tarlist, $
                         format='(%"tar tfv %s > %s")')
    mg_log, 'creating tarlist %s...', tarlist, name='kcor/eod', /info
    spawn, tarlist_cmd, result, error_result, exit_status=status
    if (status ne 0L) then begin
      mg_log, 'problem create tarlist file with command: %s', tarlist_cmd, $
              name='kcor/eod', /error
      mg_log, '%s', strjoin(error_result, ' '), name='kcor/eod', /error
      goto, done
    endif

    ; fix permissions on tarlist
    !null = file_test(tarlist, get_mode=mode)
    if (mode and '664'o ne '664'o) then begin
      if (file_test(tarlist, /user)) then begin
        file_chmod, tarlist, /a_read, /g_write
      endif else begin
        mg_log, 'bad permissions %o on %s', mode, tarlist, $
                name='kcor/eod', /warn
      endelse
    endif

    cs_gateway = run->config('results/cs_gateway')
    send_to_campaign = run->config('eod/send_to_campaign') $
      && (strlen(cs_gateway) gt 0L)

    if (send_to_campaign) then begin
      ; create Campaign Storage gateway directory if needed
      if (~file_test(cs_gateway, /directory)) then begin
        file_mkdir, cs_gateway
        file_chmod, cs_gateway, /a_read, /a_execute, /u_write, /g_write
      endif

      ; remove old links to tarballs
      dst_tarfile = filepath(tarfile, root=cs_gateway)
      ; need to test for dangling symlink separately because a link to a
      ; non-existent file will return 0 from FILE_TEST with just /SYMLINK
      if (file_test(dst_tarfile, /symlink) $
          || file_test(dst_tarfile, /dangling_symlink)) then begin
        mg_log, 'removing link to tarball in Campaign Storage gateway', $
                name='kcor/eod', /warn
        file_delete, dst_tarfile
      endif

      ; link tarball into Campaign Storage directory
      file_link, filepath(tarfile, root=l2_dir), $
                 dst_tarfile

      ; remove old links to tarballs
      dst_tarfile = filepath(tarfile, root=cs_gateway)
      ; need to test for dangling symlink separately because a link to a
      ; non-existent file will return 0 from FILE_TEST with just /SYMLINK
      if (file_test(dst_tarfile, /symlink) $
          || file_test(dst_tarfile, /dangling_symlink)) then begin
        mg_log, 'removing link to tarball in CS gateway', name='kcor/eod', /warn
        file_delete, dst_tarfile
      endif

      ; link tarball into CS directory
      file_link, filepath(tarfile, root=l2_dir), $
                 dst_tarfile
    endif else begin
      if (strlen(cs_gateway) eq 0L) then begin
        mg_log, 'cs_gateway not specified, not sent to CS', name='kcor/eod', /info
      endif else begin
        mg_log, 'not sending to Campaign Storage', name='kcor/eod', /info
      endelse
    endelse
  endif else begin
    mg_log, 'no files for L2 tarball/tarlist, not creating', $
            name='kcor/eod', /warn
  endelse

  done:
  cd, cwd
  mg_log, 'done sending L2 data to Campaign Storage', name='kcor/eod', /info
end
