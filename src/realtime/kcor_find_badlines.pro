
;+
; Find the bad horizontal lines in a full raw image by camera.
;
; :Params:
;   im : in, required, type="uintarr(nx, ny, 4, 2)"
;     raw image
;
; :Keywords:
;   cam0_badlines : out, optional, type=lonarr
;     bad lines for camera 0
;   cam1_badlines : out, optional, type=lonarr
;     bad lines for camera 1
;-
pro kcor_find_badlines, im, $
                        cam0_badlines=cam0_badlines, $
                        cam1_badlines=cam1_badlines
  compile_opt strictarr

  cam0_badlines = !null
  cam1_badlines = !null

  corona0 = kcor_corona(im[*, *, *, 0])
  corona1 = kcor_corona(im[*, *, *, 1])

  if (median(im) gt 10000.0) then return
  if (median(corona0) gt 200.0 || median(corona1) gt 200.0) then return

  cam0_badlines = kcor_find_badlines_camera(corona0)
  cam1_badlines = kcor_find_badlines_camera(corona1)
end
