; docformat = 'rst'

;+
; Main end-of-day routine.
;
; :Params:
;   date : in, required, type=date
;     date in the form 'YYYYMMDD' to produce calibration for
;
; :Keywords:
;   config_filename : in, required, type=string
;     filename of configuration file
;-
pro kcor_eod, date, config_filename=config_filename
  compile_opt strictarr

  catch, error
  if (error ne 0L) then begin
    catch, /cancel
    mg_log, /last_error, name='kcor/eod', /critical
    goto, done
  endif

  run = kcor_run(date, config_filename=config_filename)

  mg_log, 'starting end-of-day processing for %s', date, name='kcor/eod', /info

  date_dir = filepath(date, root=run.raw_basedir)
  if (~file_test(date_dir, /directory)) then begin
    mg_log, '%s does not exist', date_dir, name='kcor/eod', /error
    goto, done
  endif

  l0_dir = filepath('level0', root=date_dir)
  if (~file_test(l0_dir, /directory)) then begin
    mg_log, '%s does not exist', l0_dir, name='kcor/eod', /error
    goto, done
  endif

  l0_fits_files = file_search(filepath('*kcor.fts*', root=date_dir), $
                              count=n_l0_fits_files)
  if (n_l0_fits_files gt 0L) then begin
    mg_log, 'L0 FITS files exist in %s', date_dir, name='kcor/eod', /info
    mg_log, 'L1 processing incomplete', name='kcor/eod', /info
    goto, done
  endif

  t1_log_file = filepath(date + '.kcor.t1.log', root=l0_dir)
  if (file_test(t1_log_file, /regular)) then begin
    mg_log, 'T1 log in level0/, validation already done', name='kcor/eod', /info
    goto, done
  endif

  t1_log_file = filepath(date + '.kcor.t1.log', root=date_dir)
  if (file_test(t1_log_file, /regular)) then begin
    mg_log, 'copying T1 log to level0/', name='kcor/eod', /info
    file_copy, t1_log_file, l0_dir
  endif else begin
    mg_log, 'T1 log does not exist in %s', date_dir, name='kcor/eod', /info
    goto, done
  endif

  t2_log_file = filepath(date + '.kcor.t2.log', root=date_dir)
  if (file_test(t2_log_file, /regular)) then begin
    mg_log, 'copying T2 log to level0/', name='kcor/eod', /info
    file_copy, t2_log_file, l0_dir
  endif else begin
    mg_log, 'T2 log does not exist in %s', date_dir, name='kcor/eod', /warn
  endelse

  cd, l0_dir

  cmd = string(run.gunzip, format='(%"%s *fts.gz")')
  spawn, cmd, result, error_result, exit_status=status
  if (status ne 0L) then begin
    mg_log, 'problem unzipping FITS files with command: %s', cmd, $
            name='kcor/eod', /error
    mg_log, '%s', error_result, name='kcor/eod', /error
  endif

  n_missing = 0L
  n_wrongsize = 0L
  n_l0_files = 0L

  openr, lun, t1_log_file, /get_lun
  row = ''
  while (~eof(lun)) do begin
    n_l0_files += 1
    readf, lun, row
    fields = strsplit(row, /extract)
    t1_file = fields[0]
    t1_size = long(fields[1])
    if (file_test(t1_file, /regular)) then begin
      if (t1_size ne mg_filesize(t1_file)) then begin
        n_wrongsize += 1
        mg_log, '%s file size: %d != %d', t1_file, t1_size, mg_filesize(t1_file), $
                name='kcor/eod', /warn
      endif else begin
        n_missing += 1
        mg_log, '%s not found in level0/', t1_file, name='kcor/eod', /warn
      endelse
    endif else begin
    endelse
  endwhile

  mg_log, 't1.log # L0 files: %d', n_l0_files, name='kcor/eod', /info
  if (n_missing gt 0L) then begin
    mg_log, 't1.log # missing files: %d', n_missing, name='kcor/eod', /info
  endif
  if (n_wrongsize gt 0L) then begin
    mg_log, 't1.log # wrong size files: %d', n_wrongsize, name='kcor/eod', /info
  endif

  if (n_missing eq 0L && n_wrongsize eq 0L) then begin
    files = file_search(filepath('*kcor.fts*', root=l0_dir), count=n_files)

    kcorp, date, list=files, run=run
    kcor_plotcen, date, list=files, run=run
    dokcor_catalog, date, list=files, run=run

    kcor_send_mail, run.notifcation_email, $
                    string(date, format='(%"kcor_eod %s : ok")'), $
                    string(date, n_l0_files, $
                           format='(%"kcor L0 eod %s : ok # files: %d")'), $
                    logger_name='kcor/eod'

    kcor_archive, run=run

    ; put results in database
    if (run.update_database) then begin
      kcor_cal_insert, date, run=run
      kcor_dp_insert, date, run=run
      kcor_eng_insert, date, run=run
      kcor_hw_insert, date, run=run
      kcor_img_insert, date, run=run
      kcor_mission_insert, date, run=run
    endif

    ; produce calibration for tomorrow
    kcor_reduce_calibration, date, run=run
  endif else begin
    file_delete, filepath(date + '.kcor.t1.log', root=l0_dir), $
                 filepath(date + '.kcor.t2.log', root=l0_dir), $
                 /allow_nonexistent
    kcor_send_mail, run.notifcation_email, $
                    string(date, format='(%"kcor_eod %s : error")'), $
                    string(date, n_l0_files, $
                           format='(%"kcor L0 eod %s : error # files: %d")'), $
                    logger_name='kcor/eod'
    goto, done
  endelse

  ; remove zero length files in 'q' sub-directory
  cd, filepath('q', root=date_dir)

  list_files = ['brt', 'cal', 'cld', 'dev', 'dim', 'nsy', 'oka', 'sat'] + '.ls'
  list_files = [list_files, 'list_okf']
  for f = 0L, n_elements(list_files) - 1L do begin
    if (mg_filesize(list_files[f]) eq 0L) then begin
      file_delete, list_files[f], /allow_nonexistent
    endif
  endif

  cd, filepath('', root=date_dir)
  file_delete, 'list_okf', /allow_nonexistent

  done:
  mg_log, 'done with end-of-day processing', name='kcor/eod', /info
  obj_destroy, run
end
