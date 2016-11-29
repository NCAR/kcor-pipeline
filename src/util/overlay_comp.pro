;+
; overlay_comp.pro
;-------------------------------------------------------------------------------
; :purpose: draw a polar grid overlay into the occulting region of a kcor image.
;-------------------------------------------------------------------------------
; :author: Andrew L. Stanger   HAO/NCAR   cosmo K-coronagraph
; :history: 
;  9 Jun 2015 IDL procedure created.
; 16 Jun 2015 Adapt for comp.
; 17 Jun 2015 Remove parameters: hdu, wmin/wmax.  Add xcen/ycen, pixrs, pangle.
;
; :params: 
;   hdu		fits header
;   xdim	x-axis dimension
;   ydim	y-axis dimention
;   xb		x-axis border
;   yb		y-axis border
;   wmim	display minimum
;   wmax	display maximum
;-------------------------------------------------------------------------------
;-

PRO overlay_comp, xdim, ydim, xcen, ycen, pixrs, pangle, xb, yb


  print, 'overlay_comp: '
  print, 'xdim/ydim, xcen/ycen, pixrs, pangle, xb/yb: '
  print, xdim, ydim, xcen, ycen, pixrs, pangle, xb, yb

  ;--- Color assignments for annotation.

  white  = 255
  red    = 254
  green  = 253
  blue   = 252
  grey   = 251
  yellow = 250
  black  =   0

  ; --- Draw sun circle.

  gMINCOL = xb
  gMAXCOL = xb + xdim - 1
  gMINROW = yb
  gMAXROW = yb + ydim - 1

  radius =   1.0
  angmin =   0.0
  angmax = 360.0
  anginc =  10.0

  sundot_kcor, radius, angmin, angmax, anginc, yellow,  		$
	       xcen, ycen, pixrs, pangle,				$
	       gMINCOL, gMAXCOL, gMINROW, gMAXROW

  radius = 1.0
  sundot_kcor, radius, angmin, angmax, anginc, red,	    		$
	       xcen, ycen, pixrs, pangle,				$
	       gMINCOL, gMAXCOL, gMINROW, gMAXROW

  ; --- Draw radial lines.

  rmin    =  1.2
  rmax    =  1.7
  rinc    =  0.2
  anginc  = 30.0
  dotsize =  3

;  sunray, rmin, rmax, rinc, anginc, dotsize,	$
;	  xcen, ycen, pixrs, pangle, red,  	$
;	  gMINCOL, gMAXCOL, gMINROW, gMAXROW

  ;--- 30 degree radial lines.

  rmin    = 0.2
  rmax    = 1.0
  rinc    = 0.2
  anginc  = 30.0
  dotsize = 3
  sunray_kcor, rmin, rmax, rinc, anginc, dotsize,	$
	       xcen, ycen, pixrs, pangle, grey,     	$
	       gMINCOL, gMAXCOL, gMINROW, gMAXROW

  ;--- 90 degree radial lines.

  rmin    =  0.3
  rmax    =  0.95
  rinc    =  0.1
  anginc  = 90.0
  dotsize =  3

  sunray_kcor, rmin, rmax, rinc, anginc, dotsize,	$
	       xcen, ycen, pixrs, pangle, red,    	$
	       gMINCOL, gMAXCOL, gMINROW, gMAXROW

  ;--- Draw north pointer.

  cirrad = 3.00
  cirrad = 1.35
  tiprad = 0.1

  north_comp, xcen, ycen, pixrs, pangle, cirrad, tiprad, yellow,	$
              gMINCOL, gMAXCOL, gMINROW, gMAXROW

  cirrad = 1.0
  tiprad = 0.03
  north_comp, xcen, ycen, pixrs, pangle, cirrad, tiprad, yellow,	$
              gMINCOL, gMAXCOL, gMINROW, gMAXROW

  RETURN
END
