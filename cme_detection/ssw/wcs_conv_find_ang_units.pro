;+
; Project     :	STEREO
;
; Name        :	WCS_CONV_FIND_ANG_UNITS
;
; Purpose     :	Find angular units conversion from WCS structure
;
; Category    :	Coordinates, WCS
;
; Explanation :	This routine is part of the WCS coordinate conversion
;               software.  It is used to find the conversion factors between
;               the data and radians.  The units could be based on an
;               examination of the WCS structure, or explicitly set through the
;               ANG_UNITS keyword.
;
; Syntax      :	WCS_CONV_FIND_ANG_UNITS, CX, CY, WCS=WCS
;
; Examples    :	See WCS_CONV_HPC_HCC
;
; Inputs      :	None.
;
; Opt. Inputs :	None.
;
; Outputs     :	CX      = Conversion factor along the longitude (X) axis
;               CY      = Conversion factor along the latitude  (Y) axis
;
; Opt. Outputs:	None.
;
; Keywords    :	WCS     = World Coordinate System structure.
;
;               TYPE    = Coordinate type string.  See FITSHEAD2WCS for valid
;                         values.  If present, then WCS must contain the same
;                         COORD_TYPE tag.  This is used internally by the WCS
;                         conversion routines to test whether the coordinates
;                         have already been converted to an intermediate
;                         system.
;
;               ANG_UNITS = String describing the angular units.  Can be one of
;                         the following: "degrees", "arcminutes", "arcseconds",
;                         "mas" (milli-arcseconds), or "radians".  The default
;                         is degrees.  Overrides WCS structure if present.
;
;               TO_DEGREES = If set, then calculate the conversion to degrees
;                            instead of to radians.
;
; Calls       :	VALID_WCS
;
; Common      :	None.
;
; Restrictions:	None.
;
; Side effects: None.
;
; Prev. Hist. :	None.
;
; History     :	Version 1, 12-Dec-2008, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;
pro wcs_conv_find_ang_units, cx, cy, wcs=wcs, type=type, ang_units=ang_units, $
                             to_degrees=to_degrees
on_error, 2
;
;  Start by setting the units to blank.
;
xunits = ''
yunits = ''
;
;  If the ANG_UNITS keyword was passed, then use this for both axes.
;
if datatype(ang_units) eq 'STR' then begin
    xunits = ang_units
    yunits = ang_units
    goto, calculate
endif
;
;  If a valid WCS structure is present, then use it to determine the units.
;
if valid_wcs(wcs) then begin
;
;  If the type keyword was set, then skip the WCS if the type doesn't match
;  that embedded within the structure.
;
    if n_elements(type) eq 1 then $
      if strpos(strlowcase(wcs.coord_type), strlowcase(type)) lt 0 then $
      goto, calculate
;
    xunits = wcs.cunit[wcs.ix]
    yunits = wcs.cunit[wcs.iy]
endif
;
;  Determine the conversion factor between the data and radians (degrees).
;
calculate:
;
if keyword_set(to_degrees) then cx = 1.d0 else cx = !dpi / 180.d0
xunits = strlowcase(xunits)
if strmid(xunits, 0, 4) eq 'arcm' then cx = cx / 60.d0
if strmid(xunits, 0, 4) eq 'arcs' then cx = cx / 3600.d0
if xunits eq 'mas'                then cx = cx / 3600.d3
if strmid(xunits, 0, 3) eq 'rad'  then $
  if keyword_set(to_degrees) then cx = 180.d0 / !dpi else cx = 1.d0
;
if keyword_set(to_degrees) then cy = 1.d0 else cy = !dpi / 180.d0
yunits = strlowcase(yunits)
if strmid(yunits, 0, 4) eq 'arcm' then cy = cy / 60.d0
if strmid(yunits, 0, 4) eq 'arcs' then cy = cy / 3600.d0
if yunits eq 'mas'                then cy = cy / 3600.d3
if strmid(yunits, 0, 3) eq 'rad'  then $
  if keyword_set(to_degrees) then cy = 180.d0 / !dpi else cy = 1.d0
;
return
end
