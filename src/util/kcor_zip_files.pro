; docformat = 'rst'

pro kcor_zip_files, glob, run=run
  compile_opt strictarr

  unzipped_files = file_search(glob, count=n_unzipped_files)
  if (n_unzipped_files gt 0L) then begin
    gzip_cmd = string(run->config('externals/gzip'), glob, $
                      format='(%"%s %s")')
    spawn, gzip_cmd, result, error_result, exit_status=status
    if (status ne 0L) then begin
      mg_log, 'problem zipping files with command: %s', gzip_cmd, $
                name=run.logger_name, /error
      mg_log, '%s', strjoin(error_result, ' '), name='kcor/rt', /error
    endif
  endif
end
