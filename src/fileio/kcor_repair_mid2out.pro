; docformat = 'rst'

;+
; Repair routine to change "mid" values to "out".
;
; :Keywords:
;   im : in, out, optional, type="uintarr(1024, 1024, 4, 2)"
;     image data to be repaired and returned via this parameter
;   header : in, out, optional, type=strarr
;     header data to be repaired and returned via this parameter
;-
pro kcor_repair_mid2out, image=im, header=header
  compile_opt strictarr

  if (n_elements(header) gt 0L) then begin
    fxaddpar, header, 'DIFFUSER', 'out'
    fxaddpar, header, 'CALPOL', 'out'
    fxaddpar, header, 'CALPOL', 'out'
    fxaddpar, header, 'CALPOL', 'out'
  endif
end
