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
pro kcor_repair_fixmid, image=im, header=header
  compile_opt strictarr

  if (n_elements(header) gt 0L) then begin
    names = ['DIFFUSER', 'CALPOL', 'COVER', 'DARKSHUT']
    for n = 0L, n_elements(names) - 1L do begin
      if (strtim(sxpar(header, names[n]), 2) eq 'mid') then begin
        fxaddpar, header, names[n], 'out'
      endif
    endfor
  endif
end
