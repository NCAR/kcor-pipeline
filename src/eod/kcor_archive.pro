; docformat = 'rst'

;+
; Archive KCor L0 FITS files to HPSS.
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;-
pro kcor_archive, run=run
  compile_opt strictarr

  cd, current=cwd
  cd, l0_dir

  date = run.date
  year   = long(strmid(date, 0, 4))
  month  = long(strmid(date, 4, 2))
  day    = long(strmid(date, 6, 2))

  now = systime(/julian)
  caldat, now, cmonth, cday, cyear, chour, cminute, csecond

  if (year lt 2013 || year gt cyear) then begin
    mg_log, 'invalid year %d', year, name='kcor/eod', /error
    goto, done
  endif

  date_dir = filepath(date, root=run.raw_basedir)
  l0_dir   = filepath('level0', root=date_dir)
  tarfile  = string(date, format='(%"%s_kcor_l0.tgz")')
  tarlist  = string(date, format='(%"%s_kcor_l0.tarlist")')
  hpssinfo = string(date, format='(%"%s_kcor_l0_tar.ls")')

  mg_log, 'tarfile: %s', tarfile, name='kcor/eod', /info
  mg_log, 'tarlist: %s', tarlist, name='kcor/eod', /info

  if (~file_test(l0_dir, /directory)) then begin
    file_mkdir, l0_dir
    file_chmod, l0_dir, /a_read, /a_execute, /u_write
  endif

  if (file_test(tarfile, /regular)) then begin
    mg_log, 'tarfile already exists: %s', tarfile, name='kcor/eod', /warn
    goto, done
  endif

  l0_fits_files = file_search('*kcor.fts', count=n_l0_fits_files)
  if (n_l0_fits_files eq 0L) then begin
    mg_log, 'No L0 FITS files to archive to HPSS', name='kcor/eod', /warn
    goto, done
  endif

  zip_cmd = string(run.gzip, format='(%"%s *kcor.fts")')
  mg_log, 'zipping L0 files...', name='kcor/eod', /info
  spawn, zip_cmd, result, error_result, exit_status=status
  if (status ne 0L) then begin
    mg_log, 'problem zipping files with command: %s', zip_cmd, $
            name='kcor/eod', /error
    mg_log, '%s', error_result, name='kcor/eod', /error
    goto, done
  endif

  ; verify there are some compressed L0 FITS files in L0 directory
  gz_fits_files = file_search('*kcor.fts.gz', count=n_gz_fits_files)
  if (n_gz_fits_files eq 0L) then begin
    mg_log, 'no L0 compressed files exist in L0 dir: %s', l0_dir, $
            name='kcor/eod', /error
    goto, done
  endif

  tar_cmd = string(tarfile, $
                   format='(%"tar cf %s *.kcor.fts.gz *t1.log *t2.log")')
  spawn, tar_cmd, result, error_result, exit_status=status
  if (status ne 0L) then begin
    mg_log, 'problem tarring files with command: %s', tar_cmd, $
            name='kcor/eod', /error
    mg_log, '%s', error_result, name='kcor/eod', /error
    goto, done
  endif
  file_chmod, tarfile, /a_read, /g_write

  tarlist_cmd = string(tarfile, tarlist, $
                       format='(%"tar tfv %s > %s")')
  spawn, tarlist_cmd, result, error_result, exit_status=status
  if (status ne 0L) then begin
    mg_log, 'problem create tarlist file with command: %s', tarlist_cmd, $
            name='kcor/eod', /error
    mg_log, '%s', error_result, name='kcor/eod', /error
    goto, done
  endif
  file_chmod, tarlist, /a_read, /g_write

  file_link, filepath(tarfile, root=l0_dir), run.hpss_gateway

  done:

  cd, cwd
  mg_log, 'done', name='kcor/eod', /info
end
