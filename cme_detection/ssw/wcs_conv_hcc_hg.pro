;+
; Project     :	STEREO
;
; Name        :	WCS_CONV_HCC_HG
;
; Purpose     :	Convert Heliocentric-Cartesian to Heliographic coordinates
;
; Category    :	Coordinates, WCS
;
; Explanation :	This routine converts Heliocentric-Cartesian (HCC)
;               coordinates into Heliographic (HG) coordinates,
;               using equations 12 in Thompson (2006), A&A, 449, 791-803.
;
; Syntax      :	WCS_CONV_HCC_HG, X, Y, HGLN, HGLT  [, HECR ]  [, SOLZ=Z ]
;
; Examples    :	WCS_CONV_HCC_HG, X, Y, HGLN, HGLT, WCS=WCS
;
; Inputs      :	X       = Solar X coordinate
;               Y       = Solar Y coordinate
;
; Opt. Inputs :	None.
;
; Outputs     :	HGLN    = Heliographic longitude
;               HGLT    = Heliographic latitude
;
;               HGLN and HGLT are returned in degrees.
;
;               If the /CARRINGTON keyword keyword is set, then these are
;               actually CRLN, CRLT.
;
; Opt. Outputs:	HECR    = Heliocentric distance, in the same units as X and Y.
;
; Keywords    :	SOLZ    = Solar Z coordinate, in the same units as X and Y.  If
;                         not passed, then the points are assumed to be on the
;                         solar surface.  Any points calculated as above the
;                         limb will be returned as Not-A-Number (NaN).
;
;               WCS     = World Coordinate System structure.  Used to determine
;                         B0, L0, and the units of the data.  See
;                         WCS_CONV_FIND_DSUN and WCS_CONV_FIND_HG_ANGLES for
;                         more information
;
;               LENGTH_UNITS = String describing the length units.  If not
;                         passed, then taken from WCS structure.
;
;               POS_LONG = If set, then force the output longitude to be
;                         positive, i.e. between 0 and 360 degrees.  The
;                         default is to return values between +/- 180 degrees.
;
;               CARRINGTON = If set, then the longitude is a Carrington
;                            longitude.  The default is Stonyhurst longitude.
;
;               FACTOR  = Returns the conversion factor between data and meters
;
; Calls       :	WCS_CONV_FIND_DSUN, WCS_CONV_FIND_HG_ANGLES, FLAG_MISSING
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
pro wcs_conv_hcc_hg, x, y, hgln, hglt, hecr, solz=solz, wcs=wcs, $
                     pos_long=pos_long, factor=factor, _extra=_extra
on_error, 2
;
if n_params() lt 4 then message, $
  'Syntax: WCS_CONV_HCC_HG, X, Y, HGLN, HGLT  [, HECR ]'
if n_elements(x) eq 0 then message, 'X not defined'
if n_elements(y) ne n_elements(x) then message, $
  'X and Y must have the same number of elements'
;
;  If the Z array was not passed, then assume r = Rsun.
;
if n_elements(solz) eq 0 then begin
    wcs_conv_find_dsun, dsun, rsun, factor, wcs=wcs, _extra=_extra
    z = rsun^2 - x^2 - y^2
    w = where(z lt 0, count)
    if count gt 0 then flag_missing, z, w
    z = sqrt(z)
end else z = solz
;
;  Get the B0 and L0 angles
;
wcs_conv_find_hg_angles, b0, l0, wcs=wcs, _extra=_extra
radeg = 180.d0 / !dpi
b0 = b0 / radeg
l0 = l0 / radeg
cosb = cos(b0)
sinb = sin(b0)
;
;  Perform the conversion.
;
hecr = sqrt(x^2 + y^2 + z^2)
hgln = atan(x, z*cosb - y*sinb)
hglt = asin((y*cosb + z*sinb) / hecr)
;
;  Add L0 to the longitude.
;
if l0 ne 0 then begin
    hgln = hgln + l0
    twopi = 2.d0 * !dpi
    w = where(hgln lt (-!dpi), count)
    if count gt 0 then hgln[w] = hgln[w] + twopi
    w = where(hgln gt !dpi, count)
    if count gt 0 then hgln[w] = hgln[w] - twopi
endif
;
;  If /POS_LONG is set, then add 360 degrees to negative longitude
;  values.
;
if keyword_set(pos_long) then begin
    w = where(hgln lt 0, count)
    if count gt 0 then hgln[w] = hgln[w] + (2.d0 * !dpi)
endif
;
;  Convert the longitude and latitude to degrees
;
hgln = hgln * radeg
hglt = hglt * radeg
;
return
end
