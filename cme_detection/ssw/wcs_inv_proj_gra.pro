;+
; Project     :	STEREO
;
; Name        :	WCS_INV_PROJ_GRA
;
; Purpose     :	Inverse of WCS_PROJ_GRA
;
; Category    :	FITS, Coordinates, WCS
;
; Explanation :	This routine is called from WCS_GET_PIXEL to apply the inverse
;               grism-in-air (GRA) projection to convert from spectral
;               coordinates to intermediate relative coordinates.
;
; Syntax      :	WCS_INV_PROJ_GRA, WCS, COORD, I_AXIS
;
; Examples    :	See WCS_GET_PIXEL
;
; Inputs      :	WCS = A World Coordinate System structure, from FITSHEAD2WCS.
;               COORD = The coordinates, e.g. from WCS_GET_COORD.
;               I_AXIS= The axis to apply the projection to.
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
; History     :	Version 1, 07-Jun-2005, William Thompson, GSFC
;               Version 2, 18-Mar-2008, WTT, fixed bug finding GRISM values
;
; Contact     :	WTHOMPSON
;-
;
pro wcs_inv_proj_gra, wcs, coord, i_axis
on_error, 2
c = 2.99792458d8        ;Speed of light
h = 6.6260693d-34       ;Planck constant
param = [287.6155d0,  1.62887d-12,  0.01360d-24]
pder  = [287.6155d0, -1.62887d-12, -0.04080d-24]
;
;  Get the grism parameters.
;
g = 0.d0
if tag_exist(wcs, 'proj_names', /top_level) then begin
    name = 'PV' + ntrim(i_axis+1) + '_0'
    w = where(wcs.proj_names eq name, count)
    if count gt 0 then g = wcs.proj_values[w[0]]
endif
;
m = 0.d0
if tag_exist(wcs, 'proj_names', /top_level) then begin
    name = 'PV' + ntrim(i_axis+1) + '_1'
    w = where(wcs.proj_names eq name, count)
    if count gt 0 then m = wcs.proj_values[w[0]]
endif
;
alpha = 0.d0
if tag_exist(wcs, 'proj_names', /top_level) then begin
    name = 'PV' + ntrim(i_axis+1) + '_2'
    w = where(wcs.proj_names eq name, count)
    if count gt 0 then alpha = wcs.proj_values[w[0]]
endif
alpha = alpha * !dpi / 180.d0
;
nr = 1.d0
if tag_exist(wcs, 'proj_names', /top_level) then begin
    name = 'PV' + ntrim(i_axis+1) + '_3'
    w = where(wcs.proj_names eq name, count)
    if count gt 0 then nr = wcs.proj_values[w[0]]
endif
;
nrprime = 0.d0
if tag_exist(wcs, 'proj_names', /top_level) then begin
    name = 'PV' + ntrim(i_axis+1) + '_4'
    w = where(wcs.proj_names eq name, count)
    if count gt 0 then nrprime = wcs.proj_values[w[0]]
endif
;
epsilon = 0.d0
if tag_exist(wcs, 'proj_names', /top_level) then begin
    name = 'PV' + ntrim(i_axis+1) + '_5'
    w = where(wcs.proj_names eq name, count)
    if count gt 0 then epsilon = wcs.proj_values[w[0]]
endif
epsilon = epsilon * !dpi / 180.d0
;
theta = 0.d0
if tag_exist(wcs, 'proj_names', /top_level) then begin
    name = 'PV' + ntrim(i_axis+1) + '_6'
    w = where(wcs.proj_names eq name, count)
    if count gt 0 then theta = wcs.proj_values[w[0]]
