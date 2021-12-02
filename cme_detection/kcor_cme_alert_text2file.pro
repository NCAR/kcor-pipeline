; docformat = 'rst'

;+
; Write the alert text to the given filename.
;
; :Params:
;   text : in, required, type=string
;     alert text as string
;   filename : in, required, type=string
;     filename to write
;-
pro kcor_cme_alert_text2file, text, filename
  compile_opt strictarr

  openw, lun, filename, /get_lun
  printf, lun, text
  free_lun, lun
end

