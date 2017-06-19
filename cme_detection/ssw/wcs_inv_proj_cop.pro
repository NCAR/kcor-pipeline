;+
; Project     :	STEREO
;
; Name        :	WCS_INV_PROJ_COP
;
; Purpose     :	Inverse of WCS_PROJ_COP
;
; Category    :	FITS, Coordinates, WCS
;
; Explanation :	This routine is called from WCS_GET_PIXEL to apply the inverse
;               conic perspective (COP) projection to convert from celestial
;               coordinates to intermediate relative coordinates.
;
; Syntax      :	WCS_INV_PROJ_COP, WCS, COORD
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
; Side effects:	None.
;
; Prev. Hist. :	None.
;
; History     :	Version 1, 02-Jun-2005, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;
pro wcs_inv_proj_cop, wcs, coord
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
;  Get the conic average angle thetaA, and the angular difference eta.
;
if tag_exist(wcs, 'proj_names', /top_level) then begin
    name = 'PV' + ntrim(wcs.iy+1) + '_1'
    w = where(wcs.proj_names eq name, count)
    if count gt 0 then thetaA = wcs.proj_values[w[0]]
endif
if n_elements(thetaA) eq 0 then begin
    message, /continue, 'ThetaA parameter not passed -- defaulting to 45 deg'
    thetaA = 45
end else if thetaA eq 0 then begin
    message, /continue, 'ThetaA=0 not allowed -- defaulting to 45 deg'
    thetaA = 45
endif
;
eta = 0.d0
if tag_exist(wcs, 'proj_names', /top_level) then begin
    name = 'PV' + ntrim(wcs.iy+1) + '_2'
    w = where(wcs.proj_names eq name, count)
    if count gt 0 then eta = wcs.proj_values[w[0]]
endif
if eta ge 90 then begin
    message, /continue, 'Eta >= 90 not allowed -- defaulting to 0 deg'
    eta = 0
endif
;
;  Get the native longitude (phi0) and latitude (theta0) of the fiducial
;  point.  Look for the PV values from the FITS header.  If not found, use the
;  default values (0,thetaA).
;
phi0 = 0.d0
if tag_exist(wcs, 'proj_names', /top_level) then begin
    name = 'PV' + ntrim(wcs.ix+1) + '_1'
    w = where(wcs.proj_names eq name, count)
    if count gt 0 then phi0 = wcs.proj_values[w[0]]
endif
;
theta0 = thetaA
if tag_exist(wcs, 'proj_names', /top_level) then begin
    name = 'PV' + ntrim(wcs.ix+1) + '_2'
    w = where(wcs.proj_names eq name, count)
    if count gt 0 then theta0 = wcs.proj_values[w[0]]
endif
;
;  If PHI0 and THETA0 are non-standard, then signal an error.
;
if (phi0 ne 0) or (theta0 ne thetaA) then message, /informational, $
      'Non-standard PVi_1 and/or PVi_2 values'
;
;  Convert thetaA, eta, phi0, and theta0 to radians
;
phi0_deg = phi0
phi0   = (!dpi / 180.d0) * phi0
theta0 = (!dpi / 180.d0) * theta0
thetaA = (!dpi / 180.d0) * thetaA
eta    = (!dpi / 180.d0) * eta
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
if delta0 ge theta0 then phip = phi0_deg else phip = 180.d0 + phi0_deg
if tag_exist(wcs, 'proj_names', /top_level) then begin
    w = where(wcs.proj_names eq 'LONPOLE', count)
    if count gt 0 then phip = wcs.proj_values[w[0]]
    name = 'PV' + ntrim(wcs.ix+1) + '_3'
    w = where(wcs.proj_names eq name, count)
    if count gt 0 then phip = wcs.proj_values[w[0]]
endif
phip   = (!dpi / 180.d0) * phip
;
;  Get the native latitude (thetap) of the celestial pole.  Look for the
;  LATPOLE (or PVi_3) keyword.  If not found, use the default value.  Convert
;  to radians.
;
thetap = 90
if tag_exist(wcs, 'proj_names', /top_level) then begin
    w = where(wcs.proj_names eq 'LATPOLE', count)
    if count gt 0 then thetap = wcs.proj_values[w[0]]
    name = 'PV' + ntrim(wcs.ix+1) + '_4'
    w = where(wcs.proj_names eq name, count)
    if count gt 0 then thetap = wcs.proj_values[w[0]]
endif
thetap   = (!dpi / 180.d0) * thetap
;
;  Determine the pole position.
;
if (theta0 eq 0) and (delta0 eq 0) and (abs(phip - phi0) eq halfpi) then begin
    deltap = thetap
end else begin
    deltap0 = atan(sin(theta0), cos(theta0)*cos(phip-phi0))
    test = sin(delta0)/sqrt(1-cos(theta0)^2*sin(phip-phi0)^2)
    if abs(test) gt 1 then message, 'Incompatible projection parameters'
    deltap1 = acos(test)
    deltap  = deltap0 + deltap1
    deltap2 = deltap0 - deltap1
    if abs(deltap)  gt halfpi then deltap  = deltap2
    if abs(deltap2) gt halfpi then deltap2 = deltap
    if abs(deltap-thetap) gt abs(deltap2-thetap) then deltap = deltap2
endelse
;
if deltap eq halfpi then begin
    alphap = alpha0 + phip - phi0 - !dpi
end else if deltap eq -halfpi then begin
    alphap = alpha0 - phip + phi0
end else if abs(delta0) eq halfpi then begin
    alphap = alpha0
end else begin
    das = sin(phip-phi0)*cos(theta0) / cos(delta0)
    dac = (sin(theta0)-sin(deltap)*sin(delta0)) / (cos(deltap)*cos(delta0))
    if (das eq 0) and (dac eq 0) then alphap = alpha0 - !dpi else $
      alphap = alpha0 - atan(das,dac)
endelse
;
;  Convert from celestial to native spherical coordinates.
;
alpha = cx * coord[wcs.ix,*]
delta = cy * coord[wcs.iy,*]
dalpha = alpha - alphap
cos_dalpha = cos(dalpha)
sin_delta  = sin(delta)
cos_delta  = cos(delta)
phi = phip + atan(-cos_delta*sin(dalpha), $
	sin_delta*cos(deltap) - cos_delta*sin(deltap)*cos_dalpha)
theta = asin(sin_delta*sin(deltap) + cos_delta*cos(deltap)*cos_dalpha)
;
;  Calculate the relative coordinates.
;
c = sin(thetaA)
y0 = cos(eta) / tan(thetaA)
twopi = 2.d0 * !dpi
phi = phi mod twopi
w = where(phi gt !dpi, count)
if count gt 0 then phi[w] = phi[w] - twopi
w = where(phi lt -!dpi, count)
if count gt 0 then phi[w] = phi[w] + twopi
r_theta = cos(eta) * (1.d0/tan(thetaA) - tan(theta-thetaA))
x =  r_theta * sin(c*phi)
y = -r_theta * cos(c*phi) + y0
;
;  Convert back into the original units.
;
coord[wcs.ix,*] = x / cx
coord[wcs.iy,*] = y / cy
;
end
