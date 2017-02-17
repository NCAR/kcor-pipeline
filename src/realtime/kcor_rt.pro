; docformat = 'rst'


pro kcor_rt, date, config_filename=config_filename
  compile_opt strictarr

  ; catch and log any crashes
  catch, error
  if (error ne 0L) then begin
    catch, /cancel
    mg_log, /last_error, name='kcor/eod', /critical
    goto, done
  endif

  run = kcor_run(date, config_filename=config_filename)

  version = kcor_find_code_version(revision=revision, branch=branch)
  mg_log, 'kcor-pipeline %s (%s) [%s]', version, revision, branch, $
          name='kcor/rt', /info
  mg_log, 'IDL %s (%s %s)', !version.release, !version.os, !version.arch, $
          name='kcor/rt', /info
  mg_log, 'starting realtime processing for %s', date, name='kcor/rt', /info


  raw_dir = filepath('', subdir=date, root=run.raw_basedir)
  l0_dir = filepath('l0', root=raw_dir)
  l1_dir = filepath('l1', root=raw_dir)
  q_dir = filepath('q', root=raw_dir)

  if (~file_test(raw_dir, /directory)) then file_mkdir, raw_dir
  if (~file_test(l0_dir, /directory)) then file_mkdir, l0_dir
  if (~file_test(l1_dir, /directory)) then file_mkdir, l1_dir
  if (~file_test(q_dir, /directory)) then file_mkdir, q_dir

  date_parts = kcor_decompose_date(date)

  croppedgif_dir = filepath('', subdir=date_parts, root=croppedgif_basedir)
  fullres_dir = filepath('', subdir=date_parts, root=fullres_basedir)
  archive_dir = filepath('', subdir=date_parts, root=archive_basedir)

  if (~file_test(croppedgif_dir, /directory)) then file_mkdir, croppedgif_dir
  if (~file_test(fullres_dir, /directory)) then file_mkdir, fullres_dir
  if (~file_test(archive_dir, /directory)) then file_mkdir, archive_dir

  cd, raw_dir

  available = kcor_state(/lock)
  if (available) then begin
    mg_log, 'unzipping L0 files', name='kcor/rt', /info
    gunzip_cmd = string(run.gunzip, format='(%"%s *.fts.gz")')
    spawn, gunzip_cmd, result, error_result, exit_status=status
    if (status ne 0L) then begin
      mg_log, 'problem unzipping files with command: %s', gunzip_cmd, $
              name='kcor/rt', /error
      mg_log, '%s', error_result, name='kcor/rt', /error
    endif

    l0_fits_files = file_search(filepath('*_*kcor.fts', root=raw_dir), $
                                count=n_l0_fits_files)
    if (n_l0_fits_files eq 0L) then begin
      mg_log, 'no L0 files to process in %s', raw_dir, name='kcor/rt', /info
      goto, done
    endif

    mg_log, 'processing %d L0 files', n_l0_fits_files, name='kcor/rt', /info

    ; TODO: change interface here
    kcor_qsc, date, l0_fits_files, ok_files=ok_files, /append

    ; TODO: change interface here
    kcorl1, date, ok_files, /append

    mg_log, 'moving processed files to l0_dir', name='kcor/rt', /info
    file_move, l0_fits_files, l0_dir

    cd, l1_dir

    mg_log, 'zipping L1 files', name='kcor/rt', /info
    gzip_cmd = string(run.gzip, format='(%"%s *l1*fts")')
    spawn, gzip_cmd, result, error_result, exit_status=status
    if (status ne 0L) then begin
      mg_log, 'problem zipping files with command: %s', gzip_cmd, $
              name='kcor/rt', /error
      mg_log, '%s', error_result, name='kcor/rt', /error
    endif

    if (n_elements(ok_files) eq 0L) then begin
      mg_log, 'no files to archive', name='kcor/rt', info
      goto, done
    endif

    openu, okcgif_lun, 'okcgif.ls', /get_lun
    openu, okfgif_lun, 'okfgif.ls', /get_lun
    openu, okl1gz_lun, 'okl1gz.ls', /get_lun

    for f = 0L, n_elements(ok_files) - 1L do begin
      base = file_basename(ok_files[f], '.fts')
      printf, okcgif_lun, base + '_cropped.gif'
      printf, okfgif_lun, base + '.gif'
      printf, okl1gz_lun, base + '_l1.fts.gz'

      file_copy, base + '_cropped.gif', croppedgif_dir
      file_copy, base + '.gif', fullres_dir
      file_copy, base + '_l1.fts.gz', archive_dir
    endfor

    free_lun, okcgif_lun
    free_lun, okfgif_lun
    free_lun, okl1gz_lun

    rg_dir = filepath('', subdir=date_parts, root=rg_basedir)
    if (~file_test(rg_dir, /directory)) then file_mkdir, rg_dir

    spawn_cmd = string(run.rg_remove_server, run.rg_remote_dir, $
                       format='(%"scp -B -r -p *rg*.gif %s:%s")')
    spawn, spawn_cmd, result, error_result, exit_status=status
    if (status ne 0L) then begin
      mg_log, 'problem scp-ing RG files with command: %s', spawn_cmd, $
              name='kcor/rt', /error
      mg_log, '%s', error_result, name='kcor/rt', /error
    endif

    file_move, '*rg*.gif', rg_dir
    file_move, '*rg*.fts*', archive_dir
  endif else begin
    mg_log, 'raw directory locked, quitting', name='kcor/rt', /info
  endelse

  done:
  !null = kcor_state(/unlock)
  mg_log, 'done with realtime processing run', name='kcor/rt', /info
  obj_destroy, run
end
