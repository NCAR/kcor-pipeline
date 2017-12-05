; docformat = 'rst'

;+
; Determine if the 2nd Lyot stop is in the optical path.
;
; :Returns:
;   'in' or 'out' (or '' if not present as a FITS keyword in a file that should
;   contain it)
;
; :Params:
;   header : in, required, type=strarr
;     FITS header for file
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;-
function kcor_lyotstop, header, run=run
  compile_opt strictarr

  if (run->epoch('use_lyotstop_keyword')) then begin
    lyotstop = sxpar(header, 'LYOTSTOP', count=n_lyotstop)
    return, n_lyotstop eq 0L ? '' : lyotstop
  endif else begin
    return, run->epoch('lyotstop')
  endelse
end
