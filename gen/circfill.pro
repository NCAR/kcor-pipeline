;+
; circfill.pro
;
; PURPOSE	Fill a circle with a specified color.
;
; SYNTAX	circfill, img, xdim, ydim, xcen, ycen, radius, color
;
;		img	2D image array
;		xdim	x dimension
;		ydim	y dimension
;		xcen	x center
;		ycen	y center
;		radius	radius of circle in pixels
;		color	color index for fill
;
; AUTHOR	Andrew L. Stanger   HAO/NCAR   14 Feb 2006
;-

PRO circfill, img, xdim, ydim, xcen, ycen, radius, color

  FOR iy = 0, ydim - 1 DO		$
  BEGIN
     dy = FLOAT (iy) - ycen
     y2 = dy * dy
     FOR ix = 0, xdim - 1 DO	$
     BEGIN
       dx = FLOAT (ix) - xcen
       x2 = dx * dx
       radpix = sqrt (x2 + y2)
       IF (radpix LE radius) THEN img [ix, iy] = color
     END
  END

  RETURN
END
