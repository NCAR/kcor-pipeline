; docformat = 'rst'

;+
; Execute the `kcor_catalog` procedure for all kcor L0 fits files for a
; specified date.
;
; :Params:
;   date : in, required, type=string
;     date in the form 'YYYYMMDD'
;
; :Keywords:
;   list : in, required, type=strarr
;     list of files to process
;   run : in, required, type=object
;     `kcor_run` object
;
; :Author:
;   Andrew L. Stanger   HAO/NCAR	MLSO K-coronagraph
;   18 March 2015
;-
pro dokcor_catalog, date, list=list, run=run
  compile_opt strictarr

  l0_dir = filepath('level0', subdir=date, root=run.raw_basedir)

  ; if date directory does not exist in 'process_basedir', create it
  process_datedir = filepath(date, root=run.process_basedir)
  if (~file_test (process_datedir, /directory)) then begin
    file_mkdir, process_datedir
  endif

  ; move to kcor L0 directory
  cd, l0_dir

  for f = 0L, n_elements(list) - 1L do begin
    fits_file = list[f]
    mg_log, '%d/%d: %s', f + 1, n_elements(list), file_basename(fits_file), $
            name='kcor/eod', /info
    kcor_catalog, fits_file, run=run
  endfor
end

