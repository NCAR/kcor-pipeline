; docformat = 'rst'


;+
; Verify that the given filename is on a remote server with correct file size,
; group, and permissions.
;
; :Params:
;   date : in, required, type=string
;     date in the form YYYYMMDD
;   local_filename : in, required, type=string
;     local filename to check against
;   remote_server : in, required, type=string
;     remote_server
;   remote_basedir : in, required, type=string
;     base directory on remote server, i.e., final remote filename will be::
;
;       remote_server:remote_basedir/YYYY/local_filename
;
; :Keywords:
;   logger_name : in, type=string
;     name of logger
;   run : in, required, type=object
;     KCor run object
;   status : out, optional, type=integer
;     set to a named variable to retrieve the error status for the query,
;     0 for none, 1 for unable to compare, 2 for not matching
;-
pro kcor_verify_remote, date, local_filename, remote_server, remote_basedir, $
                        logger_name=logger_name, run=run, $
                        status=status
  compile_opt strictarr

  status = 0L
  year = strmid(date, 0, 4)

  if (~file_test(local_filename, /regular)) then begin
    mg_log, 'local file %s not found', local_filename, name=logger_name, /error
    status = 1L
    goto, remote_done
  endif

  local_filesize = mg_filesize(local_filename)
  basename = file_basename(local_filename)
  remote_filename = filepath(basename, subdir=year, root=remote_basedir)

  ssh_key = run->config('results/ssh_key')
  ssh_key_str = ssh_key eq '' ? '' : string(ssh_key, format='(%"-i %s")')

  cmd = string(ssh_key_str, $
               remote_server, $
               remote_filename, $
               format='(%"ssh %s %s ls -l %s")')
  spawn, cmd, output, error_output, exit_status=exit_status
  if (exit_status ne 0L) then begin
    mg_log, 'problem checking file on %s:%s', $
            remote_server, $
            remote_filename, $
            name=logger_name, /error
    mg_log, 'command: %s', cmd, name=logger_name, /error
    mg_log, '%s', strjoin(error_output, ' '), name=logger_name, /error
    status = 1L
    goto, remote_done
  endif

  tokens = strsplit(output[0], /extract, count=n_tokens)
  if (n_tokens ne 9) then begin
    mg_log, 'bad format for ls -l output', name=logger_name, /error
    mg_log, 'output: %s', output[0], name=logger_name, /debug
    status = 2L
    goto, remote_done
  endif

  permissions = tokens[0]
  group = tokens[3]
  remote_filesize = long64(tokens[4])

  if (strmid(permissions, 0, 10) ne '-rw-rw----') then begin
    mg_log, 'bad remote permissions: %s', permissions, name=logger_name, /error
    status = 2L
    goto, remote_done
  endif

  if (group ne 'cordyn') then begin
    mg_log, 'bad remote group: %s', group, name=logger_name, /error
    status = 2L
    goto, remote_done
  endif

  if (remote_filesize ne local_filesize) then begin
    mg_log, 'non-matching file sizes (local: %s B, remote %s B)', $
            mg_float2str(local_filesize, places_sep=','), $
            mg_float2str(remote_filesize, places_sep=','), $
            name=logger_name, /error
    status = 2L
    goto, remote_done
  endif else begin
    mg_log, 'file size on %s: %s', $
            remote_server, $
            mg_float2str(local_filesize, places_sep=','), $
            name=logger_name, /info
  endelse

  remote_done:
  mg_log, 'verified %s tarball on %s', basename, remote_server, $
          name=logger_name, /info
end


