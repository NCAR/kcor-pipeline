;+
; Project     :	STEREO
;
; Name        :	WCS_CONV_HCR_HCC
;
; Purpose     :	Convert Heliocentric-Radial to -Cartesian coordinates
;
; Category    :	Coordinates, WCS
;
; Explanation : This routine converts Heliocentric-Radial (HCR) coordinates
;               into Heliocentric-Cartesian (HCC) coordinates, using equations
;               14 in Thompson (2006), A&A, 449, 791-803.
;
; Syntax      :	WCS_CONV_HCR_HCC, PHI, RHO, X, Y
;
; Examples    :	WCS_CONV_HCR_HCC, PHI, RHO, X, Y, LENGTH_UNITS='solRad'
;
; Inputs      :	PHI     = Position angle from solar north
;               RHO     = Solar cylindrical distance (impact parameter)
;
; Opt. Inputs :	None.
;
; Outputs     :	X       = Solar X coordinate (in same units as RHO)
;               Y       = Solar Y coordinate (in same units as RHO)
;
; Opt. Outputs:	None.
;
; Keywords    :	ANG_UNITS = String describing the angular units to be used for
;                         the angle phi.  Can be one of the following:
;                         "degrees", "arcminutes", "arcseconds", "mas"
;                         (milli-arcseconds), or "radians".  The default is
;                         degrees.
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
pro wcs_conv_hcr_hcc, phi0, rho, x, y, ang_units=ang_units
on_error, 2
;
if n_params() ne 4 then message, $
  'Syntax: WCS_CONV_HCR_HCC, PHI, RHO, X, Y'
if n_elements(phi0) eq 0 then message, 'PHI not defined'
if n_elements(phi0) ne n_elements(rho) then message, $
  'PHI and RHO must have the same number of elements'
;
;  Determine the conversion factor between the data and radians, and apply it
;  to the longitude phi.
;
cc = !dpi / 180.d0
if datatype(ang_units) eq 'STR' then begin
    cunit = strlowcase(ang_units)
    if strmid(cunit, 0, 4) eq 'arcm' then cc = cc / 60.d0
    if strmid(cunit, 0, 4) eq 'arcs' then cc = cc / 3600.d0
    if cunit eq 'mas'                then cc = cc / 3600.d3
    if strmid(cunit, 0, 3) eq 'rad'  then cc = 1.d0
endif
;
phi = cc * phi0
;
;  Perform the conversion.
;
x = -rho * sin(phi)
y =  rho * cos(phi)
;
return
end
