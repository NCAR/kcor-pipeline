; docformat = 'rst'

;+
; Create a directory.
;
; :Params:
;   dir : in, required, type=string
;     directory to create
;
; :Keywords:
;   status : out, optional, type=long
;     set to a named variable to retrieve the error status
;   error_message : out, optional, type=string
;     set to a named variable to retrieve the error message if `status` is not
;     0, empty string if `status` is 0
;-
pro kcor_mkdir, dir, status=status, error_message=error_message
  compile_opt strictarr

  error_message = ''
  catch, status
  if (status ne 0L) then begin
    catch, /cancel
    error_message = !error_state.msg
    return
  endif

  file_mkdir, dir
end


; main-level example program

kcor_mkdir, '/hao/ftp/2026/01/22', status=status, error_message=error_message

print, status
print, error_message

kcor_mkdir, 'tmp', status=status, error_message=error_message

print, status
print, error_message

end