;+
; Verify the integrity of the data for a given date.
;
; :Params:
;   date : in, required, type=string
;     date to process, in YYYYMMDD format
;
; :Keywords:
;   config_filename, in, optional, type=string
;     configuration filename to use, default is `comp.cfg` in the `src`
;     directory
;   status : out, optional, type=integer
;     set to a named variable to retrieve the status of the date: 0 for success,
;     anything else indicates a problem
;-
pro kcor_verify, date, config_filename=config_filename, status=status
  compile_opt strictarr

  status = 0L
  ;logger_name = 'kcor/verify'

  catch, error
  if (error ne 0) then begin
    catch, /cancel
    error = 1L
    mg_log, /last_error, /critical
    goto, done
  endif
  
  valid_date = kcor_valid_date(date, msg=msg)
  if (~valid_date) then begin
    mg_log, msg, name=logger_name, /error
    status or= 1L
    goto, done
  endif

  _config_filename = file_expand_path(n_elements(config_filename) eq 0L $
                       ? filepath('kcor.cfg', root=mg_src_root()) $
                       : config_filename)

  if (n_elements(date) eq 0L) then begin
    mg_log, 'date argument is missing', name=logger_name, /error
    status or= 1L
    goto, done
  endif

  if (~file_test(_config_filename, /regular)) then begin
    mg_log, 'config file not found', name=logger_name, /error
    status or= 1L
    goto, done
  endif

  run = kcor_run(date, config_filename=_config_filename)
  if (~obj_valid(run)) then begin
    mg_log, 'invalid run', name=logger_name, /error
    status or= 1L
    goto, done
  endif

  mg_log, name=logger_name, logger=logger
  logger->setProperty, format='%(time)s %(levelshortname)s: %(message)s'

  ; list_file : listing of the tar file for that date 
  ; log_file  : original t1.log file 

  ; verify that the listing of the tar files includes all files and 
  ; only all the files that are in the original t1.log

  ; NOTE: the tar file includes the t1.log itself so the list_file 
  ;       has one extra line 

  mg_log, 'verifying %s', date, name=logger_name, /info
  mg_log, 'raw directory %s', filepath(date, root=run->config('processing/raw_basedir')), $
          name=logger_name, /info

  ; don't check days with no data
  l0_tarball_filename = filepath(date + '_kcor_l0.tgz', $
                                 subdir=[date, 'level0'], $
                                 root=run->config('processing/raw_basedir'))
  l1_tarball_filename = filepath(date + '_kcor_l1.tgz', $
                                 subdir=[date, 'level1'], $
                                 root=run->config('processing/raw_basedir'))
  l2_tarball_filename = filepath(date + '_kcor_l2.tgz', $
                                 subdir=[date, 'level2'], $
                                 root=run->config('processing/raw_basedir'))

  fits_files = file_search(filepath('*.fts.gz', $
                                    subdir=[date, 'level0'], $
                                    root=run->config('processing/raw_basedir')), $
                           count=n_fits_files)
  if (n_fits_files eq 0L && ~file_test(l0_tarball_filename)) then begin
    mg_log, 'no FITS files or tarball, skipping', name=logger_name, /info
    goto, done
  endif

  log_filename = filepath(date + '.kcor.t1.log', $
                          subdir=[date, 'level0'], $
                          root=run->config('processing/raw_basedir'))
  machine_log_filename = filepath(date + '.kcor.machine.log', $
                                  subdir=[date], $
                                  root=run->config('processing/raw_basedir'))
  list_filename = filepath(date + '_kcor_l0.tarlist', $
                           subdir=[date, 'level0'], $
                           root=run->config('processing/raw_basedir'))

  ; TEST: check if log/list files exist

  if (file_test(log_filename)) then n_log_lines  = file_lines(log_filename)
  if (file_test(machine_log_filename)) then begin
    n_machine_log_lines  = file_lines(machine_log_filename)
  endif
  if (file_test(list_filename)) then n_list_lines = file_lines(list_filename)

  if (~file_test(log_filename)) then begin 
    mg_log, 't1.log file not found', name=logger_name, /error
    status or= 1L
    goto, test2_done
  endif
  if (~file_test(machine_log_filename)) then begin 
     mg_log, 'machine.log file not found', name=logger_name, /error
     status or= 1L
     goto, test2_done
  endif
  if (~file_test(list_filename)) then begin 
    mg_log, 'tarlist file not found'
    status or= 1L
    goto, test2_done
  endif 

  ; TEST: if log file and list file exist, check number of lines:
  ;   list_file # of lines = log_file # of lines - 1
  ;   because the t1.log file is included in the tar

  mg_log, 'log file: %s (%d lines)', $
          file_basename(log_filename), n_log_lines, $
          name=logger_name, /info
  mg_log, 'machine log file: %s (%d lines)', $
          file_basename(machine_log_filename), n_machine_log_lines, $
          name=logger_name, /info
  mg_log, 'list file: %s (%d lines)', $
          file_basename(list_filename), n_list_lines, $
          name=logger_name, /info

  ; subtract t1, t2, and machine logs from tarlist file, i.e., -3 below
  if ((n_log_lines ne n_list_lines - 3) || (n_list_lines eq 0)) then begin 
    mg_log, '# of lines in t1.log and tarlist do not match', $
            name=logger_name, /error
    status or= 1L
    goto, test1_done
  endif

  if ((n_machine_log_lines ne n_log_lines)) then begin 
    mg_log, '# of lines in t1.log and machine.log do not match', $
            name=logger_name, /error
    status or= 1L
    goto, test1_done
  endif

  ; TEST: match sizes of files to log

  list_names = strarr(n_list_lines - 3L)
  list_sizes = lonarr(n_list_lines - 3L)

  line = ''
  openr, lun, list_filename, /get_lun
  for i = 0L, n_list_lines - 4L do begin 
    readf, lun, line
    tokens = strsplit(line, /extract)
    list_names[i] = tokens[5]
    list_sizes[i] = tokens[2]
  endfor
  free_lun, lun

  unzipped_sizes = kcor_zipsize(filepath(list_names, $
                                         subdir=[date, 'level0'], $
                                         root=run->config('processing/raw_basedir')), $
                                run=run, logger_name=logger_name)
  kcor_raw_size = run->epoch('raw_filesize')   ; bytes
  ind = where(unzipped_sizes ne kcor_raw_size, n_bad_sizes)
  if (n_bad_sizes ne 0L) then begin
    mg_log, '%d files in tar list with bad unzipped size', $
            n_bad_sizes, $
            name=logger_name, /error
    status or= 1L
  endif

  ; TEST: check that any file listed in the log is also in the list - no missing
  ; TEST: check that any file listed in the log is listed only one -- no double  
  ; TEST: check that all files have the correct size 
 
  log_name = '' 
  log_size = 0L

  openr, lun, log_filename, /get_lun
  for  j = 0, n_log_lines - 1L do begin 
    readf, lun, log_name, log_size, format='(a24, 1x, f8.0)'
    log_name += '.gz'
    pick = where(list_names eq log_name, npick)

    if (npick lt 1L) then begin
      mg_log, 'log file %s missing in tar list', log_name, $
              name=logger_name, /error
      status or= 1L
      free_lun, lun
      goto, test1_done
    endif

    if (npick lt 1L) then begin
      mg_log, 'log file %s in tar list %d times', log_name, npick, $
              name=logger_name, /error
      status or= 1L
      free_lun, lun
      goto, test1_done
    endif
  endfor 
  free_lun, lun

  openr, log_lun, log_filename, /get_lun
  openr, machine_log_lun, machine_log_filename, /get_lun
  log_line = ''
  machine_log_line = ''
  for j = 0L, n_log_lines - 1L do begin
    readf, log_lun, log_line
    readf, machine_log_lun, machine_log_line

    log_tokens = strsplit(log_line, /extract)
    machine_log_tokens = strsplit(machine_log_line, /extract)
    if (log_tokens[0] ne machine_log_tokens[0]) then begin
      mg_log, 'mis-matched filenames in t1 and machine logs: %s and %s', $
              log_tokens[0], $
              machine_log_tokens[0], $
              name=logger_name, /error
      status or= 1L
      free_lun, log_lun, machine_log_lun
      goto, test1_done
    endif
    if (log_tokens[1] ne machine_log_tokens[1]) then begin
      mg_log, 'mis-matched sizes in t1 and machine logs for %s: %s and %s', $
              log_tokens[0], $
              log_tokens[1], $
              machine_log_tokens[1], $
              name=logger_name, /error
      status or= 1L
      free_lun, log_lun, machine_log_lun
      goto, test1_done
    endif
  endfor
  free_lun, log_lun, machine_log_lun


  ; TEST: check range of file sizes
  testsize = ulong64(list_sizes)
  minsize  = min(testsize)
  maxsize  = max(testsize)

  ; changed to acount for larger 17-points files
  ; if (minsize ge 81996480 and maxsize le 254393280) then begin

