;+ IDL PROCEDURE
; . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
; NAME		rscan.pro
;
; PURPOSE	Radial Scan for FITS images.
;
; SYNTAX	rscan, namimg, img, pixrs, roll, xcen, ycen, $
;                      radmin, radmax, radinc, angle,	$
;		       scan, scandx, ns
;
; INPUT
;		namimg	image file name
;		img	2D image array
;		pixrs	pixels / Rsun
;		roll	roll angle
;		xcen	sun center x-axis
;		ycen	sun center y-axis
;		radmin	start radius
;		radmax	end   radius
;		radinc	radial increment
;		angle	position angle (CCW degrees from solar north)
;
; OUTPUT
;		scan	radial scan values
;		scandx	distance values
;		ns	number of data points in scan
;
; EXT.ROUTINES	rcoord.pro	converts between [r,th] and [x,y] coordinates.
;
; AUTHOR	Andrew L. Stanger   HAO/NCAR   10 Aug 2001
; . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
;-

PRO rscan, namimg, img, pixrs, roll, xcen, ycen,	$
	   radmin, radmax, radinc, angle,		$
	   scan, scandx, ns

   print, 'xcen/ycen: ', xcen, ycen, ' pixrs: ', pixrs
   pi = 3.14159265
   degrad = 180.0 / pi		; degrees/radian

   ;--- Get image size.

   sizeimg = SIZE (img)
   nx = sizeimg [1]
   ny = sizeimg [2]

   ;--- Radial increment: set default to 0.005 Rsun.

   IF (radmax LT radmin)  THEN		$	; exchange radmin & radmax.
       BEGIN
       temp = radmin
       radmin = radmax
       radmax = radmin
       END

   rinc = radinc
   nval = FIX (((radmax - radmin) / rinc) + 0.5) + 1

;   PRINT, 'radmin, radmax, rinc: ', radmin, radmax, rinc
;   PRINT, 'nval: ', nval

   scan   = FLTARR (nval)
   scandx = FLTARR (nval)

   ;--- Initialize scan arrays.

   scan [*]   = 0.0
   scandx [*] = 0.0

   ;--- Radial scan loop

   ns = 0
   ir = -1
   radius = radmin - radinc

   FOR i = 0, nval - 1 DO		$
      BEGIN ;{
      radius = radius + rinc
      ir = ir + 1
 
      ;--- Coordinate transformation :  (radius,angle) --> (pixel,line).

      ierr = rcoord (radius, angle, x, y, 1, roll, xcen, ycen, pixrs)
      IF (ierr NE 0)  THEN RETURN

      ;--- Radial array [Rsun].

      scandx [ir] = float (radius)

      ;--- Nearest neighbor selection for pixel intensity.

      ix = FIX (x + 0.5)
      iy = FIX (y + 0.5)
      cval = img [ix, iy]

      scan [ir] = cval

;      print, 'radius/angle: ', radius, angle, '  scan: ', scan [ir] 
;      print, 'x,y: ', x, y

      END ;}

   ns = ir + 1

;   PRINT, 'ns: ', ns

   ;--- Print out scan values.

;   FOR ir = 0, ns - 1 DO		$
;      PRINT, 'angle: ', angle, ' Radius:', scandx [ir],	$
;	     ' scan:', scan [ir]

   RETURN
END
