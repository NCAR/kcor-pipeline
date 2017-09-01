; docformat = 'rst'

;+
; Routine to create a calibration for a day, given a file list, date, and config
; file.
;
; :Params:
;   date : in, required, type=date
;     date in the form 'YYYYMMDD' to produce calibration for
;
; :Keywords:
;   config_filename : in, required, type=string
;     filename of configuration file
;   callist_filename : in, required, type=string
;     filename of list of files
;-
pro kcor_calibration, date, $
                      config_filename=config_filename, $
                      filelist_filename=filelist_filename
  compile_opt strictarr

  run = kcor_run(date, config_filename=config_filename)

  n_files = file_lines(filelist_filename)
  filelist = strarr(n_files)

  calfile = ''
  openr, lun, filelist_filename, /get_lun

  for f = 0L, n_files - 1L do begin
    readf, lun, calfile
    filelist[f] = calfile
  endfor

  free_lun, lun

  kcor_reduce_calibration, date, run=run, filelist=filelist
  obj_destroy, run
end