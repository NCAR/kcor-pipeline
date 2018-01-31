; docformat = 'rst'

;+
; Create an animated GIF from an array of GIF files.
;
; :Params:
;   gif_filenames : in, required, type=strarr
;     GIF filenames that represent frames of the animated GIF
;   animated_gif_filename : in, required, type=string
;     filename for output GIF file
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;   status : out, optional, type=long
;     set to a named variable to retrieve the status of creating the mp4 file;
;     0 indicates success, anything else if failure
;-
pro kcor_create_animated_gif, gif_filenames, animated_gif_filename, $
                              run=run, status=status
  compile_opt strictarr

  cmd_format = '(%"%s -delay 10 -loop 0 %s %s")'
  cmd = string(run.convert, $
               strjoin(gif_filenames, ' '), $
               animated_gif_filename, $
               format=cmd_format)
  spawn, cmd, result, error_result, exit_status=status
  if (status ne 0L) then begin
    mg_log, 'problem animated GIF with command: %s', cmd, $
            name='kcor/eod', /error
    mg_log, '%s', strjoin(error_result, ' '), name='kcor/eod', /error
  endif
end
