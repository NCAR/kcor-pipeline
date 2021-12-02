; docformat = 'rst'

;+
; Command to push a file to the FTP server::
;
;   curl --ssl -k --user anonymous:<your email> <FTP URL> -T <filename>
;
; :Params:
;   ftp_url : in, required, type=string
;     FTP address
;   filename : in, required, type=string
;     filename of file to transfer
;   email : in, required, type=string
;     email address of sender
;
; :Keywords:
;   status : out, optional, type=integer
;     set to a named variable to retrieve the status of the transfer, 0 for
;     success, other codes for errors
;   error_msg : out, optional, type=string
;     set to a named variable to retrieve the error message if `STATUS` was not
;     0
pro kcor_cme_ftp_transfer, ftp_url, filename, email, $
                           status=status, error_msg=error_msg
  compile_opt strictarr

  cmd = string(email, ftp_url, filename, $
               format='(%"curl --ssl -k --user anonymous:%s %s -T %s")')
  spawn, cmd, stdout, error_msg, exit_status=status
end
