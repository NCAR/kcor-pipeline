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
                                     n_files=n_files, run=run, $
                                     all_files=filenames, $
                                     n_all_files=n_all_files, $
                                     quality=quality
  compile_opt strictarr

  cal_file = filepath('calibration_files.txt', $
                      subdir=date, $
                      root=process_basedir)

  if (~file_test(cal_file)) then begin
    n_files = 0L
    n_all_files = 0L
    return, !null
  endif

  n_files = file_lines(cal_file)
  n_all_files = n_files
  if (n_files lt 1) then return, !null

  text = strarr(n_files)

  openr, lun, cal_file, /get_lun
  readf, lun, text
  free_lun, lun

  filenames = strarr(n_files)
  exposures = strarr(n_files)
  quality   = lonarr(n_files)

  for i = 0L, n_files - 1L do begin
    tokens = strsplit(text[i], /extract)
    filenames[i] = tokens[0]
    exposures[i] = tokens[1]

    run.time = strmid(tokens[0], 9, 6)

    ; TODO: eventually this quality will be determined by a GBU process, now is
    ; is either 0 or 99
    quality[i] = 99L * run->epoch('process') * run->epoch('use_calibration_data')
  endfor

  return, filenames[where(quality ge run->epoch('min_cal_quality'), n_files, /null)]
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