;  if ((minsize ge 13750000) and (maxsize le 15900000)) then begin 
;    mg_log, 'L0 FITS file sizes (%sB - %sB) OK', $
;            mg_float2str(minsize, places_sep=','), $
;            mg_float2str(maxsize, places_sep=','), $
;            name=logger_name, /info
;  endif else begin
;    mg_log, 'L0 FITS file sizes (%sB - %sB) out of expected range', $
;            mg_float2str(minsize, places_sep=','), $
;            mg_float2str(maxsize, places_sep=','), $
;            name=logger_name, /error
;
;    status = 1L
;    goto, test1_done
;  endelse

  test1_done:

  ; read log to find names and sizes 

  log_names = strarr(n_log_lines)
  log_sizes = lonarr(n_log_lines)

  openr, lun, log_filename, /get_lun
  readf, lun, log_names, format='(a24)'
  free_lun, lun

  log_names += '.gz'

  openr, lun, log_filename, /get_lun
  readf, lun, log_sizes, format='(25x, f8.0)'
  free_lun, lun

  ; TEST: check that any file listed in the list is also in the t1.log
  ; (e.g. no extra FTS files were put in the directory from other days 
  ; and went into the tar file)

  ; TEST: check again that any file listed in the list has the correct size
  ; this should be no different from test above

  ; TEST: check that any file listed in the list has the correct protection

  protection = '-rw-rw-r--'

  tempf = ''
  openr, lun, list_filename, /get_lun

  ; last three lines are t1, t2, and machine logs
  for j = 0L, n_list_lines - 4L do begin
    readf, lun, tempf

    ; read files and size in the tar list 
    tokens = strsplit(tempf, /extract)
    filename = tokens[5]
    filesize = ulong64(tokens[2])

    if (tokens[0] ne protection) then begin 
      mg_log, 'protection for %s is wrong: %s', filename, tokens[0], $
              name=logger_name, /error
      status or= 1L
      free_lun, lun
      goto, test2_done
    endif

    pick = where(log_names eq filename, npick)
    if (npick lt 1) then begin
      mg_log, 'extra file %s found in tar list', filename, $
              name=logger_name, /error
      status or= 1L
      free_lun, lun
      goto, test2_done
    endif else begin 
