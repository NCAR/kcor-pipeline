;+
;-----------------------------------------------------------------------------
; NAME		north_comp.pro
; -----------------------------------------------------------------------------
;
; PURPOSE	Draws a North pointer with center [screen coordinates]
;		at (xcen, ycen), circle radius 'cirrad', tip radius 'tiprad'.
; 
;		If the coordinates fall outside the displayable screen area,
;		the coordinates are clipped to the screen boundary.
; 
; EXTERNAL	wvec.pro		draw a vector on the display screen.
;
; SYNTAX	north_comp, xcen, ycen, pixrs, cirrad, tiprad, cindex,
;		          gMINCOL, gMAXCOL, gMINROW, gMAXROW
;
;		xcen, ycen		sun center coordinates
;		pixrs			# pixels/Rsun
;		scroll			spacecraft roll
;		cirrad			Circle radius [Rsun]
;		tiprad			Tip radius    [Rsun]
;		cindex			color LUT index [0-255]
;		gMINCOL, gMAXCOL	integers. Min and max horizontal pixels.
;		gMINROW, gMAXROW	integers. Min and max vertical pixels.
;
; AUTHOR	Andrew L. Stanger   HAO/NCAR   SMM C/P
;
; HISTORY	 5 Jun 1989
;		21 Aug 1990: Remove 2 degree offset previously used.
;		 4 Mar 1991: Make inner circle 0.1 Rsun.
;		 4 Apr 1991: SGI/GL version.
;		30 Dec 2005: IDL version
;                9 Jun 2015: kcor version
; -----------------------------------------------------------------------------
;-
 
PRO north_comp, xcen, ycen, pixrs, scroll, cirrad, tiprad, cindex,	$
	      gMINCOL, gMAXCOL, gMINROW, gMAXROW

;PRINT, '----------------------------------------------------------------------'
;PRINT, 'north_comp'
;PRINT, 'xcen/ycen: ', xcen, ycen
;PRINT, 'pixrs: ', pixrs, '   scroll: ', scroll
;PRINT, 'cirrad/tiprad/cindex: ', cirrad, tiprad, cindex
;PRINT, 'gMINCOL/gMAXCOL/gMINROW/gMAXROW: ', gMINCOL, gMAXCOL, gMINROW, gMAXROW

   ;--- Draw a dot at sun center.

   r  = 0.0
   th = 0.0
   ierr = rcoord (r, th, xx, yy, 1, scroll, xcen, ycen, pixrs)
;   print, 'xx/yy: ', xx, yy
   xx = xx + gMINCOL
   yy = yy + gMINROW
   wvec, xx-1, yy-1, xx+1, yy-1, 254
   wvec, xx-1, yy  , xx+1, yy  , 254
   wvec, xx-1, yy+1, xx+1, yy+1, 254

nres = 1	; Low resolution only.

;   float r, th;
;   float xx, yy;
;   int xg, yg;		/* Inner circle. */
;   int xcn, ycn;	/* North of center. */
;   int xcs, ycs;	/* South of center. */
;   int xce, yce;	/* East of center. */
;   int xcw, ycw;	/* West of center. */
;   int xpn, ypn;	/* North pointer tip. */
;   int xwe, ywe;	/* Left wing tip. */
;   int xww, yww;	/* Right wing tip. */

   ; *** North pointer tip coordinates. ***

   r  = tiprad
   th = 0.0
   ierr = rcoord (r, th, xx, yy, 1, scroll, xcen, ycen, pixrs)
   xpn = ((xx / nres) + 0.5) + gMINCOL
   ypn = ((yy / nres) + 0.5) + gMINROW

   ; *** East wing tip coordinates. ***

   r  = tiprad
   th = 90.0
   ierr = rcoord (r, th, xx, yy, 1, scroll, xcen, ycen, pixrs)
   xwe = ((xx / nres) + 0.5) + gMINCOL
   ywe = ((yy / nres) + 0.5) + gMINROW

   r = cirrad
   r = 0.1
   ierr = rcoord (r, th, xx, yy, 1, scroll, xcen, ycen, pixrs)
   xce = ((xx / nres) + 0.5) + gMINCOL
   yce = ((yy / nres) + 0.5) + gMINROW

   ; *** West wing tip coordinates. ***

   r  = tiprad
   th = 270.0
   ierr = rcoord (r, th, xx, yy, 1, scroll, xcen, ycen, pixrs)
   xww = ((xx / nres) + 0.5) + gMINCOL
   yww = ((yy / nres) + 0.5) + gMINROW

   r = cirrad
   r = 0.1
   ierr = rcoord (r, th, xx, yy, 1, scroll, xcen, ycen, pixrs)
   xcw = ((xx / nres) + 0.5) + gMINCOL
   ycw = ((yy / nres) + 0.5) + gMINROW

   ; *** Draw dots surrounding disk center pixel. ***

   r  = 0.0
   th = 0.0
   ierr = rcoord (r, th, xx, yy, 1, scroll, xcen, ycen, pixrs)
   xg = ((xx / nres) + 0.5) + gMINCOL
   yg = ((yy / nres) + 0.5) + gMINROW
