;+
; NAME		sundot_kcor.pro
;
; PURPOSE	Draw a circle.
;
; SYNTAX	sundot_kcor, radius, angmin, angmax, anginc, cindex,	$
;		           xcen, ycen, scroll, pixrs, xmin, ymin, xmax, ymax
;		radius:		radius [Rsun]
;		angmin, angmax:	begin/end angles.
;		anginc:		angular increment.
;		cindex:		color index
;		xcen, ycen:	sun center
;		pixrs:		#pixels/Rsun.
;		scroll:		spacecraft roll.
;		xmin, ymin:	Lower left  corner of window
;		xmax, ymax:	Upper right corner of window
;
; AUTHOR	Andrew L. Stanger   HAO/NCAR   10 Jan 2006
;		Adapted from "glcp_suncir.c".
; 11 Jun 2015 adapt for kcor.
;-

PRO sundot_kcor, radius, angmin, angmax, anginc, cindex, $
                  xcen, ycen, pixrs, roll, xmin, xmax, ymin, ymax

   nres = 1			; Low resolution only.

   ; --- Draw circle.

   r = radius
   FOR th = angmin, angmax, anginc DO		$
   BEGIN
      ierr = rcoord (r, th, xx, yy, 1, roll, xcen, ycen, pixrs)
      xg = ((xx / nres) + 0.5) + xmin
      yg = ((yy / nres) + 0.5) + ymin
      IF (xg GE xmin AND xg LE xmax AND	$
	  yg GE ymin AND yg LE ymax) THEN	$
         BEGIN
	    wvec, xg,   yg-1, xg,   yg+1, cindex
	    wvec, xg-1, yg,   xg+1, yg,   cindex
	 END
   END

END
