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
pro kcor_db_nrgfdiff_insert, nrgfdiff_gif_basenames, $
                             gif_date_obs, gif_date_end, $
                             gif_carrington_rotation, gif_numsum, gif_exptime, $
                             nrfgdiff_mp4_basename, $
                             mp4_date_obs, mp4_date_end, $
                             mp4_carrington_rotation, mp4_numsum, mp4_exptime, $
                             database=db, run=run, obsday_index=obsday_index
  compile_opt strictarr

  mg_log, 'inserting NRGF+diff GIFs and mp4...', name=run.logger_name, /info

  n_nrgfdiff_gifs = n_elements(nrgfdiff_gif_basenames)
  if (n_nrgfdiff_gifs eq 0L) then begin
    mg_log, 'no NRGF+diff GIFs found', name=run.logger_name, /debug
    goto, done
  endif

  nrfgdiff_mp4_found = n_elements(nrfgdiff_mp4_basename) gt 0L

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

  l2_dir = filepath('level2', $
                    subdir=[run.date], $
                    root=run->config('processing/raw_basedir'))

  quality = 75  ; level 2 files have default 75 quality

  fields = [{name: 'file_name', type: '''%s'''}, $
            {name: 'filesize', type: '%d'}, $
            {name: 'date_obs', type: '''%s'''}, $
            {name: 'date_end', type: '''%s'''}, $
            {name: 'obs_day', type: '%d'}, $
            {name: 'carrington_rotation', type: '%d'}, $
            {name: 'level', type: '%d'}, $
            {name: 'quality', type: '%d'}, $
            {name: 'producttype', type: '%d'}, $
            {name: 'filetype', type: '%d'}, $
            {name: 'numsum', type: '%d'}, $
            {name: 'exptime', type: '%f'}]
  sql_cmd = string(strjoin(fields.name, ', '), $
                   strjoin(fields.type, ', '), $
                   format='(%"insert into kcor_img (%s) values (%s)")')

  ; insert GIF files into database
  for f = 0L, n_nrgfdiff_gifs - 1L do begin
    filename = filepath(nrgfdiff_gif_basenames[f], root=l2_dir)
    db->execute, sql_cmd, $
                 nrgfdiff_gif_basenames[f], $
                 mg_filesize(filename), $
                 gif_date_obs[f], $
                 gif_date_end[f], $
                 obsday_index, $
                 gif_carrington_rotation[f], $
                 level_id, $
                 quality, $
                 producttype_id, $
                 gif_filetype_id, $
                 gif_numsum[f], $
                 gif_exptime[f], $
                 status=status
    if (status eq 0L) then begin
      mg_log, 'inserted %s into kcor_img', nrgfdiff_gif_basenames[f], $
              name=run.logger_name, /info
    endif else begin
      mg_log, 'problem inserting %s into kcor_img', nrgfdiff_gif_basenames[f], $
              name=run.logger_name, /info
    endelse
  endfor

  ; insert mp4 file into database
  if (nrfgdiff_mp4_found) then begin
    fields = [{name: 'file_name', type: '''%s'''}, $
              {name: 'filesize', type: '%d'}, $
              {name: 'date_obs', type: '''%s'''}, $
              {name: 'date_end', type: '''%s'''}, $
              {name: 'obs_day', type: '%d'}, $
              {name: 'carrington_rotation', type: '%d'}, $
              {name: 'level', type: '%d'}, $
              {name: 'quality', type: '%d'}, $
              {name: 'producttype', type: '%d'}, $
              {name: 'filetype', type: '%d'}, $
              {name: 'numsum', type: '%d'}, $
              {name: 'exptime', type: '%f'}]
    sql_cmd = string(strjoin(fields.name, ', '), $
                     strjoin(fields.type, ', '), $
                     format='(%"insert into kcor_img (%s) values (%s)")')
    db->execute, sql_cmd, $
                 nrfgdiff_mp4_basename, $
                 mg_filesize(filepath(nrfgdiff_mp4_basename, root=l2_dir)), $
                 mp4_date_obs, $
                 mp4_date_end, $
                 obsday_index, $
                 mp4_carrington_rotation, $
                 level_id, $
                 quality, $
                 producttype_id, $
                 mp4_filetype_id, $
                 mp4_numsum, $
                 mp4_exptime, $
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
