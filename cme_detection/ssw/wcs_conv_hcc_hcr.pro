;+
; Project     :	STEREO
;
; Name        :	WCS_CONV_HCC_HCR
;
; Purpose     :	Convert Heliocentric-Cartesian to -Radial coordinates
;
; Category    :	Coordinates, WCS
;
; Explanation :	This routine converts Heliocentric-Cartesian (HCC)
;               coordinates into Heliocentric-Radial (HCR) coordinates,
;               using equations 13 in Thompson (2006), A&A, 449, 791-803.
;
; Syntax      :	WCS_CONV_HCC_HCR, X, Y, PHI, RHO
;
; Examples    :	WCS_CONV_HCC_HCR, X, Y, PHI, RHO, /POS_LONG
;
; Inputs      :	X       = Solar X coordinate
;               Y       = Solar Y coordinate
;
; Opt. Inputs :	None.
;
; Outputs     :	PHI     = Position angle from solar north, in degrees.
;               RHO     = Solar cylindrical distance (impact parameter), in
;                         same units as X and Y
;
; Opt. Outputs:	None.
;
; Keywords    :	POS_LONG = If set, then force the output longitude (phi) to be
;                          between 0 and 360 degrees.  The default is to return
;                          values between +/- 180 degrees.
;
; Calls       :	None.
;
; Common      :	None.
;
; Restrictions:	None.
;
; Side effects: None.
;
; Prev. Hist. :	None.
;
; History     :	Version 1, 10-Dec-2008, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;
pro wcs_conv_hcc_hcr, x, y, phi, rho, pos_long=pos_long
on_error, 2
;
if n_params() ne 4 then message, $
  'Syntax: WCS_CONV_HCC_HCR, X, Y, PHI, RHO'
if n_elements(x) eq 0 then message, 'X not defined'
if n_elements(y) ne n_elements(x) then message, $
  'X and Y must have the same number of elements'
;
;  Perform the conversion.
;
rho = sqrt(x^2 + y^2)
phi = atan(-x, y)
;
;  If /POS_LONG is set, then add 360 degrees to negative longitude
;  values.
;
if keyword_set(pos_long) then begin
    w = where(phi lt 0, count)
    if count gt 0 then phi[w] = phi[w] + (2.d0 * !dpi)
endif
;
;  Convert phi to degrees.
;  to the longitude.
;
phi = phi * (180.d0 / !dpi)
;
return
end
