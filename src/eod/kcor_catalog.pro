; docformat = 'rst'

;+
; Execute the `kcor_catalog` procedure for all KCor L0 FITS files for a
; specified date.
;
; :Params:
;   date : in, required, type=string
;     date in the form 'YYYYMMDD'
;
; :Keywords:
;   list : in, required, type=strarr
;     list of files to process
;   catalog_dir : out, optional, type=string
;     set to a named variable to retrieve the directory catalog'ed
;   run : in, required, type=object
;     `kcor_run` object
;
; :Author:
;   Andrew L. Stanger   HAO/NCAR	MLSO K-coronagraph
;   18 March 2015
;-
pro kcor_catalog, date, list=list, run=run, catalog_dir=catalog_dir
  compile_opt strictarr

  l0_dir = filepath('level0', subdir=date, root=run->config('processing/raw_basedir'))

  ; if date directory does not exist in 'process_basedir', create it
  process_datedir = filepath(date, root=run->config('processing/process_basedir'))
  if (~file_test (process_datedir, /directory)) then begin
    file_mkdir, process_datedir
  endif

  ; move to kcor L0 directory
  if (file_test(l0_dir, /directory)) then begin
    catalog_dir = l0_dir
  endif else begin
    catalog_dir = filepath(date, root=run->config('processing/raw_basedir'))
  endelse

  if (~file_test(catalog_dir, /directory)) then begin
    mg_log, 'raw directory does not exist', name='kcor/eod', /warn
    goto, done
  endif

  cd, catalog_dir

  if (n_elements(list) eq 0L) then begin
    list = file_search(filepath('*_kcor.fts.gz', root=catalog_dir), count=n_files)
  endif else begin
    n_files = n_elements(list)
  endelse

  mg_log, 'cataloging %d L0 files', n_files, name='kcor/eod', /info

  n_digits = long(alog10(n_files)) + 1L
  for f = 0L, n_files - 1L do begin
    fits_file = list[f]
    mg_log, mg_format('%*d/%d: %s', n_digits, /simple), $
            f + 1, n_files, file_basename(fits_file), $
            name='kcor/eod', /info
    kcor_catalog_file, fits_file, run=run
  endfor

  done:
end

