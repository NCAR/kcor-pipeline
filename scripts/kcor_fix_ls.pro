; docformat = 'rst'

;+
; Remove duplicates in the .ls files in the q directory.
;
; :Params:
;   date : in, required, type=string
;     date in the form YYYYMMDD
;
; :Keywords:
;   config_filename : in, required, type=string
;     config filename
;-
pro kcor_fix_ls, date, config_filename=config_filename
  compile_opt strictarr

  mode = 'repair'
  run = kcor_run(date, config_filename=config_filename, mode=mode)
  logger_name = 'kcor/' + mode

  mg_log, 'repairing .ls files for %s', date, name=logger_name, /info

  q_dir = filepath('', $
                   subdir=[date, 'q'], $
                   root=run->config('processing/raw_basedir'))

  if (~file_test(q_dir, /directory)) then goto, done

  ls_files = file_search(filepath('*.ls', root=q_dir), count=n_ls_files)
  for f = 0L, n_ls_files - 1L do begin
    n_lines = file_lines(ls_files[f])
    if (n_lines eq 0L) then continue
    lines = strarr(n_lines)

    openr, lun, ls_files[f], /get_lun
    readf, lun, lines
    free_lun, lun

    unique_indices = uniq(lines, sort(lines))
    unique_lines = lines[unique_indices]

    mg_log, '%s: reducing from %d -> %d', $
            file_basename(ls_files[f]), n_lines, n_elements(unique_lines), $
            name=logger_name, /debug

    openw, lun, ls_files[f], /get_lun
    if (n_elements(unique_lines) gt 1L) then unique_lines = transpose(unique_lines)
    printf, lun, unique_lines
    free_lun, lun
  endfor

  done:
  mg_log, 'done', name=logger_name, /info
  obj_destroy, run
end


; main-level example program

config_filename = filepath('kcor.reprocess.cfg', $
                           subdir=['..', 'config'], $
                           root=mg_src_root())
kcor_fix_ls, '20200209', config_filename=config_filename
end
