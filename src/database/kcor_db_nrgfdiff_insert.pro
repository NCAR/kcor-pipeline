; docformat = 'rst'

;+
; Insert NRGF+diff GIFs and mp4 into the kcor_img database table.
;
; :Keywords:
;   database : in, required, type=object
;     database connection object
;   run : in, required, type=object
;     KCor run object
;   obsday_index : in, required, type=integer
;     day ID
;-
pro kcor_db_nrgfdiff_insert, database=db, run=run, obsday_index=obsday_index
  compile_opt strictarr

  mg_log, 'inserting NRGF+diff GIFs and mp4...', name=run.logger_name, /info

  ; find NRGF+diff GIFs and NRGF+diff mp4

  l2_dir = filepath('', $
                    subdir=[run.date, 'level2'], $
                    root=run->config('processing/raw_basedir'))

  nrfgdiff_gif_basename_blob = '*_kcor_l2_nrgf_and_diff.gif'
  nrfgdiff_gif_filename_blob = filepath(nrfgdiff_gif_basename_blob, root=l2_dir)
  nrgfdiff_gif_filenames = file_search(nrfgdiff_gif_filename_blob, $
                                       count=n_nrgfdiff_gifs)

  if (n_nrgfdiff_gifs eq 0L) then begin
    mg_log, 'no NRGF+diff GIFs found', name=run.logger_name, /debug
    goto, done
  endif

  nrfgdiff_mp4_basename = string(run.date, format='%s_kcor_l2_nrgf_and_diff.mp4')
  nrfgdiff_mp4_filename = filepath(nrfgdiff_mp4_basename, root=l2_dir)
  nrfgdiff_mp4_found = file_test(nrfgdiff_mp4_filename, /regular)

  ; find product type ID for NRGF+diff images

  producttype_results = db->query('select * from mlso_producttype where producttype=''%s''', $
                                  'nrgf+diff', $
                                  status=status)
  if (status ne 0L) then begin
    mg_log, 'NRGF+diff product type not found', name=run.logger_name, /error
    goto, done
  endif
  producttype_id = producttype_results.producttype_id

  ; find file types for GIF and mp4 files

  gif_filetype_results = db->query('select * from mlso_filetype where filetype=''%s''', $
                                   'gif', $
                                   status=status)
  if (status ne 0L) then begin
    mg_log, 'GIF file type not found', name=run.logger_name, /error
    goto, done
  endif
  gif_filetype_id = gif_filetype_results.filetype_id

  mp4_filetype_results = db->query('select * from mlso_filetype where filetype=''%s''', $
                                   'mp4', $
                                   status=status)
  if (status ne 0L) then begin
    mg_log, 'mp4 file type not found', name=run.logger_name, /error
    goto, done
  endif
  mp4_filetype_id = mp4_filetype_results.filetype_id

  level_id = kcor_get_level_id('L2', database=db, count=level_found)
  if (~level_found) then mg_log, 'using unknown level', name=run.logger_name, /error

  quality = 75  ; level 2 files have default 75 quality

  date_obs = strjoin(kcor_decompose_date(run.date), '-') + ' 00:00:00'
  date_end = date_obs

  ; insert GIF files into database
  for f = 0L, n_nrgfdiff_gifs - 1L do begin
    nrgfdiff_gif_basename = file_basename(nrgfdiff_gif_filenames[f])

    fields = [{name: 'file_name', type: '''%s'''}, $
              {name: 'date_obs', type: '''%s'''}, $
              {name: 'date_end', type: '''%s'''}, $
              {name: 'obs_day', type: '%d'}, $
              {name: 'carrington_rotation', type: '%s'}, $
              {name: 'level', type: '%d'}, $
              {name: 'quality', type: '%d'}, $
              {name: 'producttype', type: '%d'}, $
              {name: 'filetype', type: '%d'}, $
              {name: 'numsum', type: '%s'}, $
              {name: 'exptime', type: '%s'}]
    sql_cmd = string(strjoin(fields.name, ', '), $
                     strjoin(fields.type, ', '), $
                     format='(%"insert into kcor_img (%s) values (%s)")')
    db->execute, sql_cmd, $
                 nrgfdiff_gif_basename, $
                 date_obs, $
                 date_end, $
                 obsday_index, $
                 'NULL', $
                 level_id, $
                 quality, $
                 producttype_id, $
                 gif_filetype_id, $
                 'NULL', $
                 'NULL', $
                 status=status
    if (status eq 0L) then begin
      mg_log, 'inserted %s into kcor_img', nrgfdiff_gif_basename, $
              name=run.logger_name, /info
    endif else begin
      mg_log, 'problem inserting %s into kcor_img', nrgfdiff_gif_basename, $
              name=run.logger_name, /info
    endelse
  endfor

  ; insert mp4 file into database
  if (nrfgdiff_mp4_found) then begin
    fields = [{name: 'file_name', type: '''%s'''}, $
              {name: 'date_obs', type: '''%s'''}, $
              {name: 'date_end', type: '''%s'''}, $
              {name: 'obs_day', type: '%d'}, $
              {name: 'carrington_rotation', type: '%s'}, $
              {name: 'level', type: '%d'}, $
              {name: 'quality', type: '%d'}, $
              {name: 'producttype', type: '%d'}, $
              {name: 'filetype', type: '%d'}, $
              {name: 'numsum', type: '%s'}, $
              {name: 'exptime', type: '%s'}]
    sql_cmd = string(strjoin(fields.name, ', '), $
                     strjoin(fields.type, ', '), $
                     format='(%"insert into kcor_img (%s) values (%s)")')
    db->execute, sql_cmd, $
                 nrfgdiff_mp4_basename, $
                 date_obs, $
                 date_end, $
                 obsday_index, $
                 'NULL', $
                 level_id, $
                 quality, $
                 producttype_id, $
                 mp4_filetype_id, $
                 'NULL', $
                 'NULL', $
                 status=status
    if (status eq 0L) then begin
      mg_log, 'inserted %s into kcor_img', nrfgdiff_mp4_basename, $
              name=run.logger_name, /info
    endif else begin
      mg_log, 'problem inserting %s into kcor_img', nrfgdiff_mp4_basename, $
              name=run.logger_name, /info
    endelse
  endif

  done:
  mg_log, 'done', name=run.logger_name, /info
end


; main-level example program

date = '20240409'
mode = 'test'
config_basename = 'kcor.latest.cfg'
config_filename = filepath(config_basename, $
                           subdir=['..', '..', '..', 'kcor-config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename, mode=mode)

obsday_index = mlso_obsday_insert(date, $
                                  run=run, $
                                  database=db, $
                                  status=db_status, $
                                  log_name='kcor/' + mode)

kcor_db_nrgfdiff_insert, database=db, run=run, obsday_index=obsday_index

obj_destroy, [db, run]

end
