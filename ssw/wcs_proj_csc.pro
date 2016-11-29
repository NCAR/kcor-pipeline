;+
; Project     :	STEREO
;
; Name        :	WCS_PROJ_CSC
;
; Purpose     :	Convert intermediate coordinates in CSC projection.
;
; Category    :	FITS, Coordinates, WCS
;
; Explanation :	This routine is called from WCS_GET_COORD to apply the COBE
;               quadrilateral spherical cube (CSC) projection to intermediate
;               relative coordinates.
;
; Syntax      :	WCS_PROJ_CSC, WCS, COORD
;
; Examples    :	See WCS_GET_COORD
;
; Inputs      :	WCS = A World Coordinate System structure, from FITSHEAD2WCS.
;               COORD = The intermediate coordinates, relative to the reference
;                       pixel (i.e. CRVAL hasn't been applied yet).
;
; Opt. Inputs :	None.
;
; Outputs     :	The projected coordinates are returned in the COORD array.
;
; Opt. Outputs:	None.
;
; Keywords    :	MISSING    = Value to fill missing values with.  If not passed,
;                            then missing values are filled with IEEE
;                            Not-A-Number (NaN) values.
;
; Calls       :	TAG_EXIST, NTRIM
;
; Common      :	None.
;
; Restrictions:	Because this routine is intended to be called only from
;               WCS_GET_COORD, no error checking is performed.
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
pro wcs_proj_csc, wcs, coord, missing=k_missing
on_error, 2
halfpi = !dpi / 2.d0
;
;  Get the MISSING value.
;
if n_elements(k_missing) eq 1 then missing=k_missing else missing=!values.d_nan
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
;  Calculate the native spherical coordinates.
;
x = cx*coord[wcs.ix,*]
y = cy*coord[wcs.iy,*]
;
;  Determine the face parameters.
;
wface = (where(strupcase(wcs.ctype) eq 'CUBEFACE', nface))[0]
if nface gt 0 then face = reform(coord[wface,*]) else $
  face = replicate(-1,n_elements(x))
thetac = dblarr(n_elements(x))
phic = dblarr(n_elements(x))
quarterpi = halfpi / 2.d0
if nface gt 0 then wy = where((face ge 1) and (face le 4), nwy) else $
  wy = where(abs(y) le quarterpi, nwy)
if nwy gt 0 then begin
    xx = x[wy]
    thetac[wy] = 0.d0
;
    if nface gt 0 then wx = where(face[wy] eq 1, nwx) else $
      wx = where(abs(xx) le quarterpi, nwx)
    if nwx gt 0 then begin
        ww = wy[wx]
        face[ww] = 1
        phic[ww] = 0.d0
    endif
;
    if nface gt 0 then wx = where(face[wy] eq 2, nwx) else $
      wx = where((x gt quarterpi) and (x le 3*quarterpi), nwx)
    if nwx gt 0 then begin
        ww = wy[wx]
        face[ww] = 2
        phic[ww] = halfpi
    endif
;
    if nface gt 0 then wx = where(face[wy] eq 3, nwx) else $
      wx = where((x gt 3.d0*quarterpi) and (x le 5.d0*quarterpi), nwx)
    if nwx gt 0 then begin
        ww = wy[wx]
        face[ww] = 3
        phic[ww] = !dpi
    endif
;
    if nface gt 0 then wx = where(face[wy] eq 4, nwx) else $
      wx = where((x gt 5.d0*quarterpi) and (x le 7.d0*quarterpi), nwx)
    if nwx gt 0 then begin
        ww = wy[wx]
        face[ww] = 4
        phic[ww] = 3.d0*halfpi
    endif
;
    if nface eq 0 then begin
        wx = where((x lt -quarterpi) and (x ge -3*quarterpi), nwx)
        if nwx gt 0 then begin
            ww = wy[wx]
            face[ww] = 4
            phic[ww] = -halfpi
        endif
;
        wx = where((x lt -3.d0*quarterpi) and (x ge -5.d0*quarterpi), nwx)
        if nwx gt 0 then begin
            ww = wy[wx]
            face[ww] = 3
            phic[ww] = -!dpi
        endif
;
        wx = where((x lt -5.d0*quarterpi) and (x ge -7.d0*quarterpi), nwx)
        if nwx gt 0 then begin
            ww = wy[wx]
            face[ww] = 2
            phic[ww] = -3.d0*halfpi
        endif
    endif
endif
;
if nface gt 0 then ww = where(face eq 0, nwx) else $
  ww = where((abs(x) lt quarterpi) and (y gt quarterpi) and $
             (y le 3.d0*quarterpi), nww)
if nww gt 0 then begin
    face[ww] = 0
    thetac[ww] = halfpi
    phic[ww] = 0.d0
endif
;
if nface gt 0 then ww = where(face eq 5, nwx) else $
  ww = where((abs(x) lt quarterpi) and (y lt -quarterpi) and $
             (y ge -3.d0*quarterpi), nww)
if nww gt 0 then begin
    face[ww] = 5
    thetac[ww] = -halfpi
    phic[ww] = 0.d0
endif
;
w_missing = where((face lt 0) or (face gt 5), n_missing)
;
;  Now that the faces are known, calculate the quad-cube variables.
;
xx = (x - phic)   / quarterpi
yy = (y - thetac) / quarterpi
pp = dblarr(7,7)
pp[0,0] =-0.27292696d0  &  pp[0,4] = 0.93412077d0
pp[1,0] =-0.07629969d0  &  pp[5,0] = 0.25795794d0
pp[0,1] =-0.02819452d0  &  pp[4,1] = 1.71547508d0
pp[2,0] =-0.22797056d0  &  pp[3,2] = 0.98938102d0
pp[1,1] =-0.01471565d0  &  pp[2,3] =-0.93678576d0
pp[0,2] = 0.27058160d0  &  pp[1,4] =-1.41601920d0
pp[3,0] = 0.54852384d0  &  pp[0,5] =-0.63915306d0
pp[2,1] = 0.48051509d0  &  pp[6,0] = 0.02584375d0
pp[1,2] =-0.56800938d0  &  pp[5,1] =-0.53022337d0
pp[0,3] =-0.60441560d0  &  pp[4,2] =-0.83180469d0
pp[4,0] =-0.62930065d0  &  pp[3,3] = 0.08693841d0
pp[3,1] =-1.74114454d0  &  pp[2,4] = 0.33887446d0
pp[2,2] = 0.30803317d0  &  pp[1,5] = 0.52032238d0
pp[1,3] = 1.50880086d0  &  pp[0,6] = 0.14381585d0
chi = dblarr(n_elements(xx))
psi = dblarr(n_elements(xx))
for j=0,6 do begin
    for i=0,6-j do begin
        chi = chi + pp[i,j] * xx^(2*i) * yy^(2*j)
        psi = psi + pp[i,j] * xx^(2*j) * yy^(2*i)
    endfor
endfor
chi = xx + xx*(1-xx^2)*chi
psi = yy + yy*(1-yy^2)*psi
;
xi = 1.d0 / sqrt(1.d0 + chi^2 + psi^2)
zeta = chi * xi
eta  = psi * xi
;
theta = thetac
phi   = phic
;
w = where(face eq 0, nw)
if nw gt 0 then begin
    theta[w] = asin(xi[w])
    phi[w] = atan(zeta[w],-eta[w])
endif
;
w = where(face eq 1, nw)
if nw gt 0 then begin
    theta[w] = asin(eta[w])
    phi[w] = atan(zeta[w],xi[w])
endif
;
w = where(face eq 2, nw)
if nw gt 0 then begin
    theta[w] = asin(eta[w])
    phi[w] = atan(xi[w],-zeta[w])
endif
;
w = where(face eq 3, nw)
if nw gt 0 then begin
    theta[w] = asin(eta[w])
    phi[w] = atan(-zeta[w],-xi[w])
endif
;
w = where(face eq 4, nw)
if nw gt 0 then begin
    theta[w] = asin(eta[w])
    phi[w] = atan(-xi[w],zeta[w])
endif
;
w = where(face eq 5, nw)
if nw gt 0 then begin
    theta[w] = asin(-xi[w])
    phi[w] = atan(zeta[w],eta[w])
endif
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
;  Calculate the celestial spherical coordinates.
;
if deltap ge halfpi then begin
    alpha = alphap + phi - phip - !dpi
    delta = theta
end else if deltap le -halfpi then begin
    alpha = alphap - phi + phip
    delta = -theta
end else begin
    dphi = phi - phip
    cos_dphi = cos(dphi)
    sin_theta = sin(theta)
    cos_theta = cos(theta)
    alpha = alphap + atan(-cos_theta*sin(dphi), $
        sin_theta*cos(deltap)-cos_theta*sin(deltap)*cos_dphi)
    delta = asin(sin_theta*sin(deltap) + $
                 cos_theta*cos(deltap)*cos_dphi)
endelse
;
;  Make sure that the longitude runs from -180 to +180.
;
w = where(alpha lt -!dpi, count)
if count gt 0 then alpha[w] = alpha[w] + 2.d0 * !dpi
w = where(alpha gt  !dpi, count)
if count gt 0 then alpha[w] = alpha[w] - 2.d0 * !dpi
;
;  Convert back into the original units.
;
coord[wcs.ix,*] = alpha / cx
coord[wcs.iy,*] = delta / cy
;
;  Flag any missing values.
;
if n_missing gt 0 then begin
    coord[wcs.ix, w_missing] = missing
    coord[wcs.iy, w_missing] = missing
endif
;
end
