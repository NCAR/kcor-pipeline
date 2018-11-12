; docformat = 'rst'

;+
; Archive KCor L1 products to HPSS.
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;-
pro kcor_archive_l1, run=run
  compile_opt strictarr

  date = run.date

  if (run.send_to_hpss) then begin
    mg_log, 'sending L1.5 data to HPSS...', name='kcor/eod', /info
  endif else begin
    mg_log, 'not sending L1.5 data to HPSS', name='kcor/eod', /info
  endelse

  cd, current=cwd

  date_dir = filepath(date, root=run.raw_basedir)
  l1_dir   = filepath('level1', root=date_dir)

  if (~file_test(l1_dir, /directory)) then begin
    file_mkdir, l1_dir
    file_chmod, l1_dir, /a_read, /a_execute, /u_write
  endif

  cd, l1_dir

  tarfile  = string(date, format='(%"%s_kcor_l1.5.tgz")')
  tarlist  = string(date, format='(%"%s_kcor_l1.5.tarlist")')
  hpssinfo = string(date, format='(%"%s_kcor_l1.5_tar.ls")')

  ; delete old tarball, tarlist
  if (~file_test(tarfile, /regular)) then file_delete, tarfile, /quiet
  if (~file_test(tarlist, /regular)) then file_delete, tarlist, /quiet

  ; create tarball
  file_types = ['*.fts*', '*.gif', '*.mp4']
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

    if (run.send_to_hpss) then begin
      ; create HPSS gateway directory if needed
      if (~file_test(run.hpss_gateway, /directory)) then begin
        file_mkdir, run.hpss_gateway
        file_chmod, run.hpss_gateway, /a_read, /a_execute, /u_write, /g_write
      endif

      ; remove old links to tarballs
      dst_tarfile = filepath(tarfile, root=run.hpss_gateway)
      ; need to test for dangling symlink separately because a link to a
      ; non-existent file will return 0 from FILE_TEST with just /SYMLINK
      if (file_test(dst_tarfile, /symlink) $
          || file_test(dst_tarfile, /dangling_symlink)) then begin
        mg_log, 'removing link to tarball in HPSS gateway', name='kcor/eod', /warn
        file_delete, dst_tarfile
      endif

      ; link tarball into HPSS directory
      file_link, filepath(tarfile, root=l1_dir), $
                 dst_tarfile
    endif
  endif else begin
    mg_log, 'no files for L1.5 tarball/tarlist, not creating', $
            name='kcor/eod', /warn
  endelse

  done:
  cd, cwd
  mg_log, 'done sending L1.5 data to HPSS', name='kcor/eod', /info
end
