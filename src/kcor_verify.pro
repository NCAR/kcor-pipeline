; docformat = 'rst'


;+
; Verify that the given filename is on the HPSS with correct permissions.
;
; :Params:
;   date : in, required, type=string
;     date in the form YYYYMMDD
;   filename : in, required, type=string
;     HPSS filename to check
;   filesize : in, required, type=integer
;     size of given file
;
; :Keywords:
;   run : in, required, type=object
;     KCor run object
;-
pro kcor_verify_hpss, date, filename, filesize, $
                      logger_name=logger_name, run=run, $
                      status=status
  compile_opt strictarr

  hsi_cmd = string(run.hsi, filename, format='(%"%s ls -l %s")')

  spawn, hsi_cmd, hsi_output, hsi_error_output, exit_status=exit_status
  if (exit_status ne 0L) then begin
    mg_log, 'problem connecting to HPSS with command: %s', hsi_cmd, $
            name=logger_name, /error
    mg_log, '%s', mg_strmerge(hsi_error_output), name=logger_name, /error
    status = 1
    goto, hpss_done
  endif

  ; for some reason, hsi puts its output in stderr
  matches = stregex(hsi_error_output, $
                    file_basename(filename, '.tgz') + '\.tgz', $
                    /boolean)
  ind = where(matches, count)
  if (count eq 0L) then begin
    mg_log, '%s tarball for %s not found on HPSS', $
            file_basename(filename), date, $
            name=logger_name, /error
    status = 1L
    goto, hpss_done
  endif else begin
    status_line = hsi_error_output[ind[0]]
    tokens = strsplit(status_line, /extract)

    ; check group ownership of tarball on HPSS
    if (tokens[3] ne 'cordyn') then begin
      mg_log, 'incorrect group owner %s for tarball on HPSS', $
              tokens[3], name=logger_name, /error
      status = 1L
      goto, hpss_done
    endif

    ; check protection of tarball on HPSS
    if (tokens[0] ne '-rw-rw-r--') then begin
      mg_log, 'incorrect permissions %s for tarball on HPSS', $
              tokens[0], name=logger_name, /error
      status = 1L
      goto, hpss_done
    endif

    ; check size of tarball on HPSS
    if (ulong64(tokens[4]) ne filesize) then begin
      mg_log, 'incorrect size %sB for tarball on HPSS', $
              mg_float2str(ulong64(tokens[4]), places_sep=','), $
              name=logger_name, /error
      status = 1L
      goto, hpss_done
    endif

    mg_log, 'verified %s tarball on HPSS', file_basename(filename), $
            name=logger_name, /info
  endelse

  hpss_done:
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
  logger_name = 'kcor/verify'

  _config_filename = file_expand_path(n_elements(config_filename) eq 0L $
                       ? filepath('kcor.cfg', root=mg_src_root()) $
                       : config_filename)

  if (n_elements(date) eq 0L) then begin
    mg_log, 'date argument is missing', name=logger_name, /error
    status = 1L
    goto, done
  endif

  if (~file_test(_config_filename, /regular)) then begin
    mg_log, 'config file not found', name=logger_name, /error
    status = 1L
    goto, done
  endif

  run = kcor_run(date, config_filename=_config_filename)

  mg_log, name=logger_name, logger=logger
  logger->setProperty, format='%(time)s %(levelshortname)s: %(message)s'

  ; list_file : listing of the tar file for that date 
  ; log_file  : original t1.log file 

  ; verify that the listing of the tar files includes all files and 
  ; only all the files that are in the original t1.log

  ; NOTE: the tar file includes the t1.log itself so the list_file 
  ;       has one extra line 

  mg_log, 'verifying %s', date, name=logger_name, /info
  mg_log, 'raw directory %s', filepath(date, root=run.raw_basedir), $
          name=logger_name, /info

  ; don't check days with no data
  l0_tarball_filename = filepath(date + '_kcor_l0.tgz', $
                                 subdir=[date, 'level0'], $
                                 root=run.raw_basedir)
  l1_tarball_filename = filepath(date + '_kcor_l1.5.tgz', $
                                 subdir=[date, 'level1'], $
                                 root=run.raw_basedir)

  fits_files = file_search(filepath('*.fts.gz', $
                                    subdir=[date, 'level0'], $
                                    root=run.raw_basedir), $
                           count=n_fits_files)
  if (n_fits_files eq 0L && ~file_test(l0_tarball_filename)) then begin
    mg_log, 'no FITS files or tarball, skipping', name=logger_name, /info
    goto, done
  endif

  log_filename = filepath(date + '.kcor.t1.log', $
                          subdir=[date, 'level0'], $
                          root=run.raw_basedir)
  machine_log_filename = filepath(date + '.kcor.machine.log', $
                                  subdir=[date], $
                                  root=run.raw_basedir)
  list_filename = filepath(date + '_kcor_l0.tarlist', $
                           subdir=[date, 'level0'], $
                           root=run.raw_basedir)

  ; TEST: check if log/list files exist

  if (file_test(log_filename)) then n_log_lines  = file_lines(log_filename)
  if (file_test(machine_log_filename)) then begin
    n_machine_log_lines  = file_lines(machine_log_filename)
  endif
  if (file_test(list_filename)) then n_list_lines = file_lines(list_filename)

  if (~file_test(log_filename)) then begin 
    mg_log, 't1.log file not found', name=logger_name, /error
    status = 1L
    goto, test2_done
  endif
  if (~file_test(machine_log_filename)) then begin 
     mg_log, 'machine.log file not found', name=logger_name, /error
     status = 1L
     goto, test2_done
  endif
  if (~file_test(list_filename)) then begin 
    mg_log, 'tarlist file not found'
    status = 1L
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
    status = 1L
    goto, test1_done
  endif

  if ((n_machine_log_lines ne n_log_lines)) then begin 
    mg_log, '# of lines in t1.log and machine.log do not match', $
            name=logger_name, /error
    status = 1L
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
                                         root=run.raw_basedir), $
                                run=run, logger_name=logger_name)
  kcor_raw_size = run->epoch('raw_filesize')   ; bytes
  ind = where(unzipped_sizes ne kcor_raw_size, n_bad_sizes)
  if (n_bad_sizes ne 0L) then begin
    mg_log, '%d files in tar list with bad unzipped size', $
            n_bad_sizes, $
            name=logger_name, /error
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
      status = 1L
      free_lun, lun
      goto, test1_done
    endif

    if (npick lt 1L) then begin
      mg_log, 'log file %s in tar list %d times', log_name, npick, $
              name=logger_name, /error
      status = 1L
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
      status = 1L
      free_lun, log_lun, machine_log, lun
      goto, test1_done
    endif
    if (log_tokens[1] ne machine_log_tokens[1]) then begin
      mg_log, 'mis-matched sizes in t1 and machine logs for %s: %s and %s', $
              log_tokens[0], $
              log_tokens[1], $
              machine_log_tokens[1], $
              name=logger_name, /error
      status = 1L
      free_lun, log_lun, machine_log, lun
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
      status = 1L
      free_lun, lun
      goto, test2_done
    endif

    pick = where(log_names eq filename, npick)
    if (npick lt 1) then begin
      mg_log, 'extra file %s found in tar list', filename, $
              name=logger_name, /error
      status = 1L
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

  ssh_key_str = run.ssh_key eq '' ? '' : string(run.ssh_key, format='(%"-i %s")')
  cmd = string(ssh_key_str, run.raw_remote_server, run.raw_remote_dir, date, $
               format='(%"ssh %s %s ls %s/%s/*.fts | wc -l")')
  spawn, cmd, output, error_output, exit_status=exit_status
  if (exit_status ne 0L) then begin
    mg_log, 'problem checking raw files on %s:%s', $
            run.raw_remote_server, run.raw_remote_dir, $
            name=logger_name, /error
    mg_log, 'Command: %s', cmd, name=logger_name, /error
    mg_log, '%s', strjoin(error_output, ' '), name=logger_name, /error
    status = 1L
    goto, mlso_server_test_done
  endif

  n_raw_files = long(output[0])
  if (n_elements(n_log_lines) gt 0L) then begin
    if (n_log_lines eq n_raw_files) then begin
      mg_log, '# of L0 on %s (%d) matches t1.log (%d)', $
              run.raw_remote_server, n_raw_files, n_log_lines, $
              name=logger_name, /info
    endif else begin
      mg_log, '# of L0 on %s (%d) does not match t1.log (%d)', $
              run.raw_remote_server, n_raw_files, n_log_lines, $
              name=logger_name, /error
      status = 1L
      goto, mlso_server_test_done
    endelse
  endif else if (n_elements(n_list_lines) gt 0L) then begin
    if (n_list_lines - 2L eq n_raw_files) then begin
      mg_log, '# of L0 on %s (%d) matches tarlist (%d)', $
              run.raw_remote_server, n_raw_files, n_list_lines - 2L, $
              name=logger_name, /info
    endif else begin
      mg_log, '# of L0 on %s (%d) does not match tarlist (%d)', $
              run.raw_remote_server, n_raw_files, n_list_lines - 2L, $
              name=logger_name, /error
      status = 1L
      goto, mlso_server_test_done
    endelse
  endif else begin
    mg_log, 'nothing to compare number of files on %s to', $
            run.raw_remote_server, $
            name=logger_name, /error
  endelse


  mlso_server_test_done:

  ; skip tarball and HPSS checks if there were no good quality files
  oka_filename = filepath('oka.ls', $
                          subdir=[date, 'q'], $
                          root=run.raw_basedir)
  if (~file_test(oka_filename, /regular) || file_lines(oka_filename) eq 0L) then begin
    mg_log, 'no good quality files, skipping tarball and HPSS checks', $
            name=logger_name, /info
    goto, done
  endif


  ; TEST: tgz size

  l0_tarball_size = mg_filesize(l0_tarball_filename)
  l1_tarball_size = mg_filesize(l1_tarball_filename)

  if (~file_test(l0_tarball_filename, /regular)) then begin
    mg_log, 'no tarball', name=logger_name, /error
    status = 1
    goto, compress_ratio_done
  endif

  test_tgz_compression_ratio = 1B
  if (test_tgz_compression_ratio) then begin 
    ; test the size of tgz vs. entire directory of raw files
    ; compression factor should be 15-16%

    du_cmd = string(filepath('*.{fts.gz,log}', subdir=[date, 'level0'], $
                             root=run.raw_basedir), $
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

    if ((compress_ratio lt run.min_compression_ratio) $
          or (compress_ratio gt run.max_compression_ratio)) then begin
      mg_log, 'unusual compression ratio %0.2f', compress_ratio, $
              name=logger_name, /warn
      status = 1L
      goto, compress_ratio_done
    endif
  endif else begin
    mg_log, 'skipping tarball compression ratio check', name=logger_name, /info
  endelse

  compress_ratio_done:

  ; TEST: check if there are files in the directory that should not be there 

;  files = file_search(filepath('*', subdir=date, root=run.raw_basedir), count=n_files)
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

  ; TEST: check HPSS for L0/L1 tarball of correct size, ownership, and
  ; protections

  check_hpss = 1B
  if (check_hpss) then begin
    year = strmid(date, 0, 4)
    kcor_verify_hpss, date, $
                      string(year, date, $
                             format='(%"/CORDYN/KCOR/%s/%s_kcor_l0.tgz")'), $
                      l0_tarball_size, $
                      status=status, $
                      logger_name=logger_name, run=run
    kcor_verify_hpss, date, $
                      string(year, date, $
                             format='(%"/CORDYN/KCOR/%s/%s_kcor_l1.5.tgz")'), $
                      l1_tarball_size, $
                      status=status, $
                      logger_name=logger_name, run=run
  endif else begin
    mg_log, 'skipping HPSS check', name=logger_name, /info
  endelse

  done:

  if (status eq 0L) then begin
    mg_log, 'verification succeeded', name=logger_name, /info
  endif else begin
    mg_log, 'verification failed', name=logger_name, /error
  endelse

  obj_destroy, run
end


; main-level example program

logger_name = 'kcor/verify'
cfile = 'kcor.mgalloy.mlsodata.production.cfg'
config_filename = filepath(cfile, subdir=['..', 'config'], root=mg_src_root())

dates = ['20180818']
for d = 0L, n_elements(dates) - 1L do begin
  kcor_verify, dates[d], config_filename=config_filename

  if (d lt n_elements(dates) - 1L) then begin
    mg_log, name=logger_name, logger=logger
    logger->setProperty, format='%(time)s %(levelshortname)s: %(message)s'
    mg_log, '-----------------------------------', name=logger_name, /info
  endif
endfor

end
