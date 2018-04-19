; docformat = 'rst'

;+
; This is the top-level realtime pipeline routine.
;
; :Params:
;   date : in, required, type=string
;     date to process in the form "YYYYMMDD"
;
; :Keywords:
;   config_filename : in, required, type=string
;     configuration file specifying the parameters of the run
;   reprocess : in, optional, type=boolean
;     set to indicate a reprocessing; level 0 files are not distributed in a
;     reprocessing
;-
pro kcor_rt, date, config_filename=config_filename, reprocess=reprocess
  compile_opt strictarr

  rt_clock = tic('rt')

  run = kcor_run(date, config_filename=config_filename, mode='realtime')
  if (~obj_valid(run)) then message, 'problem creating run object'

  ; catch and log any crashes
  catch, error
  if (error ne 0L) then begin
    catch, /cancel
    mg_log, /last_error, name='kcor/rt', /critical
    kcor_crash_notification, /realtime, run=run
    goto, done
  endif

  mg_log, '------------------------------', name='kcor/rt', /info

  ; do not print math errors, we check for them explicitly
  !except = 0

  version = kcor_find_code_version(revision=revision, branch=branch)
  mg_log, 'kcor-pipeline %s (%s) [%s]', version, revision, branch, $
          name='kcor/rt', /info
  mg_log, 'IDL %s (%s %s)', !version.release, !version.os, !version.arch, $
          name='kcor/rt', /info
  mg_log, 'starting realtime processing for %s', date, name='kcor/rt', /info

  raw_dir = filepath('', subdir=date, root=run.raw_basedir)
  l0_dir = filepath('level0', root=raw_dir)
  l1_dir = filepath('level1', root=raw_dir)
  q_dir = filepath('q', root=raw_dir)

  if (~file_test(raw_dir, /directory)) then file_mkdir, raw_dir
  if (~file_test(l0_dir, /directory)) then file_mkdir, l0_dir
  if (~file_test(l1_dir, /directory)) then file_mkdir, l1_dir
  if (~file_test(q_dir, /directory)) then file_mkdir, q_dir

  date_parts = kcor_decompose_date(date)

  croppedgif_dir = filepath('', subdir=date_parts, root=run.croppedgif_basedir)
  fullres_dir = filepath('', subdir=date_parts, root=run.fullres_basedir)
  archive_dir = filepath('', subdir=date_parts, root=run.archive_basedir)

  if (run.distribute) then begin
    if (~file_test(croppedgif_dir, /directory)) then file_mkdir, croppedgif_dir
    if (~file_test(fullres_dir, /directory)) then file_mkdir, fullres_dir
    if (~file_test(archive_dir, /directory)) then file_mkdir, archive_dir
  endif

  cd, raw_dir

  available = kcor_state(/lock, run=run)

  if (available) then begin
    if (run.reprocess || run.update_processing) then begin
      kcor_reprocess, date, run=run, error=error
      if (error ne 0L) then begin
        mg_log, 'error in reprocessing setup, exiting', name='kcor/rt', /error
        goto, done
      endif
    endif else begin
      mg_log, 'skipping updating/reprocessing', name='kcor/rt', /info
    endelse

    ; need to run on machine at MLSO since data are not zipped there, should not
    ; run or be needed in Boulder
    unzipped_glob = '*_kcor.fts'
    unzipped_files = file_search(unzipped_glob, count=n_unzipped_files)
    if (n_unzipped_files gt 0L) then begin
      mg_log, 'zipping %d FITS files...', n_unzipped_files, name='kcor/rt', /info
      gzip_cmd = string(run.gzip, unzipped_glob, format='(%"%s %s")')
      spawn, gzip_cmd, result, error_result, exit_status=status
      if (status ne 0L) then begin
        mg_log, 'problem zipping files with command: %s', gzip_cmd, $
                name='kcor/rt', /error
        mg_log, '%s', strjoin(error_result, ' '), name='kcor/rt', /error
      endif
    endif

    l0_fits_files = file_search('*_kcor.fts.gz', count=n_l0_fits_files)
    if (n_l0_fits_files eq 0L) then begin
      mg_log, 'no L0 files to process in raw dir', name='kcor/rt', /info
      goto, done
    endif

    mg_log, 'checking %d L0 files', n_l0_fits_files, name='kcor/rt', /info
    ok_files = kcor_quality(date, l0_fits_files, /append, run=run)
    mg_log, '%d OK L0 files', n_elements(ok_files), name='kcor/rt', /info

    kcor_l1, date, ok_files, /append, run=run, mean_phase1=mean_phase1, error=error
    if (error ne 0L) then begin
      mg_log, 'L1 processing failed, quitting', name='kcor/rt', /error
      goto, done
    endif

    mg_log, 'moving processed files to level0 dir', name='kcor/rt', /info
    file_move, l0_fits_files, l0_dir, /overwrite

    cd, l1_dir

    l1_fits_glob = '*l1*fts'
    l1_fits_files = file_search(l1_fits_glob, count=n_l1_fits_files)
    if (n_l1_fits_files gt 0L) then begin
      mg_log, 'zipping %d L1 FITS files', n_l1_fits_files, name='kcor/rt', /info
      gzip_cmd = string(run.gzip, l1_fits_glob, format='(%"%s %s")')
      spawn, gzip_cmd, result, error_result, exit_status=status
      if (status ne 0L) then begin
        mg_log, 'problem zipping files with command: %s', gzip_cmd, $
                name='kcor/rt', /error
        mg_log, '%s', strjoin(error_result, ' '), name='kcor/rt', /error
      endif
    endif else begin
      mg_log, 'no L1 FITS files to zip', name='kcor/rt', /info
    endelse

    if (n_elements(ok_files) eq 0L) then begin
      mg_log, 'no files to archive', name='kcor/rt', /info
      goto, done
    endif else begin
      if (run.distribute) then begin
        mg_log, 'distributing L1 products of %d raw files', $
                n_elements(ok_files), $
                name='kcor/rt', /info
      endif else begin
        mg_log, 'skipping distribution', name='kcor/rt', /info
      endelse
    endelse

    openw, okcgif_lun, 'okcgif.ls', /append, /get_lun
    openw, okfgif_lun, 'okfgif.ls', /append, /get_lun
    openw, okl1gz_lun, 'okl1gz.ls', /append, /get_lun
    openw, ok_rg_lun, 'oknrgf.ls', /append, /get_lun

    nrgf_basenames = list()

    for f = 0L, n_elements(ok_files) - 1L do begin
      base = file_basename(ok_files[f], '.fts.gz')

      cropped_gif_filename = base + '_l1_cropped.gif'
      printf, okcgif_lun, cropped_gif_filename

      gif_filename = base + '_l1.gif'
      printf, okfgif_lun, gif_filename

      l1_filename = base + '_l1.fts.gz'
      printf, okl1gz_lun, l1_filename

      nrgf_filename = base + '_l1_nrgf.fts.gz'
      if (file_test(nrgf_filename)) then begin
        printf, ok_rg_lun, nrgf_filename
        nrgf_basenames->add, base
      endif

      if (run.distribute) then begin
        if (file_test(nrgf_filename)) then begin
          file_copy, nrgf_filename, archive_dir, /overwrite
        endif

        if (file_test(cropped_gif_filename)) then begin
          file_copy, cropped_gif_filename, croppedgif_dir, /overwrite
        endif
        if (file_test(gif_filename)) then begin
          file_copy, gif_filename, fullres_dir, /overwrite
        endif
        if (file_test(l1_filename)) then begin
          file_copy, l1_filename, archive_dir, /overwrite
        endif
      endif
    endfor

    free_lun, okcgif_lun
    free_lun, okfgif_lun
    free_lun, okl1gz_lun
    free_lun, ok_rg_lun

    ; find the NRGF files now, will copy them after updating database
    if (run.distribute) then begin
      nrgf_dir = filepath('', subdir=date_parts, root=run.nrgf_basedir)
      if (~file_test(nrgf_dir, /directory)) then file_mkdir, nrgf_dir
    endif

    n_nrgf_gifs = nrgf_basenames->count()
    if (n_nrgf_gifs gt 0L) then begin
      nrgf_gif_basenames = nrgf_basenames->toArray()
      nrgf_gifs = nrgf_gif_basenames + '_l1_nrgf.gif'
      cropped_nrgf_gifs = nrgf_gif_basenames + '_l1_nrgf_cropped.gif'
    endif

    obj_destroy, nrgf_basenames

    if (run.update_remote_server && ~keyword_set(reprocess)) then begin
      if (n_nrgf_gifs gt 0L) then begin
        mg_log, 'transferring %d NRGF GIFs to remote server', n_nrgf_gifs, $
                name='kcor/rt', /info
        ssh_key_str = run.ssh_key eq '' ? '' : string(run.ssh_key, format='(%"-i %s")')
        spawn_cmd = string(ssh_key_str, run.nrgf_remote_server, run.nrgf_remote_dir, $
                           format='(%"scp %s -B -r -p *nrgf.gif %s:%s")')
        spawn, spawn_cmd, result, error_result, exit_status=status
        if (status ne 0L) then begin
          mg_log, 'problem scp-ing NRGF files with command: %s', spawn_cmd, $
                  name='kcor/rt', /error
          mg_log, '%s', strjoin(error_result, ' '), name='kcor/rt', /error
        endif
      endif else begin
        mg_log, 'no NRGF images to transfer to remote server', name='kcor/rt', /info
      endelse
    endif else begin
      mg_log, 'skipping updating remote server with NRGF images', name='kcor/rt', /info
    endelse

    if (run.update_database) then begin
      mg_log, 'updating database', name='kcor/rt', /info

      obsday_index = mlso_obsday_insert(date, $
                                        run=run, $
                                        database=db, $
                                        status=db_status, $
                                        log_name='kcor/rt')
      if (db_status eq 0L) then begin
        ; update databases that use L1 files
        if (n_l1_fits_files gt 0L) then begin
          kcor_img_insert, date, l1_fits_files, $
                           sw_ids=sw_ids, $
                           hw_ids=hw_ids, $
                           run=run, $
                           database=db, $
                           obsday_index=obsday_index, log_name='kcor/rt'
          kcor_eng_insert, date, l1_fits_files, $
                           mean_phase1=mean_phase1, $
                           sw_ids=sw_ids, $
                           hw_ids=hw_ids, $
                           run=run, $
                           database=db, $
                           obsday_index=obsday_index
        endif else begin
          mg_log, 'no L1 files for img or eng tables', name='kcor/rt', /info
        endelse

        if (n_l0_fits_files gt 0L) then begin
          ; should use ALL (cal, eng, sci, and bad ones) raw files
          mlso_sgs_insert, date, file_basename(l0_fits_files), $
                           run=run, $
                           database=db, $
                           obsday_index=obsday_index
        endif else begin
          mg_log, 'no L0 files for sgs table', name='kcor/rt', /info
        endelse

        obj_destroy, db
      endif else begin
          mg_log, 'skipping database because unable to connect', name='kcor/rt', /warn
      endelse
    endif else begin
      mg_log, 'skipping updating database', name='kcor/rt', /info
    endelse

    ; now move NRGF files
    if (n_nrgf_gifs gt 0L && run.distribute) then begin
      file_copy, nrgf_gifs, nrgf_dir, /overwrite
      file_copy, cropped_nrgf_gifs, croppedgif_dir, /overwrite
    endif
  endif else begin
    mg_log, 'raw directory locked, quitting', name='kcor/rt', /info
  endelse

  done:
  mg_log, /check_math, name='kcor/rt', /warn

  !null = kcor_state(/unlock, run=run)
  mg_log, 'done with realtime processing run', name='kcor/rt', /info

  rt_time = toc(rt_clock)
  mg_log, 'total realtime processing time: %0.1f sec', rt_time, name='kcor/rt', /info

  obj_destroy, run
end
