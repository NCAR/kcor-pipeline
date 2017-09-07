; docformat = 'rst'

;+
; Reinitialize common block variables that change.
;-
pro kcor_cme_det_reset
  compile_opt strictarr
  @kcor_cme_det_common

  running = 0B
  cme_occurring = 0B

  ifile = 0
  delvarx, date_orig, maps, date_diff, mdiffs, itheta, detected, leadingedge
  delvarx, param, tairef, angle, speed
end
