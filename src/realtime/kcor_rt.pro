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
    kcor_crash_notification, /realtime, run=run
    goto, done
  endif

  valid_date = kcor_valid_date(date, msg=msg)
  if (~valid_date) then message, msg

  run = kcor_run(date, config_filename=config_filename, mode='realtime')
  if (~obj_valid(run)) then message, 'problem creating run object'

  mg_log, '------------------------------', name='kcor/rt', /info

  ; do not print math errors, we check for them explicitly
  !except = 0

  version = kcor_find_code_version(revision=revision, branch=branch)
  full_hostname = mg_hostname()
  hostname_tokens = strsplit(full_hostname, '.', /extract)
  hostname = hostname_tokens[0]
  mg_log, 'kcor-pipeline %s (%s) [%s] on %s', $
          version, revision, branch, hostname, $
          name='kcor/rt', /info

  mg_log, 'IDL %s (%s %s)', !version.release, !version.os, !version.arch, $
          name='kcor/rt', /debug
  mg_log, 'starting realtime processing for %s', date, name='kcor/rt', /info

  raw_dir = filepath('', subdir=date, root=run->config('processing/raw_basedir'))
  if (~file_test(raw_dir, /directory)) then file_mkdir, raw_dir

  available = kcor_state(/lock, run=run)

  if (available) then begin
    l0_dir = filepath('level0', root=raw_dir)
    l1_dir = filepath('level1', root=raw_dir)
    l2_dir = filepath('level2', root=raw_dir)
    q_dir = filepath('q', root=raw_dir)

    if (~file_test(l0_dir, /directory)) then file_mkdir, l0_dir
    if (~file_test(l1_dir, /directory)) then file_mkdir, l1_dir
    if (~file_test(l2_dir, /directory)) then file_mkdir, l2_dir
    if (~file_test(q_dir, /directory)) then file_mkdir, q_dir

    date_parts = kcor_decompose_date(date)

    croppedgif_dir = filepath('', subdir=date_parts, $
                              root=run->config('results/croppedgif_basedir'))
    fullres_dir = filepath('', subdir=date_parts, $
                           root=run->config('results/fullres_basedir'))
    archive_dir = filepath('', subdir=date_parts, $
                           root=run->config('results/archive_basedir'))

    if (run->config('realtime/distribute')) then begin
      if (~file_test(croppedgif_dir, /directory)) then file_mkdir, croppedgif_dir
      if (~file_test(fullres_dir, /directory)) then file_mkdir, fullres_dir
      if (~file_test(archive_dir, /directory)) then file_mkdir, archive_dir
    endif

    cd, raw_dir

    if (run->config('realtime/reprocess') $
          || run->config('realtime/update_processing')) then begin
      kcor_reprocess, date, run=run, error=error
      if (error ne 0L) then begin
        mg_log, 'error in reprocessing setup, exiting', name='kcor/rt', /error
        mg_log, 'see reprocessing log for details', name='kcor/rt', /error
        goto, done
      endif
    endif else begin
      mg_log, 'skipping updating/reprocessing', name='kcor/rt', /debug
    endelse

    ; need to run on machine at MLSO since data are not zipped there, should not
    ; run or be needed in Boulder
    unzipped_glob = '*_kcor.fts'
    unzipped_files = file_search(unzipped_glob, count=n_unzipped_files)
    if (n_unzipped_files gt 0L) then begin
      mg_log, 'zipping %d FITS files...', n_unzipped_files, name='kcor/rt', /info
      gzip_cmd = string(run->config('externals/gzip'), unzipped_glob, $
                        format='(%"%s %s")')
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

    l0_spec = run->config('validation/l0_specification')
    if (n_elements(l0_spec) eq 0L || ~file_test(l0_spec, /regular)) then begin
      mg_log, 'no spec to validate L0 files against', name='kcor/rt', /info
    endif else begin
      mg_log, 'validating %d L0 files', n_l0_fits_files, name='kcor/rt', /info
      kcor_validate, l0_fits_files, l0_spec, 'L0', logger_name='kcor/rt', run=run
    endelse

    mg_log, 'checking %d L0 files', n_l0_fits_files, name='kcor/rt', /info
    ok_files = kcor_quality(date, l0_fits_files, /append, $
                            brt_files=brt_files, $
                            cal_files=cal_files, $
                            cld_files=cld_files, $
                            dev_files=dev_files, $
                            dim_files=dim_files, $
                            nsy_files=nsy_files, $
                            sat_files=sat_files, $
                            run=run)
    mg_log, '%d OK L0 files', n_elements(ok_files), name='kcor/rt', /info

    if (run->config('database/update')) then begin
      mg_log, 'updating database with raw files', name='kcor/rt', /info

      obsday_index = mlso_obsday_insert(date, $
                                        run=run, $
                                        database=db, $
                                        status=db_status, $
                                        log_name='kcor/rt')
      if (db_status eq 0L) then begin
        kcor_sw_insert, date, $
                        run=run, database=database, $
                        sw_index=sw_index, $
                        log_name='kcor/rt'

        kcor_raw_insert, date, ok_files, 'oka', $
                         run=run, database=db, obsday_index=obsday_index, $
                         log_name='kcor/rt'
        kcor_raw_insert, date, brt_files, 'brt', $
                         run=run, database=db, obsday_index=obsday_index, $
                         log_name='kcor/rt'
        kcor_raw_insert, date, cal_files, 'cal', $
                         run=run, database=db, obsday_index=obsday_index, $
                         log_name='kcor/rt'
        kcor_raw_insert, date, cld_files, 'cld', $
                         run=run, database=db, obsday_index=obsday_index, $
                         log_name='kcor/rt'
        kcor_raw_insert, date, dev_files, 'dev', $
                         run=run, database=db, obsday_index=obsday_index, $
                         log_name='kcor/rt'
        kcor_raw_insert, date, dim_files, 'dim', $
                         run=run, database=db, obsday_index=obsday_index, $
                         log_name='kcor/rt'
        kcor_raw_insert, date, nsy_files, 'nsy', $
                         run=run, database=db, obsday_index=obsday_index, $
                         log_name='kcor/rt'
        kcor_raw_insert, date, sat_files, 'sat', $
                         run=run, database=db, obsday_index=obsday_index, $
                         log_name='kcor/rt'
      endif else begin
        mg_log, 'skipping database because unable to connect', name='kcor/rt', /warn
      endelse
    endif

    kcor_process_files, ok_files, run=run, mean_phase1=mean_phase1, $
                        log_name='kcor/rt', error=error

    mg_log, 'moving processed files to level0 dir', name='kcor/rt', /info
    file_move, l0_fits_files, l0_dir, /overwrite

    if (n_elements(error) eq 0L) then begin
      mg_log, 'no L0 files to process, quitting', name='kcor/rt', /info
      goto, done
    endif

    processed_indices = where(error eq 0L, n_processed_files, /null)
    failed_indices = where(error ne 0L, n_failed_files, /null)
    mg_log, '%d processed files', n_processed_files, name='kcor/rt', /debug
    mg_log, '%d failed files', n_failed_files, name='kcor/rt', /debug

    if (file_test(l1_dir, /directory)) then begin
      cd, l1_dir

      l1_fits_glob = '*kcor_l1.fts'
      l1_fits_files = file_search(l1_fits_glob, count=n_l1_fits_files)
      if (n_l1_fits_files gt 0L) then begin
        mg_log, 'zipping %d L1 FITS files', n_l1_fits_files, name='kcor/rt', /info
        gzip_cmd = string(run->config('externals/gzip'), l1_fits_glob, format='(%"%s %s")')
        spawn, gzip_cmd, result, error_result, exit_status=status
        if (status ne 0L) then begin
          mg_log, 'problem zipping files with command: %s', gzip_cmd, $
                  name='kcor/rt', /error
          mg_log, '%s', strjoin(error_result, ' '), name='kcor/rt', /error
        endif
      endif else begin
        mg_log, 'no L1 FITS files to zip', name='kcor/rt', /info
      endelse
    endif else n_l1_fits_files = 0L

    if (file_test(l2_dir, /directory)) then begin
      cd, l2_dir

      l2_fits_glob = '*kcor_l2*.fts'
      l2_fits_files = file_search(l2_fits_glob, count=n_l2_fits_files)
      if (n_l2_fits_files gt 0L) then begin
        mg_log, 'zipping %d L2 FITS files', n_l2_fits_files, name='kcor/rt', /info
        gzip_cmd = string(run->config('externals/gzip'), l2_fits_glob, format='(%"%s %s")')
        spawn, gzip_cmd, result, error_result, exit_status=status
        if (status ne 0L) then begin
          mg_log, 'problem zipping files with command: %s', gzip_cmd, $
                  name='kcor/rt', /error
          mg_log, '%s', strjoin(error_result, ' '), name='kcor/rt', /error
        endif
      endif else begin
        mg_log, 'no L2 FITS files to zip', name='kcor/rt', /info
      endelse
    endif else begin
      file_mkdir, l2_dir
      cd, l2_dir
      n_l2_fits_files = 0L
    endelse

    if (n_processed_files eq 0L) then begin
      mg_log, 'no files to archive', name='kcor/rt', /info
    endif else begin
      if (run->config('realtime/distribute')) then begin
        mg_log, 'distributing L2 products of %d raw files', $
                n_processed_files, $
                name='kcor/rt', /info
      endif else begin
        mg_log, 'skipping distribution', name='kcor/rt', /info
      endelse
    endelse

    failed_catalog_file = 'failed.ls'
    n_previously_failed_files = file_test(failed_catalog_file) $
                                  ? file_lines(failed_catalog_file) $
                                  : 0L

    openw, okcgif_lun, 'okcgif.ls', /append, /get_lun
    openw, okfgif_lun, 'okfgif.ls', /append, /get_lun
    openw, okl1gz_lun, 'okl1gz.ls', /append, /get_lun
    openw, ok_rg_lun, 'oknrgf.ls', /append, /get_lun
    openw, failed_lun, failed_catalog_file, /append, /get_lun

    nrgf_basenames = list()

    for f = 0L, n_failed_files - 1L do begin
      printf, failed_lun, file_basename(ok_files[failed_indices[f]])
    endfor

    for f = 0L, n_processed_files - 1L do begin
      base = file_basename(ok_files[processed_indices[f]], '.fts.gz')

      cropped_gif_filename = base + '_l2_cropped.gif'
      printf, okcgif_lun, cropped_gif_filename

      gif_filename = base + '_l2.gif'
      printf, okfgif_lun, gif_filename

      l2_filename = base + '_l2.fts.gz'
      printf, okl1gz_lun, l2_filename

      nrgf_filename = base + '_l2_nrgf.fts.gz'
      if (file_test(nrgf_filename)) then begin
        printf, ok_rg_lun, nrgf_filename
        nrgf_basenames->add, base
      endif

      if (run->config('realtime/distribute')) then begin
        if (file_test(nrgf_filename)) then begin
          file_copy, nrgf_filename, archive_dir, /overwrite
        endif

        if (file_test(cropped_gif_filename)) then begin
          file_copy, cropped_gif_filename, croppedgif_dir, /overwrite
        endif
        if (file_test(gif_filename)) then begin
          file_copy, gif_filename, fullres_dir, /overwrite
        endif
        if (file_test(l2_filename)) then begin
          file_copy, l2_filename, archive_dir, /overwrite
        endif
      endif
    endfor

    free_lun, okcgif_lun
    free_lun, okfgif_lun
    free_lun, okl1gz_lun
    free_lun, ok_rg_lun
    free_lun, failed_lun

    mg_log, '%d failed files from previous realtime run', $
            n_previously_failed_files, $
            name='kcor/rt', /debug

    if (n_failed_files gt n_previously_failed_files $
          && n_previously_failed_files eq 0L) then begin
      n_new_failures = n_failed_files - n_previously_failed_files
      msg = [string(mg_src_root(/filename), mg_loginname(), mg_hostname(), $
                    format='(%"Sent from %s (%s@%s)")')]
      kcor_send_mail, run->config('notifications/email'), $
                      string(n_new_failures, run.date, $
                             format='(%"KCor failures (%d) during L1/L2 processing for %s")'), $
                      msg, $
                      logger_name='kcor/rt'
    endif

    ; find the NRGF files now, will copy them after updating database
    if (run->config('realtime/distribute')) then begin
      nrgf_dir = filepath('', subdir=date_parts, root=run->config('results/nrgf_basedir'))
      if (~file_test(nrgf_dir, /directory)) then file_mkdir, nrgf_dir
    endif

    n_nrgf_gifs = nrgf_basenames->count()
    if (n_nrgf_gifs gt 0L) then begin
      nrgf_gif_basenames = nrgf_basenames->toArray()
      nrgf_gifs = nrgf_gif_basenames + '_l2_nrgf.gif'
      cropped_nrgf_gifs = nrgf_gif_basenames + '_l2_nrgf_cropped.gif'
    endif

    obj_destroy, nrgf_basenames

    if (keyword_set(reprocess)) then begin
      mg_log, 'skipping updating NRGF gallery', name='kcor/rt', /info
    endif else begin
      if (n_nrgf_gifs eq 0L) then begin
        mg_log, 'no NRGF images to transfer to NRGF gallery', name='kcor/rt', /info
      endif else begin
        method = run->config('realtime/update_nrgf_gallery_method')
        case strlowcase(method) of
          'none': mg_log, 'no update NRGF gallery method', name='kcor/rt', /info
          'cp': begin
              mg_log, 'copying %d NRGF GIFs to local gallery', n_nrgf_gifs, $
                      name='kcor/rt', /info
              if (~file_test(run->config('results/nrgf_gallery_dir'), /directory)) then begin
                mg_log, 'creating %s', run->config('results/nrgf_gallery_dir'), $
                        name='kcor/rt', /info
                file_mkdir, run->config('results/nrgf_gallery_dir')
              endif
              file_copy, '*nrgf.gif', run->config('results/nrgf_gallery_dir'), $
                         /overwrite
            end
          'scp': begin
              mg_log, 'transferring %d NRGF GIFs to remote gallery', n_nrgf_gifs, $
                      name='kcor/rt', /info
              gallery_server = run->config('results/nrgf_gallery_server')
              gallery_dir    = run->config('results/nrgf_gallery_dir')
              if (n_elements(gallery_server) eq 0L $
                    || n_elements(gallery_dir) eq 0L) then begin
                mg_log, 'NRGF gallery server/dir not specified', $
                        name='kcor/rt', /warn 
              endif else begin
                key = run->config('results/ssh_key')
                ssh_key_str = n_elements(key) eq 0L $
                                ? '' $
                                : string(key, format='(%"-i %s")')
                spawn_cmd = string(ssh_key_str, $
                                   gallery_server, gallery_dir, $
                                   format='(%"scp %s -B -r -p *nrgf.gif %s:%s")')
                spawn, spawn_cmd, result, error_result, exit_status=status
                if (status ne 0L) then begin
                  mg_log, 'problem scp-ing NRGF files with command: %s', spawn_cmd, $
                          name='kcor/rt', /error
                  mg_log, '%s', strjoin(error_result, ' '), name='kcor/rt', /error
                endif
              endelse
            end
          else: begin
            mg_log, 'unknown update NRGF gallery method: %s', method, $
                    name='kcor/rt', /info
          end
        endcase
      endelse
    endelse

    if (run->config('database/update')) then begin
      mg_log, 'updating database', name='kcor/rt', /info

      obsday_index = mlso_obsday_insert(date, $
                                        run=run, $
                                        database=db, $
                                        status=db_status, $
                                        log_name='kcor/rt')
      if (db_status eq 0L) then begin
        ; update databases that use L2 files
        if (n_l2_fits_files gt 0L) then begin
          kcor_img_insert, date, l2_fits_files, $
                           /level2, $
                           hw_ids=hw_ids, $
                           run=run, $
                           database=db, $
                           obsday_index=obsday_index, log_name='kcor/rt'
          kcor_eng_insert, date, l2_fits_files, $
                           mean_phase1=mean_phase1, $
                           sw_index=sw_index, $
                           hw_ids=hw_ids, $
                           run=run, $
                           database=db, $
                           obsday_index=obsday_index
        endif else begin
          mg_log, 'no L2 files for img or eng tables', name='kcor/rt', /info
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
    if (n_nrgf_gifs gt 0L && run->config('realtime/distribute')) then begin
      file_copy, nrgf_gifs, nrgf_dir, /overwrite
      file_copy, cropped_nrgf_gifs, croppedgif_dir, /overwrite
    endif
  endif else begin
    mg_log, 'raw directory locked, quitting', name='kcor/rt', /info
  endelse

  done:
  mg_log, /check_math, name='kcor/rt', /debug

  if (n_elements(available) gt 0L && available) then begin
    !null = kcor_state(/unlock, run=run)
  endif

  rt_time = toc(rt_clock)
  mg_log, 'done, realtime processing time: %s', $
          kcor_sec2str(rt_time), $
          name='kcor/rt', /info

  obj_destroy, run
end
