;+
; Project     :	STEREO
;
; Name        :	WCS_CONV_HPC_HCC
;
; Purpose     :	Convert Helioprojective-Cartesian to X,Y,Z coordinates
;
; Category    :	Coordinates, WCS
;
; Explanation :	This routine converts Helioprojective-Cartesian (HPC)
;               coordinates into Heliocentric-Cartesian (HCC) coordinates,
;               using equations 15 in Thompson (2006), A&A, 449, 791-803.
;
; Syntax      :	WCS_CONV_HPC_HCC, HPLN, HPLT, X, Y  [, Z ]  [, DISTANCE=DISTANCE ]
;
; Examples    :	WCS_CONV_HPC_HCC, HPLN, HPLT, X, Y, LENGTH_UNITS='solRad'
;
; Inputs      :	HPLN    = Helioprojective-cartesian longitude (Theta_X)
;               HPLT    = Helioprojective-cartesian latitude  (Theta_Y)
;
; Opt. Inputs :	None.
;
; Outputs     :	X       = Solar X coordinate, in the same units as DISTANCE
;               Y       = Solar Y coordinate, in the same units as DISTANCE
;
; Opt. Outputs:	Z       = Solar Z coordinate, in the same units as DISTANCE
;
; Keywords    :	DISTANCE= The distance of the point from the observer.  If not
;                         passed, then the points are assumed to be on the
;                         solar surface.  Any points calculated as above the
;                         limb will be returned as Not-A-Number (NaN).
;
;               WCS     = World Coordinate System structure.  Used to determine
;                         DSUN.  See WCS_CONV_FIND_DSUN for more information.
;
;               DSUN_OBS = Solar distance, in meters, if neither WCS nor
;                          DISTANCE passed.
;
;               LENGTH_UNITS = String describing the length units.  Only used
;                         if the distance values are not passed.  Can be any
;                         string recognized by wcs_parse_units, e.g. "m", "km",
;                         "AU", "solRad", etc.  The default is meters (m).
;
;               ANG_UNITS = String describing the input angular units.  See
;                           WCS_CONV_FIND_ANG_UNITS for more information.
;
;               FACTOR  = Returns the conversion factor between data and meters
;
; Calls       :	WCS_CONV_FIND_ANG_UNITS, WCS_CONV_FIND_DSUN, FLAG_MISSING
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
pro wcs_conv_hpc_hcc, hpln, hplt, x, y, z, distance=k_distance, wcs=wcs, $
                      ang_units=ang_units, factor=factor, _extra=_extra
on_error, 2
;
if n_params() lt 4 then message, $
  'Syntax: WCS_CONV_HCC_HPC, HPLN, HPLT, X, Y [, Z ]'
if n_elements(hpln) eq 0 then message, 'HPLN not defined'
if n_elements(hplt) ne n_elements(hpln) then message, $
  'HPLN and HPLT must have the same number of elements'
;
;  Determine the conversion factor between the data and radians, and apply it
;  to the longitude and latitude arrays.
;
wcs_conv_find_ang_units, cx, cy, wcs=wcs, ang_units=ang_units, $
  type='Helioprojective-Cartesian'
;
lon = cx * hpln
lat = cy * hplt
;
;  Calculate the sines and cosines.
;
cosx = cos(lon)
sinx = sin(lon)
cosy = cos(lat)
siny = sin(lat)
;
;  Get the DSUN and RSUN values.
;
wcs_conv_find_dsun, dsun, rsun, factor, wcs=wcs, _extra=_extra
;
;  If the DISTANCE array was not passed, then assume r = Rsun.
;
if n_elements(k_distance) eq 0 then begin
    q = dsun * cosy * cosx
    distance = q^2 - dsun^2 + rsun^2
    w = where(distance lt 0, count)
    if count gt 0 then flag_missing, distance, w
    distance = q - sqrt(distance)
end else distance = k_distance
;
;  Perform the conversion.
;
x = distance * cosy * sinx
y = distance * siny
z = dsun - distance * cosy * cosx
;
return
end
