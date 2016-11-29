;+
; NAME	wvec.pro
;
; PURPOSE	Draw a vector.
;
; SYNTAX	wvec, x1, y1, x2, y2, cindex
;
;		x1, y1	coordinates of start location
;		x2, y2	coordinates of end   location
;		cindex	color index [0-255]
;
; AUTHOR	Andrew L. Stanger   HAO/NCAR
; HISTORY	30 Dec 2005: procedure created.
;-

PRO wvec, fx1, fy1, fx2, fy2, cindex

  x1 = FIX (fx1)
  y1 = FIX (fy1)
  x2 = FIX (fx2)
  y2 = FIX (fy2)

;  PRINT, 'x1, y1:', x1, y1
;  PRINT, 'x2, y2:', x2, y2

  plots, [x1, y1], /device, color=cindex
  plots, [x2, y2], /device, color=cindex, /CONTINUE
  RETURN
END