;   print, 'center: ', xg, yg
   if (xg GE gMINCOL AND xg LE gMAXCOL AND yg GE gMINROW AND yg LE gMAXROW) $
   THEN		$
   BEGIN
      wvec, xg-1, yg,   xg+1, yg,   cindex 
      wvec, xg,   yg-1, xg,   yg+1, cindex
   END 

   ; *** Draw circle around disk center. ***

   r = cirrad

   FOR th = 0.0, 360.0, 10.0 DO	$
   BEGIN
      ierr = rcoord (r, th, xx, yy, 1, scroll, xcen, ycen, pixrs)
      xg = ((xx / nres) + 0.5) + gMINCOL
      yg = ((yy / nres) + 0.5) + gMINROW
      if (xg  GE gMINCOL AND xg  LE gMAXCOL AND yg GE gMINROW AND yg LE gMAXROW)$
      THEN	$
      BEGIN
;         wvec, xg, yg, xg, yg, cindex
         wvec, xg-1, yg-1, xg+1, yg+1, 251
         wvec, xg-1, yg+1, xg+1, yg-1, 251
      END
   END 

   ; *** Draw line from circle to north pointer tip. ***

   r = cirrad
   th = 0.0
   ierr = rcoord (r, th, xx, yy, 1, scroll, xcen, ycen, pixrs)
   xg = ((xx / nres) + 0.5) + gMINCOL
   yg = ((yy / nres) + 0.5) + gMINROW

;    if (xpn GE gMINCOL AND xpn LE gMAXCOL AND ypn GE gMINROW AND ypn LE gMAXROW AND
;        xg  GE gMINCOL AND xg  LE gMAXCOL AND yg  GE gMINROW AND yg  LE gMAXROW)
;       gl_wvec (xg, yg, xpn, ypn, cindex)
 
 
   ; *** Draw north pointer. ***

   ; * North pointer tip to east wing tip. *

   if (xpn GE gMINCOL AND xpn LE gMAXCOL AND ypn GE gMINROW AND ypn LE gMAXROW AND xwe GE gMINCOL AND xwe LE gMAXCOL AND ywe GE gMINROW AND ywe LE gMAXROW)$
      THEN wvec, xpn, ypn, xwe, ywe, cindex

   ; * Circle to east wing tip. *

   if (xce GE gMINCOL AND xce LE gMAXCOL AND yce GE gMINROW AND yce LE gMAXROW AND xwe GE gMINCOL AND xwe LE gMAXCOL AND ywe GE gMINROW AND ywe LE gMAXROW)$
       THEN wvec, xce, yce, xwe, ywe, cindex

   ; * North pointer tip to west wing tip. *

   if (xpn GE gMINCOL AND xpn LE gMAXCOL AND ypn GE gMINROW AND ypn LE gMAXROW AND xww GE gMINCOL AND xww LE gMAXCOL AND yww GE gMINROW AND yww LE gMAXROW)$
   THEN wvec, xpn, ypn, xww, yww, cindex

   ; * Circle to west wing tip. *

   if (xcw GE gMINCOL AND xcw LE gMAXCOL AND ycw GE gMINROW AND ycw LE gMAXROW AND xww GE gMINCOL AND xww LE gMAXCOL AND yww GE gMINROW AND yww LE gMAXROW) $
   THEN   wvec, xcw, ycw, xww, yww, cindex

   RETURN
END
