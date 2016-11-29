;+
; NAME		sun_circle.pro
;
; PURPOSE	Draw a circle corresponding to the size of the solar photosphere
;
; SYNTAX	sun_circle, radius, angmin, angmax, anginc, cindex,	$
;		            xcen, ycen, scroll, pixrs, xmin, ymin, xmax, ymax
;		radius:		radius [Rsun units]
;		angmin, angmax:	begin/end angles  [degrees].
;		anginc:		angular increment [degrees].
;		cindex:		color index [0-255]
;		xcen, ycen:	sun center [pixels]
;		pixrs:		#pixels/Rsun.
;		scroll:		spacecraft roll [CCW degrees w.r.t. solar north]
;		xmin, ymin:	Lower left  corner of window
;		xmax, ymax:	Upper right corner of window
;
; AUTHOR	Andrew L. Stanger   HAO/NCAR   17 Nov 2015
;		Adapted from "glcp_suncir.c".
;-

PRO sun_circle, radius, angmin, angmax, anginc, cindex,			$
	        xcen, ycen, pixrs, scroll, xmin, xmax, ymin, ymax

   nres   = 1			; Low resolution only.
   cproll = 0.0			; C/P axis is 43 deg CCW from +Y axis.

   nres = 1			; Low resolution only.

   ; --- Draw circle.

   r = radius
   FOR th = angmin, angmax, anginc DO		$
   BEGIN ;{
      ierr = rcoord (r, th, xx, yy, 1, scroll+cproll, xcen, ycen, pixrs)
      xg = ((xx / nres) + 0.5) + xmin
      yg = ((yy / nres) + 0.5) + ymin
      IF (xg GE xmin AND xg LE xmax AND	$
	  yg GE ymin AND yg LE ymax) THEN	$
         BEGIN ;{
	    wvec, xg,   yg-1, xg,   yg+1, cindex
	    wvec, xg-1, yg,   xg+1, yg,   cindex
	 END   ;}
   END   ;}

END
