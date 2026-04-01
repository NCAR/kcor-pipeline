;+
;-------------------------------------------------------------------------------
; NAME	rcoord.pro
;-------------------------------------------------------------------------------
; FUNCTION	Coordinate transformation.
;
; SYNTAX   ierr = rcoord (radius, angle, x, y, isign, roll, xcen, ycen, pixrs)
;
; radius	distance from sun center in Rsun units.
; angle		position angle [degrees], CCW from solar north.
; x		X-axis pixel coordinate, origin at lower left corner.
; y		Y-axis pixel coordinate, origin at lower left corner.
; isign	=  1	[radius, angle] -> [x, y]
; isign = -1	[x, y] -> [radius, angle]
; roll		spacecraft roll w.r.t. solar north.
; xcen		X-axis coordinate of sun center.
; ycen		Y-axis coordinate of sun center.
; pixrs		# pixels per solar radius.
;
; NOTE:		Image coordinate origin (x=0,y=0): lower left corner.
;
; HISTORY	Author: Andrew L. Stanger   HAO/NCAR   4 June 1998
;-------------------------------------------------------------------------------
;-

; . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .

FUNCTION rcoord, radius, theta, x, y, isign, roll, xcen, ycen, pixrs

   degrad = 180.0 / ACOS (-1.0) 
   raddeg = 1.0 / degrad
   degnor =  90.0 + float (roll) ;	; Orientation of solar north.
   ierr = 0 ;

;   print, 'rcoord> xcen/ycen: ', xcen, ycen, '  pixrs: ', pixrs

   IF (isign EQ 1) THEN		$	; (radius,theta) --> (x,y)
      BEGIN	;{
      smmth = theta + degnor ;
      WHILE (smmth GT 360.0)  DO smmth = smmth - 360.0 ;
      angle = float (raddeg * smmth) ;
      x = float (xcen + radius * pixrs * COS (angle)) ;
      y = float (ycen + radius * pixrs * SIN (angle)) ;
      END	$ ;}
   ELSE		$			; (x,y) --> (r,theta)
      BEGIN	;{
      deltax = x - xcen ;
      deltay = y - ycen ;
      r2 = deltax * deltax + deltay * deltay ;

      radius = SQRT (r2) / pixrs ;
      theta = ATAN (deltay, deltax) * degrad - degnor ;
      WHILE (theta LT 0.0) DO theta = theta + 360.0 ;
      IF (ABS (radius) LT 1.E-4)  THEN theta = 0.0 ; 
      END	;}

;   print, 'rcoord> x/y:       ', x, y, '  isign: ', isign
;   print, 'rcoord> radius/theta: ', radius, theta

   RETURN, ierr ;
END	;}
