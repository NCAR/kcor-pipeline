; docformat = 'rst'

;+
; Read a calibration file listing and return the filenames.
;
; :Returns:
;   strarr
;
; :Params:
;   date : in, required, type=string
;     date in the form 'YYYYMMDD'
;   process_basedir : in, required, type=string
;     process base directory
;
; :Keywords:
;   exposures : out, optional, type=strarr
;     set to a named variable to retrieve the exposures matching the filenames
;     returned
;   n_files : out, optional, type=long
;     set to a named variable to retrieve the number of filenames returned
;-
function kcor_read_calibration_text, date, process_basedir, $
                                     exposures=exposures, $
                                     n_files=n_files, run=run
  compile_opt strictarr

  cal_file = filepath('calibration_files.txt', $
                      subdir=date, $
                      root=process_basedir)

  if (~file_test(cal_file)) then begin
    n_files = 0L
    return, !null
  endif

  n_files = file_lines(cal_file)
  if (n_files lt 1) then return, !null

  text = strarr(n_files)

  openr, lun, cal_file, /get_lun
  readf, lun, text
  free_lun, lun

  filenames = strarr(n_files)
  exposures = strarr(n_files)
  keep      = bytarr(n_files)

  for i = 0L, n_files - 1L do begin
    tokens = strsplit(text[i], /extract)
    filenames[i] = tokens[0]
    exposures[i] = tokens[1]

    run.time = strmid(tokens[0], 9, 6)
    keep[i] = run->epoch('process')
  endfor

  return, filenames[where(keep, n_files, /null)]
end


; main-level example program

config_filename = filepath('kcor.mgalloy.mahi.latest.cfg', $
                           subdir=['..', '..', 'config'], $
                           root=mg_src_root())
run = kcor_run(config_filename=config_filename)
filenames = kcor_read_calibration_text('20161127', run.process_basedir, $
                                       exposures=exposures, n_files=n_files, run=run)
obj_destroy, run

end
