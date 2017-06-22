;+
; Project     :	STEREO
;
; Name        :	WCS_CONV_HCR_HPR
;
; Purpose     :	Convert Heliocentric-Radial to angular coordinates
;
; Category    :	Coordinates, WCS
;
; Explanation :	This routine converts Heliocentric-Radial (HCR)
;               coordinates into Helioprojective-Radial (HPR) coordinates,
;               using equations 18 in Thompson (2006), A&A, 449, 791-803.
;
; Syntax      :	WCS_CONV_HCR_HPR, RHO, HRLT  [, DISTANCE ]  [, SOLZ=Z ]
;
; Examples    :	WCS_CONV_HCR_HPR, RHO, HRLT, LENGTH_UNITS='solRad'
;
; Inputs      :	RHO     = Solar cylindrical distance (impact parameter)
;
;               Phi is not inputted, because it does not change
;
; Opt. Inputs :	None.
;
; Outputs     :	HRLT    = Helioprojective-radial latitude (Delta_Rho)
;                         or Theta_Rho if /ZERO_CENTER is set
;
;               Note that HRLN is not calculated, because it is the same as Phi
;               HRLT is returned in degrees.
;
; Opt. Outputs:	DISTANCE= The distance of the point from the observer, in the
;                         same units as RHO.
;
; Keywords    :	SOLZ    = Solar Z coordinate, in the same units as RHO.  If not
;                         passed, then the points are assumed to be on the
;                         solar surface.  Any points calculated as above the
;                         limb will be returned as Not-A-Number (NaN).
;
;               WCS     = World Coordinate System structure.  Used to determine
;                         DSUN and the units of the data.  See
;                         WCS_CONV_FIND_DSUN for more information.
;
;               DSUN_OBS = Solar distance, in meters, if WCS not passed.
;
;               LENGTH_UNITS = String describing the length units.  If not
;                         passed, then taken from WCS structure.
;
;               ZERO_CENTER = If set, then define the input longitude to be
;                             zero at disk center.  The default is -90 degrees
;                             at disk center to be compatible with WCS
;                             requirements.  In Thompson (2006) this is the
;                             distinction between theta_rho and delta_rho.
;
;               FACTOR  = Returns the conversion factor between data and meters
;
; Calls       :	WCS_CONV_FIND_DSUN, FLAG_MISSING
;
; Common      :	None.
;
; Restrictions:	None.
;
; Side effects: None.
;
; Prev. Hist. :	None.
;
; History     :	Version 1, 11-Dec-2008, William Thompson, GSFC
;               Version 2, 09-Dec-2011, WTT, updated header
;
; Contact     :	WTHOMPSON
;-
;
pro wcs_conv_hcr_hpr, rho, hrlt, distance, solz=solz, wcs=wcs, factor=factor, $
                      zero_center=zero_center, nomask=nomask, _extra=_extra
on_error, 2
;
if n_params() lt 2 then message, $
  'Syntax: WCS_CONV_HCR_HPR, RHO, HRLT  [, DISTANCE ]'
if n_elements(rho) eq 0 then message, 'RHO not defined'
;
;  Get the DSUN and RSUN values.
;
wcs_conv_find_dsun, dsun, rsun, factor, wcs=wcs, _extra=_extra
;
;  If the Z array was not passed, then assume r = Rsun.
;
if n_elements(solz) eq 0 then begin
    z = rsun^2 - rho^2
    w = where(z lt 0, count)
    if count gt 0 then flag_missing, z, w
    z = sqrt(z)
end else z = solz
;
;  Perform the conversion.
;
hrlt = atan(rho, dsun - z)
distance = sqrt(rho^2 + (dsun - z)^2)
;
;  If the Z array was passed, then flag as missing any pixels that would be
;  obscured by the solar disk.
;
if (n_elements(solz) ne 0) and (not keyword_set(nomask)) then begin
    rho_max = asin(rsun/dsun)
    dmax = dsun * cos(rho_max)
    w = where((hrlt le rho_max) and (distance gt dmax), count)
    if count gt 0 then begin
        flag_missing, hrlt, w
        flag_missing, distance, w
    endif
endif
;
;  Unless /ZERO_CENTER is set, offset the latitude by 90 degrees.
;
if not keyword_set(zero_center) then hrlt = hrlt - (!dpi / 2.0d0)
;
;  Convert the latitude to degrees.
;
hrlt = hrlt * (180.d0 / !dpi)
;
return
end
