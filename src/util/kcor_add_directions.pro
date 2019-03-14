; docformat = 'rst'

;+
; Add cardinal directions (N, S, E, W) to a grid on a GIF image.
;
; :Params:
;   center : in, required, type=fltarr(2)
;     center of the image
;   r_photosphere : in, required, type=float
;     radius of the photosphere in pixels
;
; :Keywords:
;   charsize : in, optional, type=float, default=1.0
;     character size
;   cropped : in, optional, type=boolean
;     set to indicate a cropped plot
;   dimensions : in, optional, type=lonarr(2), default="[1024, 1024]"
;     dimensions of the image
;   color : in, optional, type=integer
;     color of characters
;-
pro kcor_add_directions, center, r_photosphere, $
                         charsize=charsize, cropped=cropped, $
                         dimensions=dimensions, $
                         color=color
  compile_opt strictarr

  _dims = n_elements(dimensions) eq 0L ? [1024L, 1024L] : dimensions

  cneg = fix(center[1] - r_photosphere) - keyword_set(cropped) * 4
  cpos = fix(center[1] + r_photosphere) + keyword_set(cropped) * 6

  xyouts, _dims[0] / 2, cpos - 24, 'N', $
          alignment=0.5, color=color, charsize=charsize, /device
  xyouts, cneg + 12, _dims[1] / 2 - 7, 'E', $
          color=color, charsize=charsize, /device
  xyouts, _dims[0] / 2, cneg + 12, 'S', $
          alignment=0.5, color=color, charsize=charsize, /device
  xyouts, cpos - 24, _dims[1] / 2 - 7, 'W', $
          color=color, charsize=charsize, /device

end
