;+
; Project     :	STEREO
;
; Name        :	WCS_CONV_HPR_HPC
;
; Purpose     :	Convert Helioprojective-Radial to -Cartesian coordinates
;
; Category    :	Coordinates, WCS
;
; Explanation :	This routine converts Helioprojective-Radial (HPR) coordinates
;               into Helioprojective-Cartesian (HPC) coordinates, using
;               equations 20 in Thompson (2006), A&A, 449, 791-803.
;
; Syntax      :	WCS_CONV_HPR_HPC, HRLN, HRLT, HPLN, HPLT
;
; Examples    :	WCS_CONV_HPR_HPC, HRLN, HRLT, HPLN, HPLT, /ARCSECONDS
;
; Inputs      :	HRLN    = Helioprojective-radial longitude  (Phi)
;                         also known as the position angle
;               HRLT    = Helioprojective-radial latitude (Delta_Rho)
;                         or Theta_Rho if /ZERO_CENTER is set
;
; Opt. Inputs :	None.
;
; Outputs     :	HPLN    = Helioprojective-cartesian longitude (Theta_X)
;               HPLT    = Helioprojective-cartesian latitude  (Theta_Y)
;
;               By default, the output angles are returned in degrees,
;               regardless of the units of the input data.
;
; Opt. Outputs:	None.
;
; Keywords    :	WCS     = World Coordinate System structure.  Used to determine
;                         the angular units of the data.
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
;               QUICK   = If set, do a quick approximate calculation rather
;                         than a full-blown spherical calculation.  This is
;                         only appropriate for small angular distances close to
;                         the Sun.
;
;               ARCSECONDS = If set, then HPLN and HPLT are returned in
;                         arcseconds.
;
; Calls       :	WCS_CONV_FIND_ANG_UNITS
;
; Common      :	None.
;
; Restrictions:	None.
;
; Side effects:	None.
;
; Prev. Hist. :	None.
;
; History     :	Version 1, 10-Dec-2008, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;
pro wcs_conv_hpr_hpc, hrln, hrlt, hpln, hplt, ang_units=ang_units, wcs=wcs, $
                      quick=quick, zero_center=zero_center, $
                      arcseconds=arcseconds
on_error, 2
;
if n_params() ne 4 then message, $
  'Syntax: WCS_CONV_HPR_HPC, HRLN, HRLT, HPLN, HPLT'
if n_elements(hrln) eq 0 then message, 'HRLN not defined'
if n_elements(hrlt) ne n_elements(hrln) then message, $
  'HRLN and HRLT must have the same number of elements'
;
;  Determine the conversion factor between the data and radians, and apply it
;  to the longitude and latitude arrays.
;
wcs_conv_find_ang_units, cx, cy, wcs=wcs, ang_units=ang_units, $
  type='Helioprojective-Radial'
;
lon = cx * hrln
lat = cy * hrlt
;
;  Unless /ZERO_CENTER is set, offset the latitude by 90 degrees.
;
if not keyword_set(zero_center) then lat = lat + (!dpi / 2.0d0)
;
;  If the /QUICK option was selected, then do a quick version of the
;  calculation.
;
if keyword_set(quick) then begin
    hpln = -lat * sin(lon)
    hplt =  lat * cos(lon)
;
;  Otherwise, do a full-blown spherical calculation.
;
end else begin
    cosx = cos(lon)
    sinx = sin(lon)
    cosy = cos(lat)
    siny = sin(lat)
    hpln = atan(-sinx*siny, cosy)
    hplt = asin(siny*cosx)
endelse
;
;  Convert the data into degrees (or arcseconds).
;
radeg = 180.d0 / !dpi
hpln = hpln * radeg
hplt = hplt * radeg
if keyword_set(arcseconds) then begin
    hpln = 3600 * hpln
    hplt = 3600 * hplt
endif
;
return
end
