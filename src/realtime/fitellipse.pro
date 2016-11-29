;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Document name: fitellipse.pro
; Created by:    Randy Meisner, HAO/NCAR, Boulder, CO, August 12, 1997
;
; Last Modified: Tue Aug 12 16:10:55 1997 by meisner (Randy Meisner) on hoth
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
PRO fitellipse, x, y, coeff, xc, yc, r1, r2, phi, err=err, help=help
;+
;
; PROJECT:
;       SunRISE
;
; NAME:
;       fitellipse     (procedure)
;
; PURPOSE:
;       To fit a set of (x, y) data coordinates to an ellipse, using least
;       squares fitting.
;
; CALLING SEQUENCE:
;
;       fitellipse, x, y, coeff, xc, yc, r1, r2, phi [,err=err, help=help]
;
; INPUTS:
;       x - a COLUMN vector of the x data coordinates.
;       y - a COLUMN vector of the y data coordinates (same size as x).
;
; OPTIONAL INPUTS: 
;       None.
;
; OUTPUTS:
;       coeff - a 5 element column vector with the coefficients which satisfy
;               the ellipse equation in the following manner:
;   
;               (1+coeff(0)) x^2 + (1-coeff(0)) y^2 + coeff(1) x y + $
;
;               coeff(2) x + coeff(3) y + coeff(4) = 0
;   
;          xc - the x coordinate of the center of the ellipse.
;          yc - the y coordinate of the center of the ellipse.
;       r1,r2 - the semi-axes of the ellipse (r1:x, r2:y).
;         phi - the rotation angle of the ellipse (radians).
;
; OPTIONAL OUTPUTS:
;       err - a column vector of errors (e = B-Ax).
;
; KEYWORD PARAMETERS: 
;       /help.  Will call doc_library and list header, and return
;
; CALLS:
;       None.
;
; EXPLANATION:
;       This procedure uses the least squares method to solve the system Ax=B
;       which is described in the file fit_circ_ellip.txt.  The vector x that
;       mimimizes ||Ax-B||^2 is
;
;                        T   -1  T
;                    x=(A  A)   A  B
;
;       which  is the least squares solution to Ax=B (See Introduction to
;       Applied Mathematics, by Gilbert Strang, 1986, p. 37).
;   
; COMMON BLOCKS:
;       None.
;
; RESTRICTIONS: 
;       None.
;
; SIDE EFFECTS:
;       None.
;
; CATEGORY:
;       Part of the SunRISE image processing software.
;
; PREVIOUS HISTORY:
;       Written August 12, 1997, by Randy Meisner, HAO/NCAR, Boulder, CO
;
; MODIFICATION HISTORY:
;       
;
; VERSION:
;       Version 1, August 12, 1997
;-
;
ON_ERROR, 2

IF(N_ELEMENTS(help) GT 0) THEN BEGIN
  doc_library,'fitellipse'
  RETURN
ENDIF

IF(N_PARAMS() NE 8) THEN BEGIN
  PRINT, ''
  PRINT, 'Usage:  fitellipse, x, y, coeff, xc, yc, r1, r2, phi [,err=err,' + $
     ' help=help]'
  PRINT, ''
  RETURN
ENDIF

A = [x^2-y^2, x*y, x, y, transpose(fltarr(n_elements(x))+1.)]

B = -x^2-y^2

coeff=invert(transpose(A)##A)##transpose(A)##B

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Determine the center of the ellipse and the semi-axes.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

aa = 1.0+coeff(0) & bb = 1.0-coeff(0)

cc = coeff(1) & dd = coeff(2) & ee = coeff(3) & ff = coeff(4)

det = 4.0*aa*bb-cc^2

IF(det EQ 0) THEN BEGIN
   
   print, 'Not a quadratic form!', format = '(/, a, /)'
   return
   
ENDIF

xc = (cc * ee - 2.0 * bb * dd) / det

yc = (cc * dd - 2.0 * aa * ee) / det

phi = 0.5 * atan(cc / (aa - bb + 1.e-32))



aaa = 0.5 * (aa + bb + (aa - bb) / cos(2.0 * phi))

bbb = aa + bb - aaa

fff = aa*xc^2 + bb*yc^2 + cc*xc*yc - ff


IF(fff/aaa LT 0 OR fff/bbb LT 0) THEN BEGIN
   
   print, 'Not an ellipse!', format = '(/, a, /)'
   return
   
ENDIF


r1 = sqrt(fff/aaa)

r2 = sqrt(fff/bbb)


; Compute the error.
;ri = sqrt((x-xc)^2 + (y-yc)^2)
;rms = sqrt((ri-r)^2/3.)
err = B - A##coeff

; Free up memory.

A = 0b & B = 0b & aa = 0b & bb = 0b & cc = 0b & dd = 0b & ee = 0b & ff = 0b

det = 0b & aaa = 0b & bbb = 0b & fff = 0b

RETURN

END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; End of 'fitellipse.pro'.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

