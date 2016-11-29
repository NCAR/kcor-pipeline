;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Document name: fitcircle.pro
; Created by:    Randy Meisner, HAO/NCAR, Boulder, CO, August 12, 1997
;
; Last Modified: Tue Aug 12 15:58:58 1997 by meisner (Randy Meisner) on hoth
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
PRO fitcircle, x, y, xc, yc, r, rms=rms, help=help
;+
;
; PROJECT:
;       SunRISE
;
; NAME:
;       fitcircle     (procedure)
;
; PURPOSE:
;       To fit a set of (x, y) data coordinates to a circle, using least
;       squares fitting.
;
; CALLING SEQUENCE:
;
;       fitcircle, x, y, xc, yc, r [,err=err, help=help]
;
; INPUTS:
;       x - a COLUMN vector of the x data coordinates.
;       y - a COLUMN vector of the y data coordinates (same size as x).
;
; OPTIONAL INPUTS: 
;       None.
;
; OUTPUTS:
;       xc - the x coordinate of the center of the fit circle.
;       yc - the y coordinate of the center of the fit circle.
;        r - the radius of the fit circle.
;
; OPTIONAL OUTPUTS:
;       rms - root-mean-squared error of the radius for each coordinate.
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
;       minimizes ||Ax-b||^2 is
;
;                        T   -1  T
;                    x=(A  A)   A  B
;
;       which  is the least squares solution to Ax=B (See Introduction to
;       Applied Mathematics, by Gilbert Strang, 1986, p. 37).  The circle
;       parameters are then given by
;
;                   xc = -x(0)/2.0
;                   yc = -x(1)/2.0
;                  r^2 = xc^2 + yc^2 - x(2).
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
  doc_library,'fitcircle'
  RETURN
ENDIF

IF(N_PARAMS() NE 5) THEN BEGIN
  PRINT, ''
  PRINT, 'Usage:  fitcircle, x, y, xc, yc, r [, rms=rms, help=help]'
  PRINT, ''
  RETURN
ENDIF

A = [x, y, transpose(fltarr(n_elements(x))+1.)]

B = -x^2-y^2

ab=invert(transpose(A)##A)##transpose(A)##B

xc = -ab(0)/2.0 & yc = -ab(1)/2.0

r = sqrt(xc^2+yc^2-ab(2))


; Compute the errors.

ri = sqrt((x-xc)^2 + (y-yc)^2)

rms = sqrt((ri-r)^2/3.)

; Free up memory.

A = 0b & B = 0b & ab = 0b & ri = 0b

RETURN

END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; End of 'fitcircle.pro'.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