;      if (filesize ne log_sizes[pick]) then begin 
;        mg_log, '%s has size %sB in list file, %sB in log file', $
;                filename, $
;                mg_float2str(filesize, places_sep=','), $
;                mg_float2str(log_sizes[pick], places_sep=','), $
;                name=logger_name, /error
;        status = 1L
;
;        goto, test2_done
;      endif
    endelse 
  endfor 

  if (n_log_lines eq n_list_lines - 1L) then begin
    mg_log, 'no extra files in tar listing and protection OK', $
            name=logger_name, /info
  endif

  free_lun, lun

  test2_done:


  ; TEST: compare t1/t2 log vs. what is present on MLSO server
  raw_remote_server = run->config('verification/raw_remote_server')
  raw_remote_dir = run->config('verification/raw_remote_dir')
  if (n_elements(raw_remote_server) gt 0L && n_elements(raw_remote_dir) gt 0L) then begin
    ssh_key_str = run->config('results/ssh_key') eq '' $
                  ? '' $
                  : string(run->config('results/ssh_key'), format='(%"-i %s")')
    cmd = string(ssh_key_str, $
                 raw_remote_server, $
                 raw_remote_dir, $
                 date, $
                 format='(%"ssh %s %s ls %s/%s/*.fts | wc -l")')
    spawn, cmd, output, error_output, exit_status=exit_status
    if (exit_status ne 0L) then begin
      mg_log, 'problem checking raw files on %s:%s', $
              run->config('verification/raw_remote_server'), $
              run->config('verification/raw_remote_dir'), $
              name=logger_name, /error
      mg_log, 'command: %s', cmd, name=logger_name, /error
      mg_log, '%s', strjoin(error_output, ' '), name=logger_name, /error
      status or= 1L
      goto, mlso_server_test_done
    endif

    n_raw_files = long(output[0])
    if (n_elements(n_log_lines) gt 0L) then begin
      if (n_log_lines eq n_raw_files) then begin
        mg_log, '# of L0 on %s (%d) matches t1.log (%d)', $
                run->config('verification/raw_remote_server'), n_raw_files, n_log_lines, $
                name=logger_name, /info
      endif else begin
        mg_log, '# of L0 on %s (%d) does not match t1.log (%d)', $
                run->config('verification/raw_remote_server'), n_raw_files, n_log_lines, $
                name=logger_name, /error
        status or= 1L
        goto, mlso_server_test_done
      endelse
    endif else if (n_elements(n_list_lines) gt 0L) then begin
      if (n_list_lines - 2L eq n_raw_files) then begin
        mg_log, '# of L0 on %s (%d) matches tarlist (%d)', $
                run->config('verification/raw_remote_server'), n_raw_files, n_list_lines - 2L, $
                name=logger_name, /info
      endif else begin
        mg_log, '# of L0 on %s (%d) does not match tarlist (%d)', $
                run->config('verification/raw_remote_server'), n_raw_files, n_list_lines - 2L, $
                name=logger_name, /error
        status or= 1L
        goto, mlso_server_test_done
      endelse
    endif else begin
      mg_log, 'nothing to compare number of files on %s to', $
              run->config('verification/raw_remote_server'), $
              name=logger_name, /error
    endelse
  endif else begin
    mg_log, 'no remote location specified, skipping check', name=logger_name, /warn
  endelse


  mlso_server_test_done:

  ; skip tarball and archive checks if there were no good quality files
  oka_filename = filepath('oka.ls', $
                          subdir=[date, 'q'], $
                          root=run->config('processing/raw_basedir'))
  if (~file_test(oka_filename, /regular) || file_lines(oka_filename) eq 0L) then begin
    mg_log, 'no good quality files, skipping tarball and archive checks', $
            name=logger_name, /info
    goto, done
  endif


  ; TEST: tgz size

  l0_tarball_size = mg_filesize(l0_tarball_filename)
  l1_tarball_size = mg_filesize(l1_tarball_filename)
  l2_tarball_size = mg_filesize(l2_tarball_filename)

  l0_tarball_mtime = (file_info(l0_tarball_filename)).mtime
  l1_tarball_mtime = (file_info(l1_tarball_filename)).mtime
  l2_tarball_mtime = (file_info(l2_tarball_filename)).mtime

  if (~file_test(l0_tarball_filename, /regular)) then begin
    if (run->config('realtime/reprocess')) then begin
      mg_log, 'skipping L0 compression test on reprocessing', $
              name=logger_name, /warn
    endif else begin
      mg_log, 'no L0 tarball', name=logger_name, /error
      status or= 1
    endelse
    goto, compress_ratio_done
  endif

  if (~file_test(l1_tarball_filename, /regular)) then begin
    mg_log, 'no L1 tarball', name=logger_name, /warn
    status or= 1
    goto, compress_ratio_done
  endif

  if (~file_test(l2_tarball_filename, /regular)) then begin
    mg_log, 'no L2 tarball', name=logger_name, /warn
    status or= 1
    goto, compress_ratio_done
  endif

  test_tgz_compression_ratio = 1B
  if (test_tgz_compression_ratio) then begin 
    ; test the size of tgz vs. entire directory of raw files
    ; compression factor should be 15-16%

    du_cmd = string(filepath('*.{fts.gz,log}', subdir=[date, 'level0'], $
                             root=run->config('processing/raw_basedir')), $
                    format='(%"du -scb %s | tail -1")')
    spawn, du_cmd, du_output
    tokens = strsplit(du_output[0], /extract)
    dir_size = ulong64(tokens[0])

    compress_ratio = float(dir_size) / float(l0_tarball_size)

    mg_log, 'tarball size: %s bytes', $
            mg_float2str(l0_tarball_size, places_sep=','), $
            name=logger_name, /info
    mg_log, 'dir size: %s bytes', $
            mg_float2str(dir_size, places_sep=','), $
            name=logger_name, /info
    mg_log, 'compression ratio: %0.2f', compress_ratio, name=logger_name, /info

    if ((compress_ratio lt run->config('verification/min_compression_ratio')) $
          or (compress_ratio gt run->config('verification/max_compression_ratio'))) then begin
      mg_log, 'unusual compression ratio %0.2f', compress_ratio, $
              name=logger_name, /warn
      status or= 1L
      goto, compress_ratio_done
    endif
  endif else begin
    mg_log, 'skipping tarball compression ratio check', name=logger_name, /info
  endelse

  compress_ratio_done:

  ; TEST: check if there are files in the directory that should not be there 

