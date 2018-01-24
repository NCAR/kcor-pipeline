; docformat = 'rst'

;+
; Create a movie from an array of GIF files. Creates temporary files in the
; current directory and deletes them when finished.
;
; :Params:
;   gif_filenames : in, required, type=strarr
;     GIF filenames that represent frames of the movie
;   mp4_filename : in, required, type=string
;     filename for output mp4 file
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;   status : out, optional, type=long
;     set to a named variable to retrieve the status of creating the mp4 file;
;     0 indicates success, anything else if failure
;-
pro kcor_create_mp4, gif_filenames, mp4_filename, run=run, status=status
  compile_opt strictarr

  n_gif_files = n_elements(gif_filenames)

  tmp_gif_fmt = '(%"tmp-%04d.gif")'
  for f = 0L, n_gif_files - 1L do begin
    file_link, gif_filenames[f], string(f, format=tmp_gif_fmt)
  endfor

  ; use FFmpeg to create mp4 from GIF files
  cmd_format = '(%"%s -r 20 -i tmp-%%*.gif -y -loglevel error ' $
                 + '-vcodec libx264 -passlogfile kcor_tmp -r 20 %s")')

  cmd = string(run.ffmpeg, mp4_filename, format=cmd_format)
  spawn, cmd, result, error_result, exit_status=status
  if (status ne 0L) then begin
    mg_log, 'problem creating mp4 with command: %s', cmd, $
            name='kcor/eod', /error
    mg_log, '%s', strjoin(error_result, ' '), name='kcor/eod', /error
  endif

  ; clean up temporary files
  for f = 0L, n_gif_files - 1L do file_delete, string(f, format=tmp_gif_fmt)
  tmp_files = file_search('kcor_tmp*', count=n_tmp_files)
  if (n_tmp_files gt 0L) then file_delete, tmp_files
end
