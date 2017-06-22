;+
; Project     :	STEREO
;
; Name        :	WCS_INV_PROJ_SZP
;
; Purpose     :	Inverse of WCS_PROJ_SZP
;
; Category    :	FITS, Coordinates, WCS
;
; Explanation :	This routine is called from WCS_GET_PIXEL to apply the inverse
;               slant zenithal perspective (SZP) projection to convert from
;               celestial coordinates to intermediate relative coordinates.
;
; Syntax      :	WCS_INV_PROJ_SZP, WCS, COORD
;
; Examples    :	See WCS_GET_PIXEL
;
; Inputs      :	WCS = A World Coordinate System structure, from FITSHEAD2WCS.
;               COORD = The coordinates, e.g. from WCS_GET_COORD.
;
; Opt. Inputs :	None.
;
; Outputs     :	The de-projected coordinates are returned in the COORD array.
;
; Opt. Outputs:	None.
;
; Keywords    :	None.
;
; Calls       :	TAG_EXIST, NTRIM
;
; Common      :	None.
;
; Restrictions:	Because this routine is intended to be called only from
;               WCS_GET_PIXEL, no error checking is performed.
;
;               This routine is not guaranteed to work correctly if the
;               projection parameters are non-standard.
;
; Side effects:	None.
;
; Prev. Hist. :	None.
;
; History     :	Version 1, 03-Jun-2005, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;
pro wcs_inv_proj_szp, wcs, coord
on_error, 2
halfpi = !dpi / 2.d0
;
;  Calculate the conversion from coordinate units into radians.
;
cx = !dpi / 180.d0
case wcs.cunit[wcs.ix] of
    'arcmin': cx = cx / 60.d0
    'arcsec': cx = cx / 3600.d0
    'mas':    cx = cx / 3600.d3
    'rad':    cx = 1.d0
    else:     cx = cx
endcase
;
cy = !dpi / 180.d0
case wcs.cunit[wcs.iy] of
    'arcmin': cy = cy / 60.d0
    'arcsec': cy = cy / 3600.d0
    'mas':    cy = cy / 3600.d3
    'rad':    cy = 1.d0
    else:     cy = cy
endcase
;
;  Get the native longitude (phi0) and latitude (theta0) of the fiducial
;  point.  Look for the PV values from the FITS header.  If not found, use the
;  default values (0,90).
;
phi0 = 0.d0
if tag_exist(wcs, 'proj_names', /top_level) then begin
    name = 'PV' + ntrim(wcs.ix+1) + '_1'
    w = where(wcs.proj_names eq name, count)
    if count gt 0 then phi0 = wcs.proj_values[w[0]]
endif
;
theta0 = 90.d0
if tag_exist(wcs, 'proj_names', /top_level) then begin
    name = 'PV' + ntrim(wcs.ix+1) + '_2'
    w = where(wcs.proj_names eq name, count)
    if count gt 0 then theta0 = wcs.proj_values[w[0]]
endif
;
;  If PHI0 and THETA0 are non-standard, then signal an error.
;
if (phi0 ne 0) or (theta0 ne 90) then message, /informational, $
      'Non-standard PVi_1 and/or PVi_2 values -- ignored'
;
;  Convert phi0 and theta0 to radians
;
phi0   = (!dpi / 180.d0) * phi0
theta0 = (!dpi / 180.d0) * theta0
;
;  Get the projection source distance mu, and the slant angles phiC and thetaC.
;  If not found, use the default values of 0, 0, and 90 respectively.
;
mu = 0.d0
if tag_exist(wcs, 'proj_names', /top_level) then begin
    name = 'PV' + ntrim(wcs.iy+1) + '_1'
    w = where(wcs.proj_names eq name, count)
    if count gt 0 then mu = wcs.proj_values[w[0]]
endif
;
phiC = 0.d0
if tag_exist(wcs, 'proj_names', /top_level) then begin
    name = 'PV' + ntrim(wcs.iy+1) + '_2'
    w = where(wcs.proj_names eq name, count)
    if count gt 0 then phiC = wcs.proj_values[w[0]]
endif
;
thetaC = 90.d0
if tag_exist(wcs, 'proj_names', /top_level) then begin
    name = 'PV' + ntrim(wcs.iy+1) + '_3'
    w = where(wcs.proj_names eq name, count)
    if count gt 0 then thetaC = wcs.proj_values[w[0]]
endif
;
;  Convert phiC and thetaC to radians.
;
phiC   = (!dpi / 180.d0) * phiC
thetaC = (!dpi / 180.d0) * thetaC
;
;  Get the celestial longitude and latitude of the fiducial point.
;
alpha0 = wcs.crval[wcs.ix] * cx
delta0 = wcs.crval[wcs.iy] * cy
;
;  Get the native longitude (phip) of the celestial pole.  Look for the LONPOLE
;  (or PVi_3) keyword.  If not found, use the default value.  Convert to
;  radians.
;
if delta0 ge theta0 then phip=0 else phip=180
if tag_exist(wcs, 'proj_names', /top_level) then begin
    w = where(wcs.proj_names eq 'LONPOLE', count)
    if count gt 0 then phip = wcs.proj_values[w[0]]
    name = 'PV' + ntrim(wcs.ix+1) + '_3'
    w = where(wcs.proj_names eq name, count)
    if count gt 0 then phip = wcs.proj_values[w[0]]
endif
if (phip ne 180) and (delta0 ne halfpi) then message, /informational, $
  'Non-standard LONPOLE value ' + ntrim(phip)
phip   = (!dpi / 180.d0) * phip
;
;  Convert from celestial to native spherical coordinates.
;
alpha = cx * coord[wcs.ix,*]
delta = cy * coord[wcs.iy,*]
dalpha = alpha - alpha0
cos_dalpha = cos(dalpha)
sin_delta  = sin(delta)
cos_delta  = cos(delta)
phi = phip + atan(-cos_delta*sin(dalpha), $
	sin_delta*cos(delta0) - cos_delta*sin(delta0)*cos_dalpha)
theta = asin(sin_delta*sin(delta0) + cos_delta*cos(delta0)*cos_dalpha)
;
;  Calculate the relative coordinates.
;
xp = -mu * cos(thetaC) * sin(phiC)
yp =  mu * cos(thetaC) * cos(phiC)
zp =  mu * sin(thetaC) + 1.d0
denom = zp - (1 - sin(theta))
w_missing = where(denom eq 0, n_missing)
if n_missing gt 0 then denom[w_missing] = 1
x =  (zp*cos(theta)*sin(phi) - xp*(1-sin(theta))) / denom
y = -(zp*cos(theta)*cos(phi) + yp*(1-sin(theta))) / denom
;
;  Convert back into the original units.
;
coord[wcs.ix,*] = x / cx
coord[wcs.iy,*] = y / cy
;
;  Flag any missing values.
;
if n_missing gt 0 then begin
    coord[wcs.ix, w_missing] = !values.d_nan
    coord[wcs.iy, w_missing] = !values.d_nan
endif
;
end
