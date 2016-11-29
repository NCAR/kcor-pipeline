;+
; :name; dokcormask
;
; :author: Andrew Stanger
;
; 29 October 2014
;
; :purpose: Create FOV mask for MLSO/COSMO K-coronagraph.
;-

PRO dokcormask

;--- Mask file name.

maskfile = 'kcor_mask.img'

;--- Image dimensions.

xdim = 1024
ydim = 1024

;--- Image center.

xcen = xdim * 0.5 - 0.5
ycen = ydim * 0.5 - 0.5

;--- FOV limits.

platescale = 5.643
occulter_size = 991.6		; use smallest occulter.
rmin = (occulter_size / platescale) + 5.0
rmax = 504.0

mask = fltarr (xdim, ydim)
mask (*, *) = 1.0

FOR ix = 0, xdim - 1 DO $
BEGIN
   xdist = ix - xcen
   FOR iy = 0, ydim -1 DO $
   BEGIN
   ydist = iy - ycen
   r = sqrt (xdist * xdist + ydist * ydist)
   IF (r LT rmin OR r GT rmax) THEN mask (ix, iy) = 0.0
   END
END

GET_LUN,  UMASK
CLOSE,    UMASK
OPENW,    UMASK, maskfile
WRITEU,   UMASK, mask
CLOSE,    UMASK
FREE_LUN, UMASK

END
