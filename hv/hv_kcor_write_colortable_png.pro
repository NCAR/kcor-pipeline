; docformat = 'rst'

;+
; Write out the KCor colortable as a PNG file.
;
; The colortable is defined by copying lines in kcor_l1.pro that load in a
; colortable and manipulate it just before a gif of the scaled FITS data is
; written out.  If the definition of the colortable in kcor_l1.pro should change
; then the relevant pieces of code should be copied here, the code re-run, and
; the new colortable should be sent to the Helioviewer Project
; (contact@helioviewer.org).
;
; There is also an assumption that the colortable stays the same for all images
; that it could be applied to. This may not be true since the KCor output could
; change for many different reasons (detector behavior changes, equipment
; changes, different processing pipeline). If this assumption is not true and
; the colortable changes as a function of time please let the Helioviewer
; Project developers know (contact@helioviewer.org).
;
; :Author:
;   Jack Ireland [JI]
;
; :History
;   20 Jun 2018 initial commit.
;
; :Params:
;   run : in, required, type=object
;     a `kcor_run` object
;
; :Keywords:
;   dir : in, optional, type=string
;     a string that specifies where to write out the PNG color table
;-
pro hv_kcor_write_colortable_png, run, dir=dir
  compile_opt strictarr

  if (n_elements(dir) eq 0L) then dir = ''

  ; all KCor measurements have the same colortable
  lct, filepath('quallab_ver2.lut', root=run.resources_dir)
  gamma_ct, run->epoch('display_gamma'), /current
  tvlct, red, green, blue, /get
  write_png, dir +  'kcor_all_colortable.png', a, red, green, blue
end
