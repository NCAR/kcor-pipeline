; docformat = 'rst'

;+
; Determine occulter size in arcsec.
;
; :Params:
;   occulter_id : in, required, type=string
;     occulter ID from FITS header
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;-
function kcor_get_occulter_size, occulter_id, run=run
  compile_opt strictarr

  if (run->epoch('use_default_occulter_size')) then begin
    ; beginning of mission occulter ID was OC-1
    return, run->epoch('default_occulter_size')
  endif else begin
    ; later days use the first 8 characters to lookup in epoch file
    return, run->epoch(strmid(occulter_id, 0, 8))
  endelse
end