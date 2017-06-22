;+
; Project     :	STEREO
;
; Name        :	WCS_CONV_HPC_HPR
;
; Purpose     :	Convert Helioprojective-Cartesian to -Radial coordinates
;
; Category    :	Coordinates, WCS
;
; Explanation :	This routine converts Helioprojective-Cartesian (HPC)
;               coordinates into Helioprojective-Radial (HPR) coordinates,
;               using equations 19 in Thompson (2006), A&A, 449, 791-803.
;
; Syntax      :	WCS_CONV_HPC_HPR, HPLN, HPLT, HRLN, HRLT
;
; Examples    :	WCS_CONV_HPC_HPR, HPLN, HPLT, HRLN, HRLT, WCS=WCS
;
; Inputs      :	HPLN    = Helioprojective-cartesian longitude (Theta_X)
;               HPLT    = Helioprojective-cartesian latitude  (Theta_Y)
;
; Opt. Inputs :	None.
;
; Outputs     :	HRLN    = Helioprojective-radial longitude  (Phi)
;                         also known as the position angle
;               HRLT    = Helioprojective-radial latitude (Delta_Rho)
;                         or Theta_Rho if /ZERO_CENTER is set
;
;               The output angles are returned in degrees, regardless of the
;               units of the input data.
;
; Opt. Outputs:	None.
;
; Keywords    :	WCS     = World Coordinate System structure.  Used to determine
;                         the angular units of the data.
;
;               ANG_UNITS = String describing the input angular units.  See
;                           WCS_CONV_FIND_ANG_UNITS for more information.
;
;               ZERO_CENTER = If set, then define the output longitude to be
;                             zero at disk center.  The default is -90 degrees
;                             at disk center to be compatible with WCS
;                             requirements.  In Thompson (2006) this is the
;                             distinction between theta_rho and delta_rho.
;
;               POS_LONG = If set, then force the output longitude to be
;                         positive, i.e. between 0 and 360 degrees.  The
;                         default is to return values between +/- 180 degrees.
;
;               QUICK   = If set, do a quick approximate calculation rather
;                         than a full-blown spherical calculation.  This is
;                         only appropriate for small angular distances close to
;                         the Sun.
;
; Calls       :	WCS_CONV_FIND_ANG_UNITS
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
pro wcs_conv_hpc_hpr, hpln, hplt, hrln, hrlt, ang_units=ang_units, wcs=wcs, $
                      quick=quick, zero_center=zero_center, pos_long=pos_long
on_error, 2
;
if n_params() ne 4 then message, $
  'Syntax: WCS_CONV_HPC_HPR, HPLN, HPLT, HRLN, HRLT'
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
;  If the /QUICK option was selected, then do a quick version of the
;  calculation.
;
if keyword_set(quick) then begin
    hrln = atan(-lon, lat)
    hrlt = sqrt(lon^2 + lat^2)
;
;  Otherwise, do a full-blown spherical calculation.
;
end else begin
    cosx = cos(lon)
    sinx = sin(lon)
    cosy = cos(lat)
    siny = sin(lat)
    hrln = atan(-cosy*sinx, siny)
    hrlt = atan(sqrt(cosy^2*sinx^2 + siny^2), cosy*cosx)
endelse
;
;  Unless /ZERO_CENTER is set, offset the latitude by -90 degrees.
;
if not keyword_set(zero_center) then hrlt = hrlt - (!dpi / 2.0d0)
;
;  If /POS_LONG is set, then add 360 degrees to negative longitude
;  values.
;
if keyword_set(pos_long) then begin
    w = where(hrln lt 0, count)
    if count gt 0 then hrln[w] = hrln[w] + (2.d0 * !dpi)
endif
;
;  Convert the data into degrees.
;
radeg = 180.d0 / !dpi
hrln = hrln * radeg
hrlt = hrlt * radeg
;
return
end
