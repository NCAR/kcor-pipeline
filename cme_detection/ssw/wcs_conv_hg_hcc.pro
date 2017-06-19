;+
; Project     :	STEREO
;
; Name        :	WCS_CONV_HG_HCC
;
; Purpose     :	Convert Heliographic coordinates to Heliocentric-Cartesian
;
; Category    :	Coordinates, WCS
;
; Explanation : This routine converts Heliographic (HG) coordinates into
;               Heliocentric-Cartesian (HCC) coordinates, using equations 11 in
;               Thompson (2006), A&A, 449, 791-803.
;
; Syntax      :	WCS_CONV_HG_HCC, HGLN, HGLT, X, Y  [, Z ]  [, HECR=HECR ]
;
; Examples    :	WCS_CONV_HG_HCC, HGLN, HGLT, X, Y, LENGTH_UNITS='solRad'
;
; Inputs      :	HGLN    = Heliographic longitude
;               HGLT    = Heliographic latitude
;
;               If the /CARRINGTON keyword keyword is set, then these are
;               actually CRLN, CRLT.
;
; Opt. Inputs :	None.
;
; Outputs     :	X       = Solar X coordinate, in same units as HECR
;               Y       = Solar Y coordinate, in same units as HECR
;
; Opt. Outputs:	Z       = Solar Z coordinate, in same units as HECR
;
; Keywords    :	HECR    = Heliocentric distance.  If not passed, then the
;                         points are assumed to be on the solar surface.  Any
;                         points calculated as above the limb will be returned
;                         as Not-A-Number (NaN).
;
;               WCS     = World Coordinate System structure.  Used to determine
;                         B0, L0, and the units of the data.  See
;                         WCS_CONV_FIND_DSUN and WCS_CONV_FIND_HG_ANGLES for
;                         more information
;
;               DSUN_OBS = Solar distance, in meters, if neither HECR nor WCS
;                          passed.
;
;               LENGTH_UNITS = String describing the length units.  Only used
;                         if the HECR values are not passed.  Can be any string
;                         recognized by wcs_parse_units, e.g. "m", "km", "AU",
;                         "solRad", etc.  The default is meters (m).
;
;               ANG_UNITS = String describing the input angular units.  See
;                           WCS_CONV_FIND_ANG_UNITS for more information.
;
;               CARRINGTON = If set, then the longitude is a Carrington
;                            longitude.  The default is Stonyhurst longitude.
;
;               FACTOR  = Returns the conversion factor between data and meters
;
; Calls       :	WCS_CONV_FIND_DSUN, WCS_CONV_FIND_ANG_UNITS,
;               WCS_CONV_FIND_HG_ANGLES
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
;               Version 2, 09-Dec-2011, WTT, updated header
;
; Contact     :	WTHOMPSON
;-
;
pro wcs_conv_hg_hcc, hgln, hglt, x, y, z, hecr=k_hecr, wcs=wcs, $
                     factor=factor, _extra=_extra
on_error, 2
;
if n_params() lt 4 then message, $
  'Syntax: WCS_CONV_HG_HCC, HGLN, HGLT, X, Y  [, Z ]'
if n_elements(hgln) eq 0 then message, 'HGLN not defined'
if n_elements(hglt) ne n_elements(hgln) then message, $
  'HGLN and HGLT must have the same number of elements'
;
;  If the HECR array was not passed, then assume r = Rsun.  This requires
;  parsing LENGTH_UNITS to derive HECR.
;
if n_elements(k_hecr) eq 0 then begin
    wcs_conv_find_dsun, dsun, rsun, factor, wcs=wcs, _extra=_extra
    sz = size(hgln)
    if sz[0] eq 0 then hecr = rsun else begin
        dim = sz[1:sz[0]]
        hecr = make_array(value=rsun, dimension=dim)
    endelse
end else hecr = k_hecr
;
;  Determine the conversion factor between the data and radians, and apply it
;  to the longitude and latitude arrays.
;
wcs_conv_find_ang_units, cx, cy, wcs=wcs, type='Heliographic'
;
lon = cx * hgln
lat = cy * hglt
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
;  Subtract L0 from the longitude.
;
if l0 ne 0 then lon = lon - l0
;
;  Calculate the sines and cosines.
;
cosx = cos(lon)
sinx = sin(lon)
cosy = cos(lat)
siny = sin(lat)
;
;  Perform the conversion.
;
x = hecr * cosy * sinx
y = hecr * (siny*cosb - cosy*cosx*sinb)
z = hecr * (siny*sinb + cosy*cosx*cosb)
;
return
end
