;+
; PROJECT:
;	SDAC
; NAME:
;	SIGN
; PURPOSE:
;	This function takes two numbers X1,X2 and returns sign(X2)*abs(X1)
;	(by assumption sign(0)=1)
; CATEGORY:
;	NUMERICAL MATH UTILITY
; CALLING SEQUENCE:
;	A = SIGN(X1,X2)
; INPUTS:
;	X1	the absolute value of X1 is used
;	X2	the sign of X2 is used
; OUTPUTS:
;	SIGN	sign(X2)*abs(X1)
; PROCEDURE:
;	(Equivalent to FORTRAN SIGN function)
;	If X1 and X2 have the same number of elements the result is calculated
;	from corresponding elements in X1 and X2. If X2 is a scalar the sign
;	of X2 is used in combination with all elements of X1.
; MODIFICATION HISTORY:
;	APR-1991, Paul Hick (ARC)
;-

function SIGN, X1,X2

on_error, 1				; On error return to main level
if n_elements(X1) eq 0 or n_elements(X2) eq 0 then message, 'Both arguments must exist

A = n_elements(X1)  
B = n_elements(X2)

if A ne B and B ne 1 then message, 'Dimension error
OUT = abs(X1)
A = where(X2 lt 0)
if A(0) ne -1 then if B ne 1 then OUT(A) = -OUT(A) else OUT = -OUT
return, OUT  
end
