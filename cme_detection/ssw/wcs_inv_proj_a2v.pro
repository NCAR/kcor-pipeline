;+
; Project     :	STEREO
;
; Name        :	WCS_INV_PROJ_A2V
;
; Purpose     :	Inverse of WCS_PROJ_A2V
;
; Category    :	FITS, Coordinates, WCS
;
; Explanation :	This routine is called from WCS_GET_PIXEL to apply the inverse
;               air-wavelength-to-velocity (A2V) projection to convert from
;               spectral coordinates to intermediate relative coordinates.
;
; Syntax      :	WCS_INV_PROJ_A2V, WCS, COORD, I_AXIS
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
; History     :	Version 1, 08-Jun-2005, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;
pro wcs_inv_proj_a2v, wcs, coord, i_axis
on_error, 2
c = 2.99792458d8        ;Speed of light
h = 6.6260693d-34       ;Planck constant
param = [287.6155d0,  1.62887d-12,  0.01360d-24]
pder  = [287.6155d0, -1.62887d-12, -0.04080d-24]
;
;  Get the final variable type.
;
coord_type = strupcase( strmid(wcs.ctype[i_axis], 0, 4) )
;
;  Get the rest wavelength.  All the projections require this.
;
restwav = 0
if tag_exist(wcs,'spectrum') then begin
    if tag_exist(wcs.spectrum, 'RESTWAV') then $
      restwav=wcs.spectrum.restwav
endif
if restwav eq 0 then begin
    message = 'Rest wavelength not available -- ignoring projection'
    goto, handle_error
endif
;
;  Parse the units specification.
;
cunit = wcs.cunit[i_axis]
wcs_parse_units, cunit, base_units, factor
;
;  Convert the reference value into the associated variable type, and get the
;  derivative dP/dS at the reference point.
;
case coord_type of
    'VELO': begin
        if (base_units ne 'm.s^-1') and (cunit ne '') then begin
            message = 'Illegal units specification ' + cunit
            goto, handle_error
        endif
        p0 = factor * wcs.crval[i_axis]
        dpds = 1.d0
    end
    'BETA': begin
        if (base_units ne '') and (cunit ne '') then begin
            message = 'Illegal units specification ' + cunit
            goto, handle_error
        endif
        p0 = factor * wcs.crval[i_axis] * c
        dpds = c
    endcase
    else: begin
        message = 'Invalid projection ' + wcs.ctype[i_axis] + ' -- ignored'
        goto, handle_error
    endcase
endcase
;
;  Convert the reference value from the associated variable (p=velocity) into
;  the sampled variable (x=air wavelength), and calculate dX/dw = dP/dS / dP/dX
;
l0 = restwav * (c + p0) / sqrt(c^2 - p0^2)
x0 = l0 / (1.d0 + 1.d-6 * (param[0] + param[1]/l0^2 + param[2]/l0^4))
dxdw = dpds * (l0^2 + restwav^2)^2 / (4.d0 * c * l0 * restwav^2) / $
  (1.d0 + 1.d-6 * (pder[0] + pder[1]/l0^2 + pder[2]/l0^4))
;
;  Apply the appropriate units conversion.
;
s = factor * coord[i_axis,*]
;
;  Convert into the assocated variable (velocity).
;
case coord_type of
    'VELO': p = s
    'BETA': p = s * c
endcase
;
;  Convert into the sampled variable (air wavelength)
;
l = restwav * (c + p) / sqrt(c^2 - p^2)
x = l / (1.d0 + 1.d-6 * (param[0] + param[1]/l^2 + param[2]/l^4))
;
;  Calculate the intermediate relative values.
;
w = (x - x0) / dxdw
;
;  Apply the appropriate units conversion, and return.
;
coord[i_axis,*] = w / factor
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
