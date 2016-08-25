;+
;-------------------------------------------------------------------------------
; NAME		sunray_kcor.pro
;-------------------------------------------------------------------------------
; PURPOSE	Draw radial rays.
;
; SYNTAX	sunray_kcor, rmin, rmax, anginc, xcen, ycen, scroll, pixrs, $
;                            cindex, xmin, xmax, ymin, ymax
;
;		rmin, rmax:	start/stop radii [Rsun]
;		rinc:		increment for radius [Rsun]
;		anginc:		angular increment [degrees].
;		dotsize:	dot size [1, 3, 5, 7, ...] [pixels]
;		xcen, ycen:	sun center [pixels]
;		pixrs:		#pixels/Rsun.
;		scroll:		spacecraft roll [degrees]
;		cindex:		color index [0-255]
;		xmin, ymin:	Lower left  corner of window
;		xmax, ymax:	Upper right corner of window
;
; AUTHOR	Andrew L. Stanger   HAO/NCAR   10 Jan 2006
;		Adapted from "glcp_suncir.c".
; HISTORY
; 18 Nov 2015 [ALS] Modify for kcor.
;-------------------------------------------------------------------------------
;-

PRO sunray_kcor, rmin, rmax, rinc, anginc, dotsize, $
	         xcen, ycen, pixrs, scroll, cindex, $
	         xmin, xmax, ymin, ymax

   nres = 1			; Low resolution only.
;   cproll = 43.0		; C/P axis is 43 deg CCW from +Y axis.
   cproll = 0.0
   p = FIX (dotsize) / 2

   ;------------------------------------------------------------
   ; Draw radial scans (r=r1min -> r1max) every ang1inc degrees.
   ;------------------------------------------------------------

   FOR th = 0.0, 360.0, anginc DO	$
   BEGIN ;{
;      IF (th EQ 180.0) THEN rmin = 0.2 ELSE rmin = 0.4

      FOR r = rmin, rmax, rinc DO	$
      BEGIN ;{
	 ierr = rcoord (r, th, xx, yy, 1, scroll + cproll, xcen, ycen, pixrs)
	 xg = ((xx / nres) + 0.5) + xmin
	 yg = ((yy / nres) + 0.5) + ymin

	 FOR yp = yg - p, yg + p DO		$
	 BEGIN ;{
	 IF (xg-p GE xmin AND xg+p LE xmax  AND		$
	     yp   GE ymin AND yp   LE ymax) THEN	$
	     BEGIN ;{
		wvec, xg-p, yp, xg+p, yp, cindex
	     END   ;}
         END   ;}

      END   ;}

   END   ;}

RETURN
END
