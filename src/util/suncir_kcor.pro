;+
; NAME		suncir_kcor.pro
;
; PURPOSE	Draw a circle at 1.0 Rsun.
;
; SYNTAX	suncir_kcor, xdim, ydim, xcen, ycen, xb, yb, pixrs, roll
;
;		xdim:  x-axis dimension
;		ydim:  y-axis dimension
;		xcen:  x-axis center
;		ycen:  y-axis center
;		xb:    x-axis border for annotation
;		yb:    y-axis border for annotation
;		pixrs: pixels/solar radius
;		roll:  roll angle (solar north w.r.t. +Y axis, CCW=positive).
;
; HISTORY	Andrew L. Stanger   HAO/NCAR   23 November 2004
; 11 Feb 2005 [ALS]: Do NOT draw a circle at 1.1 Rsun.
; 21 May 2015 derived from suncir_mk4.pro.
;-

PRO suncir_kcor, xdim, ydim, xcen, ycen, xb, yb, pixrs, roll
  compile_opt strictarr

   white  = 255
   red    = 254
   green  = 253
   blue   = 252
   grey   = 251
   yellow = 250
   black  =   0

   r       = 1.0
   r1min   = 0.2		; radial inner limit for major lines.
   r1max   = 1.0		; radial outer limit for major lines.
   r1inc   = 0.2		; radial  increment between major lines
   ang1inc = 30.0		; angular increment between major lines.

   r2min   = 0.2		; radial inner limit for major lines.
   r2max   = 0.8		; radial outer limit for major lines.
   r2inc   = 0.1		; radial  increment between major lines
   ang2inc = 90.0		; angular increment between major lines.

   print, 'pixrs: ', pixrs

   ; --- Sun center location.

   xg = FIX (xcen + xb + 0.5)
   yg = FIX (ycen + yb + 0.5)
   rp = FIX (pixrs / 10.0 + 0.5) - 1
   rp = rp * (pixrs / 160.0)

   IF (pixrs LT 120.0) THEN		$
   BEGIN ;{

      ; --- Draw "+ mark at sun center.

      PLOTS, xg-rp,   yg,      /device, color=white
      PLOTS, xg-1,    yg,      /device, color=white, /continue

      PLOTS, xg+1,    yg,      /device, color=white
      PLOTS, xg+rp,   yg,      /device, color=white, /continue

      PLOTS, xg,      yg-rp,   /device, color=white
      PLOTS, xg,      yg-1,    /device, color=white, /continue

      PLOTS, xg,      yg+1,    /device, color=white
      PLOTS, xg,      yg+rp,   /device, color=white, /continue

   END   ;}

   IF (pixrs GE 120.0) THEN		$
   BEGIN ;{

      ; --- Draw a triangle with a base on the equator.

      PLOTS, xg-rp,   yg,    /device, color=white
      PLOTS, xg,      yg+rp, /device, color=white, /continue

      PLOTS, xg+1,    yg+rp, /device, color=white
      PLOTS, xg+rp+1, yg,    /device, color=white, /continue

      PLOTS, xg-rp,   yg,    /device, color=white
      PLOTS, xg-1,    yg,    /device, color=white, /continue

      PLOTS, xg+2,    yg,    /device, color=white
      PLOTS, xg+rp+1, yg,    /device, color=white, /continue

      ; --- Draw a vertical line below the triangle.

      PLOTS, xg,    yg-rp, /device, color=white
      PLOTS, xg,    yg-1,  /device, color=white, /continue

      PLOTS, xg+1,  yg-rp, /device, color=white
      PLOTS, xg+1,  yg-1,  /device, color=white, /continue

      PLOTS, xg,    yg+2,  /device, color=white
      PLOTS, xg+1,  yg+2,  /device, color=white, /continue
      END   ;}

   ; --- Draw a triangle with a base 10 pixels above the equator.

;   PLOTS, xg,    yg+1,  /device, color=white
;   PLOTS, xg,    yg+7,  /device, color=white, /continue

;   PLOTS, xg,    yg+8,  /device, color=white
;   PLOTS, xg,    yg+10, /device, color=white, /continue

;   PLOTS, xg-5,  yg+10, /device, color=white
;   PLOTS, xg,    yg+15, /device, color=white, /continue

;   PLOTS, xg,    yg+15, /device, color=white
;   PLOTS, xg+5,  yg+10, /device, color=white, /continue