endif
theta = theta * !dpi / 180.d0
;
;  Simplify into the independent variables.
;
gme = g * m / cos(epsilon)
nra = nr * sin(alpha)
nraprime = nrprime * sin(alpha)
;
;  Get the final variable type.
;
coord_type = strupcase( strmid(wcs.ctype[i_axis], 0, 4) )
;
;  Parse the units specification.
;
cunit = wcs.cunit[i_axis]
wcs_parse_units, cunit, base_units, factor
;
;  Get the reference wavelength, and the derivative needed to calculate
;  dGamma/dw at the reference point.  The distinction between vacuum and air
;  wavelengths will be handled further down.
;
case coord_type of
    'FREQ': begin
        if (base_units ne 's^-1') and (cunit ne '') then begin
            message = 'Illegal units specification ' + cunit
            goto, handle_error
        endif
        nu0 = factor * wcs.crval[i_axis]
        lambda0 = c / nu0
        deriv = -c / nu0^2
    end
    'ENER': begin
        if (base_units ne 'kg.m^2.s^-2') and (cunit ne '') then begin
            message = 'Illegal units specification ' + cunit
            goto, handle_error
        endif
        nu0 = factor * wcs.crval[i_axis] / h
        lambda0 = c / nu0
        deriv = -c * h / nu0^2
    endcase
    'WAVN': begin
        if (base_units ne 'm^-1') and (cunit ne '') then begin
            message = 'Illegal units specification ' + cunit
            goto, handle_error
        endif
        kappa0 = factor * wcs.crval[i_axis]
        lambda0 = 1.d0 / kappa0
        deriv = -1.d0 / (c * kappa0)^2
    endcase
    'VRAD': begin
        if (base_units ne 'm.s^-1') and (cunit ne '') then begin
            message = 'Illegal units specification ' + cunit
            goto, handle_error
        endif
        restfrq = 0
        if tag_exist(wcs,'spectrum') then begin
            if tag_exist(wcs.spectrum, 'RESTFRQ') then $
              restfrq = wcs.spectrum.restfrq
        endif
        if restfrq eq 0 then begin
            message = 'Rest frequency not available -- ignoring projection'
            goto, handle_error
        endif
        v0 = factor * wcs.crval[i_axis]
        nu0 = restfrq * (1.d0 - v0 / c)
        lambda0 = c / nu0
        deriv = restfrq / nu0^2
    endcase
    'WAVE': begin
        if (base_units ne 'm') and (cunit ne '') then begin
            message = 'Illegal units specification ' + cunit
            goto, handle_error
        endif
        lambda0 = factor * wcs.crval[i_axis]
        deriv = 1.d0
    endcase
    'VOPT': begin
        if (base_units ne 'm.s^-1') and (cunit ne '') then begin
            message = 'Illegal units specification ' + cunit
            goto, handle_error
        endif
        restwav = 0
        if tag_exist(wcs,'spectrum') then begin
            if tag_exist(wcs.spectrum, 'RESTWAV') then $
              restwav=wcs.spectrum.restwav
        endif
        if restwav eq 0 then begin
            message = 'Rest wavelength not available -- ignoring projection'
            goto, handle_error
        endif
        z0 = factor * wcs.crval[i_axis]
        lambda0 = restwav * (1.d0 + z0 / c)
        deriv = restwav / c
    endcase
    'ZOPT': begin
        if (base_units ne '') and (cunit ne '') then begin
            message = 'Illegal units specification ' + cunit
            goto, handle_error
        endif
        restwav = 0
        if tag_exist(wcs,'spectrum') then begin
            if tag_exist(wcs.spectrum, 'RESTWAV') then $
              restwav=wcs.spectrum.restwav
        endif
        if restwav eq 0 then begin
            message = 'Rest wavelength not available -- ignoring projection'
            goto, handle_error
        endif
        z0 = factor * wcs.crval[i_axis]
        lambda0 = restwav * (1.d0 + z0)
        deriv = restwav
    endcase
    'AWAV': begin
        if (base_units ne 'm') and (cunit ne '') then begin
            message = 'Illegal units specification ' + cunit
            goto, handle_error
        endif
        lambda0 = factor * wcs.crval[i_axis]
        deriv = 1.d0
    endcase
    'VELO': begin
        if (base_units ne 'm.s^-1') and (cunit ne '') then begin
            message = 'Illegal units specification ' + cunit
            goto, handle_error
        endif
        restwav = 0
        if tag_exist(wcs,'spectrum') then begin
            if tag_exist(wcs.spectrum, 'RESTWAV') then $
              restwav=wcs.spectrum.restwav
        endif
        if restwav eq 0 then begin
            message = 'Rest wavelength not available -- ignoring projection'
            goto, handle_error
        endif
        v0 = factor * wcs.crval[i_axis]
        lambda0 = restwav * (c + v0) / sqrt(c^2 - v0^2)
        deriv = c * restwav / ((c - v0) * sqrt(c^2 - v0^2))
    end
    'BETA': begin
        if (base_units ne '') and (cunit ne '') then begin
            message = 'Illegal units specification ' + cunit
            goto, handle_error
        endif
        restwav = 0
        if tag_exist(wcs,'spectrum') then begin
            if tag_exist(wcs.spectrum, 'RESTWAV') then $
              restwav=wcs.spectrum.restwav
        endif
        if restwav eq 0 then begin
            message = 'Rest wavelength not available -- ignoring projection'
            goto, handle_error
        endif
        v0 = factor * wcs.crval[i_axis] * c
        lambda0 = restwav * (c + v0) / sqrt(c^2 - v0^2)
        deriv = c^2 * restwav / ((c - v0) * sqrt(c^2 - v0^2))
    endcase
    else: begin
        message = 'Invalid projection ' + wcs.ctype[i_axis] + ' -- ignored'
        goto, handle_error
    endcase
