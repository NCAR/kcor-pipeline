; docformat = 'rst'

;+
; Repair routine to change the DIFFUSER "mid" values to "out".
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
    if (strtrim(sxpar(header, 'DIFFUSER'), 2) eq 'mid') then begin
      fxaddpar, header, 'DIFFUSER', 'out'
    endif
  endif
end
