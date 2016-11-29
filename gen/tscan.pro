;+ IDL PROCEDURE
; . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
; NAME		tscan.pro
;
; PURPOSE	Theta Scan for FITS images.
;
; SYNTAX	tscan, namimg, img, pixrs, roll, xcen, ycen,	$
;                      thmin, thmax, thinc, radius,		$
;		       scan, scandx, ns
;
; INPUT
;		namimg	image file name
;		img	2D image array
;		pixrs	#pixels/Rsun
;		roll	
;		xcen	X-axis center (pixels)
;		ycen	Y-axis center (pixels)
;		thmin	start angle
;		thmax	end   angle
;		thinc	angle increment
;		radius	height above solar limb (Rsun units)
;
; OUTPUT
;		scan	theta scan values
;		scandx	distance values
;		ns	number of data points in scan
;
; EXT.ROUTINES	rcoord.pro	converts between [r,th] and [x,y] coordinates.
;
; AUTHOR	Andrew L. Stanger   HAO/NCAR    8 Feb 2001
; . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
;-

PRO tscan, namimg, img, pixrs, roll, xcen, ycen,	$
	   thmin, thmax, thinc, radius,			$
	   scan, scandx, ns

   pi = 3.14159265
   degrad = 180.0 / pi		; degrees/radian

   ;--- Get image size.

   sizeimg = SIZE (img)
   nx = sizeimg [1]
   ny = sizeimg [2]

   ;--- Theta increment: set default to angle separating two adjacent pixels.

   IF (thmax LT thmin)  THEN thmax = thmax + 360.0
   tinc = thinc
   r = radius
   nval = FIX (((thmax - thmin) / tinc) + 0.5) + 1

;   PRINT, 'thmin, thmax, tinc: ', thmin, thmax, tinc
;   PRINT, 'nval: ', nval

   scan   = FLTARR (nval)
   scandx = FLTARR (nval)

   ;--- Initialize scan arrays.

   scan   [*] = 0.0
   scandx [*] = 0.0

   ;--- Theta scan loop

   ns = 0
   it = -1
   th = thmin - tinc

   FOR i = 0, nval - 1 DO		$
      BEGIN ;{
      th = th + tinc
      it = it + 1
 
      ;--- Coordinate transformation :  (radius,angle) --> (pixel,line).

      ierr = rcoord (radius, th, x, y, 1, roll, xcen, ycen, pixrs)
      IF (ierr NE 0)  THEN RETURN
;      print, 'roll: ', roll, ' xcen/ycen: ', xcen, ycen, ' pixrs: ', pixrs
;      print, '[r,th]: ', radius, th, '  [x,y]: ', x, y

      ;--- Angle array [degrees].

      scandx [it] = float (th)

      ;--- Nearest neighbor selection for pixel intensity.

      ix = FIX (x + 0.5)
      iy = FIX (y + 0.5)
      IF (ix LT 0 OR ix GT nx-1)  THEN		$
      BEGIN
	 PRINT, 'Invalid index ix,iy: ', ix, iy, ' nx: ', nx, $
		' r,th: ', radius, th
	 PRINT, 'xcen,ycen: ', xcen, ycen
	 PRINT, 'pixrs: ', pixrs
      END
      IF (iy LT 0 OR iy GT ny-1)  THEN		$
      BEGIN
	 PRINT, 'Invalid index ix,iy: ', ix, iy, ' nx: ', ny, $
		' r,th: ', radius, th
	 PRINT, 'xcen,ycen: ', xcen, ycen
	 PRINT, 'pixrs: ', pixrs
      END

      cval = img [ix, iy]

      ;--- Bi-linear interpolation.

      cval = blint (img, x, y)

      scan [it] = cval

      END ;}

   ns = it + 1

;   PRINT, 'ns: ', ns

   ;--- Print out scan values.

;   FOR it = 0, ns - 1 DO		$
;      PRINT, 'radius: ', radius, ' Position Angle:', scandx [it],	$
;	     ' scan:', scan [it]

   RETURN
END
