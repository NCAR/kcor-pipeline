; docformat = 'rst'

;+
; Write a level 1 IQU FITS file.
;
; :Params:
;   l0_filename : in, required, type=string
;     filename of corresponding level 0 file
;   data : in, required, type="fltarr(nx, ny, 3)"
;     IQU images
;   header : in, required, type=strarr
;     current level 1 header
;
; :Keywords:
;   run : in, required, type=run object
;     KCor run object
;-
pro kcor_write_iqu, l0_filename, data, header, run=run
  compile_opt strictarr

  iqu_header = header
  sxaddpar, iqu_header, $
            'OBJECT', $
            'Corona Stokes IQU', $
            ' calibrated corona+sky in cartesian coordinates'
  sxaddpar, iqu_header, $
            'PRODUCT', $
            'Stokes IQU', $
            ' calibrated corona+sky in cartesian coordinates', $
            after='OBJECT'

  iqu_basename = string(strmid(file_basename(l0_filename), 0, 20), $
                        format='(%"%s_l1_stokesIQU.fts")')
  iqu_filename = filepath(iqu_basename, $
                          subdir=[run.date, 'level1'], $
                          root=run->config('processing/raw_basedir'))

  writefits, iqu_filename, data, iqu_header
end
