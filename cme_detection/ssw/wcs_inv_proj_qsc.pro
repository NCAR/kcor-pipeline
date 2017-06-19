;+
; Project     :	STEREO
;
; Name        :	WCS_INV_PROJ_QSC
;
; Purpose     :	Inverse of WCS_PROJ_QSC
;
; Category    :	FITS, Coordinates, WCS
;
; Explanation :	This routine is called from WCS_GET_PIXEL to apply the inverse
;               quadrilateralized spherical cube (QSC) projection to convert
;               from celestial coordinates to intermediate relative
;               coordinates.
;
; Syntax      :	WCS_INV_PROJ_QSC, WCS, COORD
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
; History     :	Version 1, 21-Dec-2005, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;
pro wcs_inv_proj_qsc, wcs, coord
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
;  default values (0,0).
;
phi0 = 0.d0
if tag_exist(wcs, 'proj_names', /top_level) then begin
    name = 'PV' + ntrim(wcs.ix+1) + '_1'
    w = where(wcs.proj_names eq name, count)
    if count gt 0 then phi0 = wcs.proj_values[w[0]]
endif
;
theta0 = 0.d0
if tag_exist(wcs, 'proj_names', /top_level) then begin
    name = 'PV' + ntrim(wcs.ix+1) + '_2'
    w = where(wcs.proj_names eq name, count)
    if count gt 0 then theta0 = wcs.proj_values[w[0]]
endif
;
;  If PHI0 and THETA0 are non-standard, then signal an error.
;
if (phi0 ne 0) or (theta0 ne 0) then message, /informational, $
      'Non-standard PVi_1 and/or PVi_2 values'
;
;  Convert phi0 and theta0 to radians
;
phi0_deg = phi0
phi0   = (!dpi / 180.d0) * phi0
theta0 = (!dpi / 180.d0) * theta0
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
;  Calculate the relative coordinates.  Start by calculating the direction
;  cosines.
;
ll = cos(theta)*cos(phi)
mm = cos(theta)*sin(phi)
nn = sin(theta)
;
;  Determine the face parameters.
;
wface = (where(strupcase(wcs.ctype) eq 'CUBEFACE', nface))[0]
if nface gt 0 then face = reform(coord[wface,*]) else $
  face = replicate(-1,n_elements(ll))
thetac = dblarr(n_elements(ll))
phic = dblarr(n_elements(ll))
;
if nface gt 0 then ww = where(face eq 0, nww) else $
  ww = where((nn gt 0) and (nn gt abs(ll)) and (nn gt abs(mm)), nww)
if nww gt 0 then begin
    face[ww] = 0
    thetac[ww] = halfpi
    phic[ww] = 0.d0
    zeta =  mm
    eta  = -ll
    xi   =  nn
endif
;
if nface gt 0 then ww = where(face eq 1, nww) else $
  ww = where((ll gt 0) and (ll gt abs(nn)) and (ll gt abs(mm)), nww)
if nww gt 0 then begin
    face[ww] = 1
    thetac[ww] = 0.d0
    phic[ww] = 0.d0
    zeta =  mm
    eta  =  nn
    xi   =  ll
endif
;
if nface gt 0 then ww = where(face eq 2, nww) else $
  ww = where((mm gt 0) and (mm gt abs(ll)) and (mm gt abs(nn)), nww)
if nww gt 0 then begin
    face[ww] = 2
    thetac[ww] = 0.d0
    phic[ww] = halfpi
    zeta = -ll
    eta  =  nn
    xi   =  mm
endif
;
if nface gt 0 then ww = where(face eq 3, nww) else $
  ww = where((ll lt 0) and (-ll gt abs(nn)) and (-ll gt abs(mm)), nww)
if nww gt 0 then begin
    face[ww] = 3
    thetac[ww] = 0.d0
    phic[ww] = !dpi
    zeta = -mm
    eta  =  nn
    xi   = -ll
endif
;
if nface gt 0 then ww = where(face eq 4, nww) else $
  ww = where((mm lt 0) and (-mm gt abs(ll)) and (-mm gt abs(nn)), nww)
if nww gt 0 then begin
    face[ww] = 4
    thetac[ww] = 0.d0
    phic[ww] = 3.d0 * halfpi
    zeta =  ll
    eta  =  nn
    xi   = -mm
endif
;
if nface gt 0 then ww = where(face eq 5, nww) else $
  ww = where((nn lt 0) and (-nn gt abs(ll)) and (-nn gt abs(mm)), nww)
if nww gt 0 then begin
    face[ww] = 5
    thetac[ww] = -halfpi
    phic[ww] = 0.d0
    zeta =  mm
    eta  =  ll
    xi   = -nn
endif
;
w_missing = where((face lt 0) or (face gt 5), n_missing)
;
;  Now that the faces are known, calculate the quad-cube variables.
;
quarterpi = !dpi / 4.d0
deg15 = !dpi / 12.d0
w1 = where(abs(zeta) gt abs(eta), n1, complement=w2, ncomplement=n2)
omega = dblarr(n_elements(zeta))
if n1 gt 0 then omega[w1] =  eta[w1] / zeta[w1]
if n2 gt 0 then omega[w2] = zeta[w1] /  eta[w1]
ss = replicate(quarterpi, n_elements(zeta))
ww = where((zeta le abs(eta)) and (eta lt abs(zeta)), nn)
if nn gt 0 then ss[ww] = -quarterpi
x = ss * sqrt((1.d0-xi) / (1.d0 - 1.d0/sqrt(2.d0 + omega^2)))
y = (x/deg15) * (atan(omega) - asin(omega / sqrt(2.d0*(1.d0+omega^2))))
ww = where(abs(x) le abs(y), nn)
if nn gt 0 then begin
    temp = x[ww]
    x[ww] = y[ww]
    y[ww] = temp
endif
x = x + phic
y = y + thetac
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
