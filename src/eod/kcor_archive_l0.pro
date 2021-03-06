; docformat = 'rst'

;+
; Archive KCor L0 FITS files to HPSS.
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;   reprocess : in, optional, type=boolean
;     set to indicate a reprocessing; level 0 files are not distributed in a
;     reprocessing
;-
pro kcor_archive_l0, run=run, reprocess=reprocess
  compile_opt strictarr

  cd, current=cwd

  date = run.date

  date_dir = filepath(date, root=run->config('processing/raw_basedir'))
  l0_dir   = filepath('level0', root=date_dir)

  if (~file_test(l0_dir, /directory)) then begin
    file_mkdir, l0_dir
    file_chmod, l0_dir, /a_read, /a_execute, /u_write
  endif

  cd, l0_dir

  year   = long(strmid(date, 0, 4))
  month  = long(strmid(date, 4, 2))
  day    = long(strmid(date, 6, 2))

  now = systime(/julian)
  caldat, now, cmonth, cday, cyear, chour, cminute, csecond

  if (year lt 2013 || year gt cyear) then begin
    mg_log, 'invalid year %d', year, name='kcor/eod', /error
    goto, done
  endif

  tarfile  = string(date, format='(%"%s_kcor_l0.tgz")')
  tarlist  = string(date, format='(%"%s_kcor_l0.tarlist")')

  if (file_test(tarfile, /regular)) then begin
    mg_log, 'tarfile already exists: %s', tarfile, name='kcor/eod', /warn
    goto, done
  endif

  l0_fits_files = file_search('*_kcor.fts.gz', count=n_l0_fits_files)
  if (n_l0_fits_files eq 0L) then begin
    mg_log, 'no L0 FITS files to archive to HPSS', name='kcor/eod', /warn
    goto, done
  endif else begin
    mg_log, '%d compressed files exist in L0 dir', n_l0_fits_files, $
            name='kcor/eod', /info
  endelse

  if (run->config('eod/send_to_hpss') && ~keyword_set(reprocess)) then begin
    tar_cmd = string(tarfile, $
                     format='(%"tar cf %s *_kcor.fts.gz *.log")')
    mg_log, 'creating tarfile %s...', tarfile, name='kcor/eod', /info
    spawn, tar_cmd, result, error_result, exit_status=status
    if (status ne 0L) then begin
      mg_log, 'problem tarring files with command: %s', tar_cmd, $
              name='kcor/eod', /error
      mg_log, '%s', strjoin(error_result, ' '), name='kcor/eod', /error
      goto, done
    endif
    if (file_test(tarfile, /user)) then begin
      file_chmod, tarfile, /a_read, /g_write
    endif else begin
      !null = file_test(tarfile, get_mode=mode)
      if (mode and '664'o ne '664'o) then begin
        mg_log, 'bad permissions on %s', tarfile, name='kcor/eod', /warn
      endif
    endelse

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

    !null = file_test(tarlist, get_mode=mode)
    if (mode and '664'o ne '664'o) then begin
      if (file_test(tarlist, /user)) then begin
        file_chmod, tarlist, /a_read, /g_write
      endif else begin
        mg_log, 'bad permissions %o on %s', mode, tarlist, $
                name='kcor/eod', /warn
      endelse
    endif
  endif else begin
    mg_log, 'not creating tarfile or tarlist', name='kcor/eod', /info
  endelse

  if (run->config('eod/send_to_hpss') && ~keyword_set(reprocess)) then begin
    ; create HPSS gateway directory if needed
    hpss_gateway = run->config('results/hpss_gateway')
    if (~file_test(hpss_gateway, /directory)) then begin
      file_mkdir, hpss_gateway
      file_chmod, hpss_gateway, /a_read, /a_execute, /u_write, /g_write
    endif

    ; remove old links to tarballs
    dst_tarfile = filepath(tarfile, root=hpss_gateway)
    ; need to test for dangling symlink separately because a link to a
    ; non-existent file will return 0 from FILE_TEST with just /SYMLINK
    if (file_test(dst_tarfile, /symlink) $
          || file_test(dst_tarfile, /dangling_symlink)) then begin
      mg_log, 'removing link to tarball in HPSS gateway', name='kcor/eod', /warn
      file_delete, dst_tarfile
    endif

    file_link, filepath(tarfile, root=l0_dir), $
               dst_tarfile
  endif else begin
    mg_log, 'not sending to HPSS', name='kcor/eod', /info
  endelse

  if (run->config('eod/send_to_hpss') && ~keyword_set(reprocess)) then begin
    cs_gateway = run->config('results/cs_gateway')
    if (n_elements(cs_gateway) gt 0L && strlen(cs_gateway) gt 0L) then begin
      ; create CS gateway directory if needed
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
        mg_log, 'removing link to tarball in Campaign Storage gateway', name='kcor/eod', /warn
        file_delete, dst_tarfile
      endif
  
      file_link, filepath(tarfile, root=l0_dir), $
                 dst_tarfile
    endif else begin
      mg_log, 'cs_gateway not specified, not sent to Campaign Storage', name='kcor/eod', /info
    endelse
  endif else begin
    mg_log, 'not sending to Campaign Storage', name='kcor/eod', /info
  endelse

  done:
  cd, cwd
  mg_log, 'done', name='kcor/eod', /info
end


; main-level example program

; WARNING: this uses the production config file, so will actually copy L0
; tarball to the HPSS!

date = '20180306'
config_filename = filepath('kcor.mgalloy.kaula.production.cfg', $
                           subdir=['..', '..', 'config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)
kcor_archive_l0, run=run
obj_destroy, run

end