;  files = file_search(filepath('*', subdir=date, root=run->config('processing/raw_basedir')), count=n_files)
;  if (n_log_lines lt n_files - 3L) then begin
;    n_extra = n_files - 3L - n_log_files
;    mg_log, 'extra %d file%s in raw dir: %d in log, %d in dir', $
;            n_extra, n_extra eq 1 ? '' : 's', n_log_lines, n_files, $
;            name=logger_name, /error
;    status = 1B
;    goto, extra_files_done
;  endif else if (n_log_lines gt n_files - 3L) then begin
;    n_missing = n_log_lines - n_files + 3L
;    mg_log, 'missing %d file%s in raw dir: %d in log, %d in dir', $
;            n_missing, n_missing eq 1 ? '' : 's', n_log_lines, n_files, $
;            name=logger_name, /error
;    status = 1B
;    goto, extra_files_done
;  endif else begin
;    mg_log, 'number of files OK', name=logger_name, /info
;  endelse
;
;  extra_files_done:

  ; check Campaign Storage
  remote_server = run->config('verification/archive_remote_server')
  check_campaign_storage = n_elements(remote_server) gt 0L
  if (check_campaign_storage) then begin
    remote_basedir = run->config('verification/archive_remote_basedir')
    if (file_test(l0_tarball_filename, /regular)) then begin
      kcor_verify_remote, date, l0_tarball_filename, remote_server, remote_basedir, $
                          logger_name=logger_name, run=run, $
                          status=cs_status
      status or= cs_status
    endif
    if (file_test(l1_tarball_filename, /regular)) then begin
      kcor_verify_remote, date, l1_tarball_filename, remote_server, remote_basedir, $
                          logger_name=logger_name, run=run, $
                          status=cs_status
      status or= cs_status
    endif
    if (file_test(l2_tarball_filename, /regular)) then begin
      kcor_verify_remote, date, l2_tarball_filename, remote_server, remote_basedir, $
                          logger_name=logger_name, run=run, $
                          status=cs_status
      status or= cs_status
    endif
  endif else begin
    mg_log, 'skipping Campaign Storage check', name=logger_name, /info
  endelse

  done:

  if (status eq 0L) then begin
    mg_log, 'verification succeeded', name=logger_name, /info
  endif else begin
    mg_log, 'verification failed', name=logger_name, /error
  endelse

  if (obj_valid(run)) then obj_destroy, run
end


; main-level example program

config_filename = filepath('kcor.production.cfg', $
                           subdir=['..', 'config'], $
                           root=mg_src_root())

dates = ['20201228', '20201229']
for d = 0L, n_elements(dates) - 1L do begin
  kcor_verify, dates[d], config_filename=config_filename, status=status
  print, status, format='(%"status: %d")'
endfor

end
