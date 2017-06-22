;+
; Project     :	STEREO
;
; Name        :	WCS_INV_PROJ_F2A
;
; Purpose     :	Inverse of WCS_PROJ_F2A
;
; Category    :	FITS, Coordinates, WCS
;
; Explanation :	This routine is called from WCS_GET_PIXEL to apply the inverse
;               frequency-to-air-wavelength (F2A) projection to convert from
;               spectral coordinates to intermediate relative coordinates.
;
; Syntax      :	WCS_INV_PROJ_F2A, WCS, COORD, I_AXIS
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
pro wcs_inv_proj_f2a, wcs, coord, i_axis
on_error, 2
c = 2.99792458D8        ;Speed of light
param = [287.6155d0,  1.62887d-12,  0.01360d-24]
pder  = [287.6155d0, -1.62887d-12, -0.04080d-24]
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
;  Convert the reference value into the associated variable type, and get the
;  derivative dP/dS at the reference point.
;
case coord_type of
    'AWAV': begin
        if (base_units ne 'm') and (cunit ne '') then begin
            message = 'Illegal units specification ' + cunit
            goto, handle_error
        endif
        p0 = factor * wcs.crval[i_axis]
        dpds = 1.d0
    end
    else: begin
        message = 'Invalid projection ' + wcs.ctype[i_axis] + ' -- ignored'
        goto, handle_error
    endcase
endcase
;
;  Convert the reference value from the associated variable (p=air wavelength)
;  into the sampled variable (x=frequency), and calculate dX/dw
;
l0 = p0 * (1.d0 + 1.d-6 * (param[0] + param[1]/p0^2 + param[2]/p0^4))
x0 = c / l0
dxdw = -dpds * x0^2 / c * $
  (1.d0 + 1.d-6 * (pder[0] + pder[1]/p0^2 + pder[2]/p0^4))
;
;  Apply the appropriate units conversion.
;
p = factor * coord[i_axis,*]
;
;  Convert into the sampled variable (frequency)
;
x = c / (p * (1.d0 + 1.d-6 * (param[0] + param[1]/p^2 + param[2]/p^4)))
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
