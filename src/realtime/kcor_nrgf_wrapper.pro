; docformat = 'rst'

;+
; Wrapper to call `kcor_nrgf`.
;
; :Params:
;   date : in, required, type=string
;     date in the form 'YYYYMMDD'
;
; :Keywords:
;   config_filename : in, required, type=string
;     filename of config file
;   l0_basename : in, required, type=string
;     basename of filename of L0 file to process to NRGF
;-
pro kcor_nrgf_wrapper, date, l0_basename, config_filename=config_filename
  compile_opt strictarr

  ; catch and log any crashes
  catch, error
  if (error ne 0L) then begin
    catch, /cancel
    mg_log, /last_error, name='kcor/eod', /critical
    kcor_crash_notification, /realtime, run=run
    goto, done
  endif

  valid_date = kcor_valid_date(date, msg=msg)
  if (~valid_date) then message, msg

  run = kcor_run(date, config_filename=config_filename)

  log_name = 'kcor/rt'

  dirs  = filepath('level' + ['0', '1', '2'], $
                   subdir=run.date, $
                   root=run->config('processing/raw_basedir'))
  l0_dir = dirs[0]
  l1_dir = dirs[1]
  l2_dir = dirs[2]

  date_dir = filepath(run.date, root=run->config('processing/raw_basedir'))

  l0_filename = filepath(file_basename(l0_basename), root=l0_dir)
  unchecked_l0_filename = filepath(file_basename(l0_basename), root=date_dir)

  if (file_test(l0_basename, /regular)) then begin
    l0_filename = l0_basename
  endif else if (file_test(l0_filename, /regular)) then begin
    ; nothing to do
  endif else if (file_test(unchecked_l0_filename, /regular)) then begin
    l0_filename = unchecked_l0_filename
  endif else begin
    message, string(l0_basename, format='(%"%s not found")')
  endelse

  kcor_l1, l0_filename, $
           run=run, $
           l1_filename=l1_filename, $
           l1_header=l1_header, $
           intensity=intensity, $
           q=q, $
           u=u, $
           flat_vdimref=flat_vdimref, $
           scale_factor=scale_factor, $
           log_name=log_name, $
           error=l1_error

  kcor_l2, l1_filename, $
           l1_header, $
           intensity, q, u, flat_vdimref, $
           scale_factor=scale_factor, $
           l2_filename=l2_filename, $
           run=run, $
           nomask=nomask, $
           log_name=log_name, $
           error=l2_error

  kcor_nrgf, filepath(l2_filename, root=l2_dir), run=run, log_name=log_name

  done:
  if (obj_valid(run)) then obj_destroy, run
end