;   PLOTS, xg-5,  yg+10, /device, color=white
;   PLOTS, xg+5,  yg+10, /device, color=white, /continue

   ; --- Draw radial scans every 30 degrees.

   FOR th = 0.0, 360.0, ang1inc DO		$
   BEGIN ;{
      FOR radius = r1min, r1max*1.01, r1inc DO	$
      BEGIN ;{
	 ierr = rcoord (radius, th, x, y, 1, roll, xcen, ycen, pixrs)
	 xg = FIX (x + xb + 0.5)
	 yg = FIX (y + yb + 0.5)
	 PLOTS, xg, yg, /device, color=white
	 PLOTS, xg, yg, /device, color=white, /continue
;	 print, 'radius/th: ', radius, th, ' x/y: ', x, y
      END   ;}
   END   ;}

   ; --- Draw radial scans every 90 degrees.

   FOR th = 0.0, 360.0, ang2inc DO		$
   BEGIN ;{
      FOR radius = r2min, r2max*1.01, r2inc DO	$
      BEGIN ;{
	 ierr = rcoord (radius, th, x, y, 1, roll, xcen, ycen, pixrs)
	 xg = FIX (x + xb + 0.5)
	 yg = FIX (y + yb + 0.5)
	 PLOTS, xg,   yg,   /device, color=white
	 PLOTS, xg,   yg,   /device, color=white, /continue
	 PLOTS, xg,   yg,   /device, color=white
	 PLOTS, xg,   yg,   /device, color=white, /continue
      END   ;}
   END   ;}

   ; --- Draw a circle at 1.0 Rsun:  one dot every 5 degrees.

   r = 1.0
   FOR th = 0, 360, 5 DO			$
   BEGIN ;{
      ierr = rcoord (r, th, x, y, 1, roll, xcen, ycen, pixrs)
      xg = FIX (x + xb + 0.5)
      yg = FIX (y + yb + 0.5)
      PLOTS, xg,   yg,   /device, color=white
      PLOTS, xg,   yg,   /device, color=white, /continue
      PLOTS, xg,   yg,   /device, color=white
      PLOTS, xg,   yg,   /device, color=white, /continue
   END   ;}

   ; --- Draw a circle at 1.0 Rsun:  one BOLD dot every 10 degrees.

   r = 1.0
   FOR th = 0, 360, 10 DO			$
   BEGIN ;{
      ierr = rcoord (r, th, x, y, 1, roll, xcen, ycen, pixrs)
      xg = FIX (x + xb + 0.5)
      yg = FIX (y + yb + 0.5)
;      PLOTS, xg,   yg,   /device, color=white
;      PLOTS, xg,   yg,   /device, color=white, /continue

      PLOTS, xg-1, yg-1, /device, color=white
      PLOTS, xg+1, yg-1, /device, color=white, /continue
      PLOTS, xg+1, yg+1, /device, color=white, /continue
      PLOTS, xg-1, yg+1, /device, color=white, /continue
      PLOTS, xg-1, yg-1, /device, color=white, /continue
   END   ;}

   ; --- Draw a circle at 1.1 Rsun:  one dot every 30 degrees.

;   r = 1.1
;   FOR th = 0, 360, 30 DO			$
;   BEGIN ;{
;      ierr = rcoord (r, th, x, y, 1, roll, xcen, ycen, pixrs)
;      xg = FIX (x + xb + 0.5)
;      yg = FIX (y + yb + 0.5)
;      PLOTS, xg,   yg,   /device, color=white
;      PLOTS, xg,   yg,   /device, color=white, /continue
;      PLOTS, xg,   yg,   /device, color=white
;      PLOTS, xg,   yg,   /device, color=white, /continue
;   END   ;}

   ;--- Draw a circle at 3.0 Rsun.

   r3 = pixrs * 3.0
;   tvcircle, r3, xcen, ycen, color=254, /device

   ; --- Draw a circle at 3.0 Rsun:  one BOLD dot every 30 degrees.

   r = 3.02
   FOR th = 0, 360, 30 DO			$
   BEGIN ;{
      ierr = rcoord (r, th, x, y, 1, roll, xcen, ycen, pixrs)
      xg = FIX (x + xb + 0.5)
      yg = FIX (y + yb + 0.5)
;      PLOTS, xg,   yg,   /device, color=white
;      PLOTS, xg,   yg,   /device, color=white, /continue

;      PLOTS, xg-3, yg-3, /device, color=white
;      PLOTS, xg+3, yg-3, /device, color=white, /continue
;      PLOTS, xg+3, yg+3, /device, color=white, /continue
;      PLOTS, xg-3, yg+3, /device, color=white, /continue
;      PLOTS, xg-3, yg-3, /device, color=white, /continue
;      PLOTS, xg+3, yg+3, /device, color=white, /continue
   END   ;}


   ; --- Draw a circle at 3.0 Rsun:  one BOLD dot every 10 degrees.

   r = 3.02
   FOR th = 0, 360, 10 DO			$
   BEGIN ;{
      ierr = rcoord (r, th, x, y, 1, roll, xcen, ycen, pixrs)
      xg = FIX (x + xb + 0.5)
      yg = FIX (y + yb + 0.5)
;      PLOTS, xg,   yg,   /device, color=white
;      PLOTS, xg,   yg,   /device, color=white, /continue
      PLOTS, xg-1, yg-1, /device, color=white
      PLOTS, xg+1, yg-1, /device, color=white, /continue
      PLOTS, xg+1, yg+1, /device, color=white, /continue
      PLOTS, xg-1, yg+1, /device, color=white, /continue
      PLOTS, xg-1, yg-1, /device, color=white, /continue
   END   ;}

   RETURN
END
