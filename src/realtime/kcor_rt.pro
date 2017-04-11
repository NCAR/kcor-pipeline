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

  ; catch and log any crashes
  catch, error
  if (error ne 0L) then begin
    catch, /cancel
    mg_log, /last_error, name='kcor/rt', /critical
    goto, done
  endif

  run = kcor_run(date, config_filename=config_filename)

  mg_log, '------------------------------', name='kcor/rt', /info

  ; ignore math errors
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

  if (~file_test(croppedgif_dir, /directory)) then file_mkdir, croppedgif_dir
  if (~file_test(fullres_dir, /directory)) then file_mkdir, fullres_dir
  if (~file_test(archive_dir, /directory)) then file_mkdir, archive_dir

  cd, raw_dir

  available = kcor_state(/lock, run=run)

  if (available) then begin
    l0_fits_glob = '*.fts.gz'
    l0_fits_files = file_search(l0_fits_glob, count=n_l0_fits_files)
    if (n_l0_fits_files gt 0L) then begin
      mg_log, 'unzipping %d L0 FITS files', n_l0_fits_files, name='kcor/rt', /info
      gunzip_cmd = string(run.gunzip, l0_fits_glob, format='(%"%s %s")')
      spawn, gunzip_cmd, result, error_result, exit_status=status
      if (status ne 0L) then begin
        mg_log, 'problem unzipping files with command: %s', gunzip_cmd, $
                name='kcor/rt', /error
        mg_log, '%s', strjoin(error_result, ' '), name='kcor/rt', /error
      endif
    endif else begin
      mg_log, 'no L0 FITS files to unzip', name='kcor/rt', /info
    endelse

    l0_fits_files = file_search(filepath('*_*kcor.fts', root=raw_dir), $
                                count=n_l0_fits_files)
    if (n_l0_fits_files eq 0L) then begin
      mg_log, 'no L0 files to process in %s', raw_dir, name='kcor/rt', /info
      goto, done
    endif

    mg_log, 'checking %d L0 files', n_l0_fits_files, name='kcor/rt', /info
    ok_files = kcor_quality(date, l0_fits_files, /append, run=run)
    mg_log, '%d OK L0 files', n_elements(ok_files), name='kcor/rt', /info

    kcor_l1, date, ok_files, /append, run=run, mean_phase1=mean_phase1

    mg_log, 'moving processed files to l0_dir', name='kcor/rt', /info
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
    endif

    openw, okcgif_lun, 'okcgif.ls', /append, /get_lun
    openw, okfgif_lun, 'okfgif.ls', /append, /get_lun
    openw, okl1gz_lun, 'okl1gz.ls', /append, /get_lun

    for f = 0L, n_elements(ok_files) - 1L do begin
      base = file_basename(ok_files[f], '.fts')
      printf, okcgif_lun, base + '_cropped.gif'
      printf, okfgif_lun, base + '.gif'
      printf, okl1gz_lun, base + '_l1.fts.gz'

      file_copy, base + '_cropped.gif', croppedgif_dir, /overwrite
      file_copy, base + '.gif', fullres_dir, /overwrite
      file_copy, base + '_l1.fts.gz', archive_dir, /overwrite
    endfor

    free_lun, okcgif_lun
    free_lun, okfgif_lun
    free_lun, okl1gz_lun

    ; find the NRGF files now, will move them after updating database
    rg_dir = filepath('', subdir=date_parts, root=run.nrgf_basedir)
    if (~file_test(rg_dir, /directory)) then file_mkdir, rg_dir

    rg_files = file_search('*nrgf.fts*', count=n_rg_files)
    rg_gifs = file_search('*nrgf.gif', count=n_rg_gifs)
    cropped_rg_gifs = file_search('*nrgf_cropped.gif', count=n_cropped_rg_gifs)

    if (run.update_remote_server && ~keyword_set(reprocess)) then begin
      if (n_rg_gifs gt 0L) then begin
        mg_log, 'transferring %d NRGF GIFs to remote server', n_rg_gifs, $
                name='kcor/rt', /debug
        spawn_cmd = string(run.nrgf_remote_server, run.nrgf_remote_dir, $
                           format='(%"scp -B -r -p *rg*.gif %s:%s")')
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

      ; update databases that use L1 files
      if (n_l1_fits_files gt 0L) then begin
        obsday_index = mlso_obsday_insert(date, $
                                          run=run, $
                                          database=db, $
                                          status=db_status, $
                                          log_name='kcor/rt')
        if (db_status eq 0L) then begin
          kcor_img_insert, date, l1_fits_files, $
                           run=run, $
                           database=db, $
                           obsday_index=obsday_index
          kcor_eng_insert, date, l1_fits_files, $
                           mean_phase1=mean_phase1, $
                           run=run, $
                           database=db, $
                           obsday_index=obsday_index
          mlso_sgs_insert, date, l1_fits_files, $
                           run=run, $
                           database=db, $
                           obsday_index=obsday_index
        endif else begin
          mg_log, 'skipping database inserts', name='kcor/rt', /warn
        endelse
        obj_destroy, db
      endif else begin
        mg_log, 'no L1 files for img, eng, or sgs tables', name='kcor/rt', /info
      endelse
    endif else begin
      mg_log, 'skipping updating database', name='kcor/rt', /info
    endelse

    ; now move NRGF files
    if (n_rg_gifs gt 0L) then file_move, rg_gifs, rg_dir, /overwrite
    if (n_cropped_rg_gifs gt 0L) then begin
      file_move, cropped_rg_gifs, croppedgif_dir, /overwrite
    endif
  endif else begin
    mg_log, 'raw directory locked, quitting', name='kcor/rt', /info
  endelse

  done:
  !null = kcor_state(/unlock, run=run)
  mg_log, 'done with realtime processing run', name='kcor/rt', /info

  rt_time = toc(rt_clock)
  mg_log, 'total realtime processing time: %0.1f sec', rt_time, name='kcor/rt', /info

  obj_destroy, run
end
