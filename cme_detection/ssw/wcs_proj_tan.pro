;+
; Project     :	STEREO
;
; Name        :	WCS_PROJ_TAN
;
; Purpose     :	Convert intermediate coordinates in TAN projection.
;
; Category    :	FITS, Coordinates, WCS
;
; Explanation :	This routine is called from WCS_GET_COORD to apply the gnomonic
;               (TAN) projection to intermediate relative coordinates.
;
; Syntax      :	WCS_PROJ_TAN, WCS, COORD
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
; Keywords    :	QUICK      = If set, do a quick approximate calculation rather
;                            than a full-blown spherical projection.  Different
;                            approximations are used for helioprojective-
;                            cartesian and -radial coordinates.
;
;               FORCE_PROJ = This routine has logic which skips the
;                            calculation of the spherical projection when the
;                            pixels are within 3 degrees of the Sun.  Using
;                            /FORCE_PROJ forces the full spherical coordinate
;                            transformation to be calculated.
;
; Calls       :	TAG_EXIST, NTRIM
;
; Common      :	None.
;
; Restrictions:	Because this routine is intended to be called only from
;               WCS_GET_COORD, no error checking is performed.
;
;               This routine is not guaranteed to work correctly if the
;               projection parameters are non-standard.
;
; Side effects:	None.
;
; Prev. Hist. :	None.
;
; History     :	Version 1, 19-Apr-2005, William Thompson, GSFC
;               Version 2, 19-May-2005, William Thompson, GSFC
;                       Corrected bug when single pixel passed.
;
; Contact     :	WTHOMPSON
;-
;
pro wcs_proj_tan, wcs, coord, quick=k_quick, force_proj=force_proj
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
;  Get the maximum and minimum coordinates.  If the image doesn't go beyond 3
;  degrees from disk center, don't bother to calculate the projection.
;
quick = keyword_set(k_quick)
if not keyword_set(force_proj) then begin
    if wcs.coord_type eq 'Helioprojective-Radial' then begin
        ymin = min(coord[wcs.iy,*], max=ymax)
        yrange = ([ymin,ymax]  + wcs.crval[wcs.iy]) * cy + halfpi
        if max(abs(yrange)) le 3*!dtor then quick = 1
    end else begin
        xmin = min(coord[wcs.ix,*], max=xmax)
        xrange = ([xmin,xmax] + wcs.crval[wcs.ix]) * cx
        ymin = min(coord[wcs.iy,*], max=ymax)
        yrange = ([ymin,ymax] + wcs.crval[wcs.iy]) * cy
        if max([abs(xrange),abs(yrange)]) le 3*!dtor then quick = 1
    endelse
endif
;
;  If the QUICK option was selected, then don't do the full spherical
;  projection.
;
if keyword_set(quick) and (not keyword_set(force_proj)) then begin
    if wcs.coord_type eq 'Helioprojective-Radial' then begin
        x = coord[wcs.ix,*] * cx
        y = (coord[wcs.iy,*] + wcs.crval[wcs.iy]) * cy + halfpi
        coord[wcs.ix,*] = wcs.crval[wcs.ix] + atan(x,y) / cx
        coord[wcs.iy,*] = (sqrt(x^2 + y^2) - halfpi) / cy
    end else begin
        coord[wcs.ix,*] = coord[wcs.ix,*] + wcs.crval[wcs.ix]
        coord[wcs.iy,*] = coord[wcs.iy,*] + wcs.crval[wcs.iy]
    endelse
    return
endif
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
;  Calculate the native spherical coordinates.
;
phi = atan(cx*coord[wcs.ix,*],-cy*coord[wcs.iy,*])
theta = sqrt((cx*coord[wcs.ix,*])^2 + (cy*coord[wcs.iy,*])^2)
w0 = where(theta eq 0, n0, complement=w1, ncomplement=n1)
if n0 gt 0 then theta[w0] = halfpi
if n1 gt 0 then theta[w1] = atan(1.d0 / theta[w1])
;
;  Calculate the celestial spherical coordinates.
;
if delta0 ge halfpi then begin
    alpha = alpha0 + phi - phip - !dpi
    delta = theta
end else if delta0 le -halfpi then begin
    alpha = alpha0 - phi + phip
    delta = -theta
end else begin
    dphi = phi - phip
    cos_dphi = cos(dphi)
    sin_theta = sin(theta)
    cos_theta = cos(theta)
    alpha = alpha0 + atan(-cos_theta*sin(dphi), $
        sin_theta*cos(delta0)-cos_theta*sin(delta0)*cos_dphi)
    delta = asin(sin_theta*sin(delta0) + $
                 cos_theta*cos(delta0)*cos_dphi)
endelse
;
;  Convert back into the original units.
;
coord[wcs.ix,*] = alpha / cx
coord[wcs.iy,*] = delta / cy
;
end