endcase
;
;  Unless the coordinate type is AWAV, correct for the distinction between
;  vacuum and air wavelengths.
;
if coord_type ne 'AWAV' then begin
    lambda0 = lambda0 / $
      (1.d0 + 1.d-6 * (param[0] + param[1]/lambda0^2 + param[2]/lambda0^4))
    deriv = deriv * $
      (1.d0 + 1.d-6 * (pder[0] + pder[1]/lambda0^2 + pder[2]/lambda0^4))
endif
;
;  Calculate the reference angle gamma_r, and the derivative dGamma/dw.
;
gamma0 = gme * lambda0 - nra
if abs(gamma0) le 1 then gamma0 = asin(gamma0) else begin
    message = 'Incompatible grism parameters -- not projecting'
    goto, handle_error
endelse
denom = cos(gamma0) * cos(theta)^2
if denom eq 0 then begin
    message = 'Incompatible grism parameters -- not projecting'
    goto, handle_error
endif
dgdw = deriv * (gme - nraprime) / denom
;
;  Apply the appropriate units conversion.
;
s = factor * coord[i_axis,*]
;
;  Convert into wavelength.
;
case coord_type of
    'FREQ': lambda = c / s
    'ENER': lambda = h * c / s
    'WAVN': lambda = 1.d0 / s
    'VRAD': lambda = c / (restfrq * (1.d0 - s / c))
    'WAVE': lambda = s
    'VOPT': lambda = restwav * (1.d0 + s / c)
    'ZOPT': lambda = restwav * (1.d0 + s)
    'AWAV': lambda = s
    'VELO': lambda = restwav * (c + s) / sqrt(c^2 - s^2)
    'BETA': lambda = restwav * (1.d0 + s) / sqrt(1.d0 - s^2)
endcase
;
;  Unless the coordinate type is AWAV, correct for the distinction between
;  vacuum and air wavelengths.
;
if coord_type ne 'AWAV' then lambda = lambda / $
      (1.d0 + 1.d-6 * (param[0] + param[1]/lambda^2 + param[2]/lambda^4))
;
;  From wavelength, calculate the grism parameter.
;
denom = gme - nraprime
if denom eq 0 then begin
    message = 'Incompatible grism parameters -- not projecting'
    goto, handle_error
endif
gamma = denom*lambda - nra + nraprime*lambda0
w_missing = where(abs(gamma) gt 1, n_missing)
gamma = asin(-1.d0 > gamma < 1.d0)
gamma = tan(gamma - gamma0 - theta)
;
;  Calculate the intermediate relative values.
;
w = (gamma + tan(theta)) / dgdw
;
;  Apply the appropriate units conversion.
;
coord[i_axis,*] = w /factor
;
;  Flag any missing values.
;
if n_missing gt 0 then coord[i_axis, w_missing] = !values.d_nan
return
;
;  Error handling point.
;
handle_error:
message, message, /continue
coord[i_axis,*] = coord[i_axis,*] - wcs.crval[i_axis]
;
return
end
