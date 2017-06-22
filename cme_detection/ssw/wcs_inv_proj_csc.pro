;+
; Project     :	STEREO
;
; Name        :	WCS_INV_PROJ_CSC
;
; Purpose     :	Inverse of WCS_PROJ_CSC
;
; Category    :	FITS, Coordinates, WCS
;
; Explanation :	This routine is called from WCS_GET_PIXEL to apply the inverse
;               COBE quadrilateralized spherical cube (CSC) projection to
;               convert from celestial coordinates to intermediate relative
;               coordinates.
;
; Syntax      :	WCS_INV_PROJ_CSC, WCS, COORD
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
; History     :	Version 1, 20-Dec-2005, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;
pro wcs_inv_proj_csc, wcs, coord
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
    chi =  mm / nn
    psi = -ll / nn
endif
;
if nface gt 0 then ww = where(face eq 1, nww) else $
  ww = where((ll gt 0) and (ll gt abs(nn)) and (ll gt abs(mm)), nww)
if nww gt 0 then begin
    face[ww] = 1
    thetac[ww] = 0.d0
    phic[ww] = 0.d0
    chi = mm / ll
    psi = nn / ll
endif
;
if nface gt 0 then ww = where(face eq 2, nww) else $
  ww = where((mm gt 0) and (mm gt abs(ll)) and (mm gt abs(nn)), nww)
if nww gt 0 then begin
    face[ww] = 2
    thetac[ww] = 0.d0
    phic[ww] = halfpi
    chi = -ll / mm
    psi =  nn / mm
endif
;
if nface gt 0 then ww = where(face eq 3, nww) else $
  ww = where((ll lt 0) and (-ll gt abs(nn)) and (-ll gt abs(mm)), nww)
if nww gt 0 then begin
    face[ww] = 3
    thetac[ww] = 0.d0
    phic[ww] = !dpi
    chi =  mm / ll
    psi = -nn / ll
endif
;
if nface gt 0 then ww = where(face eq 4, nww) else $
  ww = where((mm lt 0) and (-mm gt abs(ll)) and (-mm gt abs(nn)), nww)
if nww gt 0 then begin
    face[ww] = 4
    thetac[ww] = 0.d0
    phic[ww] = 3.d0 * halfpi
    chi = -ll / mm
    psi = -nn / mm
endif
;
if nface gt 0 then ww = where(face eq 5, nww) else $
  ww = where((nn lt 0) and (-nn gt abs(ll)) and (-nn gt abs(mm)), nww)
if nww gt 0 then begin
    face[ww] = 5
    thetac[ww] = -halfpi
    phic[ww] = 0.d0
    chi = -mm / nn
    psi = -ll / nn
endif
;
w_missing = where((face lt 0) or (face gt 5), n_missing)
;
;  Now that the faces are known, calculate the quad-cube variables.
;
gstar = 1.37484847732d0
capm = 0.004869491981d0
gamma =-0.13161671474d0
omega =-0.159596235474d0
cc = dblarr(3,3)
cc[0,0] = 0.141189631152d0
cc[1,0] = 0.0809701286525d0
cc[0,1] =-0.281528535557d0
cc[2,0] =-0.178251207466d0
cc[1,1] = 0.15384112876d0
cc[0,2] = 0.106959469314d0
dd = [0.0759196200467d0, -0.0217762490699d0]
;
x = dblarr(n_elements(chi))
y = dblarr(n_elements(chi))
for j=0,2 do begin
    for i=0,2 do begin
        x = x + cc[i,j] * chi^(2*i) * psi^(2*j)
        y = y + cc[i,j] * chi^(2*j) * psi^(2*i)
    endfor
endfor
;
x = chi*gstar + chi^3*(1.d0 - gstar) + chi*psi^2*(1.d0-chi^2)* $
  (gamma + (capm - gamma)*chi^2 + (1-psi^2)*x) + $
  chi^3*(1.d0-chi^2)*(omega - (1-chi^2)*poly(chi^2,dd))
y = psi*gstar + psi^3*(1.d0 - gstar) + psi*chi^2*(1.d0-psi^2)* $
  (gamma + (capm - gamma)*psi^2 + (1-chi^2)*y) + $
  psi^3*(1.d0-psi^2)*(omega - (1-psi^2)*poly(psi^2,dd))
;
quarterpi = !dpi / 4.d0
x = phic   + quarterpi * x
y = thetac + quarterpi * y
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
