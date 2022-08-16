; docformat = 'rst'

pro kcor_cme_retract_email, retract_time, retract_position_angle, comment=comment
  compile_opt strictarr
  @kcor_cme_det_common

  addresses = run->config('cme/email')
  if (n_elements(addresses) eq 0L) then begin
    mg_log, 'no cme.email specified, not sending email', $
            name='kcor/cme', /warn
    return
  endif

  ; create a temporary file for the message
  mailfile = mk_temp_file(dir=get_temp_dir(), 'cme_retract.txt', /random)

  ; write out the message to the temporary file
  openw, out, mailfile, /get_lun
  printf, out, 'An observer at the Mauna Loa Observatory is retracting the ' $
                 + 'CME alert produced by the automated CME detection ' $
                 + 'software for the CME found at ' $
                 + retract_time + ' UT and position angle ' $
                 + strtrim(long(retract_position_angle), 2) + ' degrees.'
  if (n_elements(comment) gt 0L && comment ne '') then begin
    printf, out
    printf, out, 'Observer comment: ' + comment
  endif

  spawn, 'echo $(whoami)@$(hostname)', who, error_result, exit_status=status
  if (status eq 0L) then begin
    who = who[0]
  endif else begin
    who = 'unknown'
  endelse

  printf, out
  printf, out, mg_src_root(/filename), who, format='(%"Sent from %s (%s)")'
  version = kcor_find_code_version(revision=revision, branch=branch)
  printf, out, version, revision, branch, format='(%"kcor-pipeline %s (%s) [%s]")'
  printf, out

  free_lun, out

  ut_date = kcor_cme_ut_date(retract_time, simple_date)
  subject = string(ut_date, retract_time, $
                   format='(%"MLSO K-Cor retract CME alert from %s at %s UT")')

  from_email = n_elements(run->config('cme/from_email')) eq 0L $
                 ? '$(whoami)@ucar.edu' $
                 : run->config('cme/from_email')
  cmd = string(subject, from_email, addresses, mailfile, $
               format='(%"mail -s \"%s\" -r %s %s < %s")')
  spawn, cmd, result, error_result, exit_status=status
  if (status eq 0L) then begin
    mg_log, 'alert sent to %s', addresses, name='kcor/cme', /info
  endif else begin
    mg_log, 'problem with mail command: %s', cmd, name='kcor/cme', /error
    mg_log, strjoin(error_result, ' '), name='kcor/cme', /error
  endelse

  ; delete the temporary file
  file_delete, mailfile
end

