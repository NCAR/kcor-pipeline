;+
; NAME:
;	FSHIFT
; PURPOSE:
;	To provide a shifted image in units of fractional pixels. 
; CALLING SEQUENCE:
;	oimage = fshift(data,x,y)
; INPUTS:
;	data	- An array of any size.
;	x,y	- Fractional amount of shift in x and y directions. 
;		  x positive ... shifts the image RIGHT
;		  y positive ... shifts the image UP
;		(i.e. signs of x and y have the same meaning as those of SHIFT)
; OPTIONAL INPUT:
;	interp	- Specify method of interpolation. Default value is 2 
;		  (cubic convolution interpolation). 
;		  See IDL manual for details. 
; OUTPUT:
;	oimage	- shifted image
; HISTORY:
;	version 1.0	T.Sakao written on 95.06.30 (Fri)
;		1.1	96.01.16 (Tue)	Option interp added. 
;-
;
;
function fshift, data, x, y, interp=itp

  p = fltarr(2,2)  &  p(*,*) = 0.0
  q = fltarr(2,2)  &  q(*,*) = 0.0

  p(0,0) = -x  &  p(0,1) = 1.0
  q(0,0) = -y  &  q(1,0) = 1.0

  if n_elements(itp) eq 0 then itp = 2

  return, poly_2d(data,p,q,itp)
end
