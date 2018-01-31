;+
; NAME		blint.pro
;
; PURPOSE	Bilinear interpolation.
;
; SYNTAX	b = blint (img, xdim, ydim, nbypix, x, y)
;
;		img :	character pointer to array containing image.
;		x,y:	FLOATing point pointers to x & y position in image.
;
; OUTPUT
;		blint returns a FLOATing point value representing the intensity
;		value at position (x,y).
;
; HISTORY	Andrew L. Stanger   HAO/NCAR   28 August 2001
;- 

FUNCTION blint, img, x, y

   ix = FIX (x)
   iy = FIX (y)

   fx = x - ix
   fy = y - iy

   ;--- Select 4 nearest neighbor elements in 'image' array.

   f00 = FLOAT (img [ ix    ,  iy   ])
   f10 = FLOAT (img [(ix+1) ,  iy   ])
   f01 = FLOAT (img [ ix    , (iy+1)])
   f11 = FLOAT (img [(ix+1) , (iy+1)])

   ;--- Bilinear interpolation.

   fx0 = f00 + fx * (f10 - f00)
   fx1 = f01 + fx * (f11 - f01)
   fxy = fx0 + fy * (fx1 - fx0)

   RETURN, fxy
END 
