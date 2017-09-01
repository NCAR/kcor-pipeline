;+
; Project     :	STEREO
;
; Name        :	WCS_CONV_HPR_HCR
;
; Purpose     :	Convert Heliocentric-Radial to angular coordinates
;
; Category    :	Coordinates, WCS
;
; Explanation :	This routine converts Helioprojective-Radial (HPR)
;               coordinates into Heliocentric-Radial (HCR) coordinates,
;               using equations 17 in Thompson (2006), A&A, 449, 791-803.
;
; Syntax      :	WCS_CONV_HPR_HCR, HRLT, RHO  [, Z ]  [, DISTANCE=DISTANCE ]
;
; Examples    :	WCS_CONV_HPR_HCR, HRLT, RHO, LENGTH_UNITS='solRad'
;
; Inputs      :	HRLT    = Helioprojective-radial latitude (Delta_Rho)
;                         or Theta_Rho if /ZERO_CENTER is set
;
; Opt. Inputs :	None.
;
; Outputs     :	RHO     = Solar cylindrical distance (impact parameter), in
;                         same units as DISTANCE.
;
;               Note that PHI is not calculated, because it is the same as HRLN
;
; Opt. Outputs:	Z       = The solar Z coordinate, in the same units as DISTANCE
;
; Keywords    :	DISTANCE= The distance of the point from the observer.  If not
;                         passed, then the points are assumed to be on the
;                         solar surface.  Any points calculated as above the
;                         limb will be returned as Not-A-Number (NaN).
;
;               WCS     = World Coordinate System structure.  Used to determine
;                         DSUN and the units of the data.
;
;               DSUN_OBS = Solar distance, in meters, if WCS not passed.
;
;               LENGTH_UNITS = String describing the input length units.  Only
;                              used if the Z values or DISTANCE are not passed.
;                              Can be any string recognized by wcs_parse_units,
;                              e.g. "m", "km", "AU", "solRad", etc.
;
;               ANG_UNITS = String describing the input angular units.  See
;                           WCS_CONV_FIND_ANG_UNITS for more information.
;
;               ZERO_CENTER = If set, then define the input longitude to be
;                             zero at disk center.  The default is -90 degrees
;                             at disk center to be compatible with WCS
;                             requirements.  In Thompson (2006) this is the
;                             distinction between theta_rho and delta_rho.
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
pro wcs_conv_hpr_hcr, hrlt, rho, z, distance=k_distance, wcs=wcs, $
                      ang_units=ang_units, zero_center=zero_center, $
                      factor=factor, _extra=_extra
on_error, 2
;
if n_params() lt 2 then message, $
  'Syntax: WCS_CONV_HPR_HCR, HRLT, RHO  [, Z ]'
if n_elements(hrlt) eq 0 then message, 'HRLT not defined'
;
;  Determine the conversion factor between the data and radians, and apply it
;  to the latitude array.
;
wcs_conv_find_ang_units, cx, cy, wcs=wcs, ang_units=ang_units, $
  type='Helioprojective-Radial'
;
lat = cy * hrlt
;
;  Unless /ZERO_CENTER is set, offset the latitude by 90 degrees.
;
if not keyword_set(zero_center) then lat = lat + (!dpi / 2.0d0)
;
;  Calculate the sines and cosines.
;
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
    q = dsun * cosy
    distance = q^2 - dsun^2 + rsun^2
    w = where(distance lt 0, count)
    if count gt 0 then flag_missing, distance, w
    distance = q - sqrt(distance)
end else distance = k_distance
;
;  Perform the conversion.
;
rho = distance * siny
z = dsun - distance * cosy
;
return
end
