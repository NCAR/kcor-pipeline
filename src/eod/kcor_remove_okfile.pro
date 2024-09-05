; docformat = 'rst'

pro kcor_remove_okfile_removefile, ls_filename, l0_basename, n_removed=n_removed
  compile_opt strictarr

  n_removed = 0L

  if (~file_test(ls_filename, /regular)) then return
  n_files = file_lines(ls_filename)
  if (n_files eq 0L) then return

  files = strarr(n_files)
  openr, lun, ls_filename, /get_lun
  readf, lun, files
  free_lun, lun

  keep_indices = where(files ne l0_basename, n_keep, /null)
  files = files[keep_indices]

  n_removed = n_files - n_keep

  openw, lun, ls_filename, /get_lun
  if (n_keep gt 0L) then begin
    printf, lun, n_keep gt 1L ? transpose(files) : files
  endif
  free_lun, lun
end


pro kcor_remove_okfile_addfile, ls_filename, l0_basename
  compile_opt strictarr

  ; add in correct place
  n_ls_files = file_test(ls_filename, /regular) eq 0L ? 0L : file_lines(ls_filename)
  ls_files = n_ls_files eq 0L ? !null : strarr(n_ls_files)

  if (n_ls_files gt 0L) then begin
    openr, lun, ls_filename, /get_lun
    readf, lun, ls_files
    free_lun, lun
  endif

  ls_files = [ls_files, l0_basename]
  ls_files = ls_files[sort(ls_files)]

  openw, lun, ls_filename, /get_lun
  printf, lun, transpose(ls_files)
  free_lun, lun
end


;+
; Remove the results from a good level 0 file.
;
; - remove from kcor_file table of the database
; - remove anything with the same timestamp from the level 1 and level 2
;   directories
; - remove anything with the same timestamp from the web archive
; - move file from `oka.ls` to device files list file `dev.ls`
;
; :Params:
;   l0_basename : in, required, type=string
;     basename of level 0 KCor file, including the ".gz"
;   date : in, required, type=string
;     date in the form "YYYYMMDD"
;   db : in, required, type=object/undefined
;     database connection; if not valid, do not remove from database
;   raw_rootdir : in, required, type=string
;     root of the base raw directories
;   web_rootdir : in, required, type=string
;     root of the web archive directories
;   fullres_rootdir : in, required, type=string
;     root of the web fullres directories
;
; :Keywords:
;   logger_name : in, optional, type=string
;     name of the logger to send messages to
;-
pro kcor_remove_okfile, l0_basename, date, db, obsday_index, $
                        raw_rootdir, web_rootdir, fullres_rootdir, cropped_rootdir, $
                        logger_name=logger_name
  compile_opt strictarr

  date_parts = kcor_decompose_date(date)
  datetime = strmid(l0_basename, 0, 15)

  mg_log, 'removing %s...', l0_basename, name=logger_name, /warn

  ; remove from kcor_img table of the database

  if (obj_valid(db)) then begin
    query = 'delete from kcor_img where obs_day=%d and file_name like "%s%%"'
    db->execute, query, obsday_index, datetime, $
                 status=status, $
                 n_affected_rows=n_affected_rows
    if (status eq 0L) then begin
      mg_log, '%d rows deleted', n_affected_rows, name=logger_name, /warn
    endif
  endif

  ; remove anything with the same timestamp from the level 1 and level 2
  ; directories

  removed_dirname = filepath('', subdir=[date, 'removed'], root=raw_rootdir)
  levels = ['level1', 'level2']
  for i = 0L, n_elements(levels) - 1L do begin
    glob = filepath(datetime + '*', subdir=[date, levels[i]], root=raw_rootdir)
    files = file_search(glob, count=n_files)
    if (n_files gt 0L) then begin
      if (~file_test(removed_dirname, /directory)) then file_mkdir, removed_dirname
      file_move, files, removed_dirname, /overwrite
      mg_log, 'moved %d files from %s dir to removed dir', n_files, levels[i], $
              name=logger_name, /warn
    endif
  endfor

  ; remove anything with the same timestamp from the web archive

  if (n_elements(web_rootdir) gt 0L) then begin
    web_glob = filepath(datetime + '*', subdir=date_parts, root=web_rootdir)
    web_files = file_search(web_glob, count=n_web_files)
    if (n_web_files gt 0L) then begin
      file_delete, web_files, /allow_nonexistent, /quiet
      mg_log, 'removed %d files from web archive', n_web_files, $
              name=logger_name, /warn
    endif
  endif

  if (n_elements(fullres_dir) gt 0L) then begin
    fullres_glob = filepath(datetime + '*', subdir=date_parts, root=fullres_rootdir)
    fullres_files = file_search(fullres_glob, count=n_fullres_files)
    if (n_fullres_files gt 0L) then begin
      file_delete, fullres_files, /allow_nonexistent, /quiet
      mg_log, 'removed %d files from fullres archive', n_fullres_files, $
              name=logger_name, /warn
    endif
  endif

  if (n_elements(cropped_rootdir) gt 0L) then begin
    cropped_glob = filepath(datetime + '*', subdir=date_parts, root=cropped_rootdir)
    cropped_files = file_search(cropped_glob, count=n_cropped_files)
    if (n_cropped_files gt 0L) then begin
      file_delete, cropped_files, /allow_nonexistent, /quiet
      mg_log, 'removed %d files from cropped archive', n_cropped_files, $
              name=logger_name, /warn
    endif
  endif

  ; move file from `oka.ls` to device files list file `dev.ls` and `removed.ls`
  oka_filename = filepath('oka.ls', subdir=[date, 'q'], root=raw_rootdir)
  kcor_remove_okfile_removefile, oka_filename, l0_basename, n_removed=n_removed
  mg_log, 'removed %d files from oka.ls', n_removed, name=logger_name, /warn

  dev_filename = filepath('dev.ls', subdir=[date, 'q'], root=raw_rootdir)
  kcor_remove_okfile_addfile, dev_filename, l0_basename
  mg_log, 'added file to dev.ls', name=logger_name, /warn

  removed_filename = filepath('removed.ls', subdir=[date, 'q'], root=raw_rootdir)
  kcor_remove_okfile_addfile, removed_filename, l0_basename
  mg_log, 'added file to removed.ls', name=logger_name, /warn
end
