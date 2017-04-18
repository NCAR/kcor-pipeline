; docformat = 'rst'

;+
; Apply KCOR_NRGF to an array of L1 FITS files. Writes NRGFs in the current
; directory.
;
; :Params:
;   fits_files : in, required, type=strarr
;     array of KCor L1 FITS files
;
; :Keywords:
;   cropped : in, optional, type=boolean
;     set to create cropped NRGFs
;   run : in, required, type=object
;     `kcor_run` object
;-
pro kcor_nrgfs, fits_files, cropped=cropped, run=run
  compile_opt strictarr

  for f = 0L, n_elements(fits_files) - 1L do begin
    kcor_nrgf, fits_files[f], cropped=cropped, run=run
  endfor
end
