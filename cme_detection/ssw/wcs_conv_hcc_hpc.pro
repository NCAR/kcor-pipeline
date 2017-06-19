;+
; Project     :	STEREO
;
; Name        :	WCS_CONV_HCC_HPC
;
; Purpose     :	Convert Heliocentric-Cartesian to angular coordinates
;
; Category    :	Coordinates, WCS
;
; Explanation :	This routine converts Heliocentric-Cartesian (HCC)
;               coordinates into Helioprojective-Cartesian (HPC) coordinates,
;               using equations 16 in Thompson (2006), A&A, 449, 791-803.
;
; Syntax      :	WCS_CONV_HCC_HPC, X, Y, HPLN, HPLT  [, DISTANCE ]  [, SOLZ=Z ]
;
; Examples    :	WCS_CONV_HCC_HPC, X, Y, HPLN, HPLT, WCS=WCS
;
; Inputs      :	X       = Solar X coordinate
;               Y       = Solar Y coordinate
;
; Opt. Inputs :	None.
;
; Outputs     :	HPLN    = Helioprojective-cartesian longitude (Theta_X)
;               HPLT    = Helioprojective-cartesian latitude  (Theta_Y)
;
;               By default, HPLN and HPLT are returned in degrees.
;
; Opt. Outputs:	DISTANCE= The distance of the point from the observer, in the
;                         same units as X and Y.
;
; Keywords    :	SOLZ    = Solar Z coordinate, in the same units as X and Y.  If
;                         not passed, then the points are assumed to be on the
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
;               ARCSECONDS = If set, then HPLN and HPLT are returned in
;                         arcseconds.
;
;               FACTOR  = Returns the conversion factor between data and meters
;
; Calls       :	WCS_CONV_FIND_DSUN, FLAG_MISSING, WCS_CONV_HPC_HPR
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
;               Version 2, 11-Nov-2010, WTT, fix bug masked points behind Sun
;               Version 3, 09-Dec-2011, WTT, updated header.
;
; Contact     :	WTHOMPSON
;-
;
pro wcs_conv_hcc_hpc, x, y, hpln, hplt, distance, solz=solz, wcs=wcs, $
                      arcseconds=arcseconds, nomask=nomask, factor=factor, $
                      _extra=_extra
on_error, 2
;
if n_params() lt 4 then message, $
  'Syntax: WCS_CONV_HCC_HPC, X, Y, HPLN, HPLT  [, DISTANCE ]'
if n_elements(x) eq 0 then message, 'X not defined'
if n_elements(y) ne n_elements(x) then message, $
  'X and Y must have the same number of elements'
;
;  Determine the DSUN and RSUN values.
;
wcs_conv_find_dsun, dsun, rsun, factor, wcs=wcs, _extra=_extra
;
;  If the Z array was not passed, then assume r = Rsun.
;
if n_elements(solz) eq 0 then begin
    z = rsun^2 - x^2 - y^2
    w = where(z lt 0, count)
    if count gt 0 then flag_missing, z, w
    z = sqrt(z)
end else z = solz
;
;  Perform the conversion.
;
zeta = dsun - z
distance = sqrt(x^2 + y^2 + zeta^2)
hpln = atan(x, zeta)
hplt = asin(y / distance)
;
;  If the Z array was passed, then flag as missing any pixels that would be
;  obscured by the solar disk.
;
if (n_elements(solz) ne 0) and (not keyword_set(nomask)) then begin
    wcs_conv_hpc_hpr, hpln, hplt, hrln, hrlt, ang_units='radians', /zero_center
    rho_max = asin(rsun/dsun)
    dmax = dsun * cos(rho_max)
    w = where((hrlt le (rho_max*180.d0/!dpi)) and (distance gt dmax), count)
    if count gt 0 then begin
        flag_missing, hpln, w
        flag_missing, hplt, w
        flag_missing, distance, w
    endif
endif
;
;  Convert the data to degrees (or arcseconds).
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
