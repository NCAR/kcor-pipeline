;+
; Project     :	STEREO
;
; Name        :	WCS_PROJ_V2W
;
; Purpose     :	Convert intermediate coordinates in V2W projection.
;
; Category    :	FITS, Coordinates, WCS
;
; Explanation :	This routine is called from WCS_GET_COORD to apply the
;               velocity-to-wavelength (V2W) projection to intermediate
;               relative coordinates.
;
; Syntax      :	WCS_PROJ_V2W, WCS, COORD, I_AXIS
;
; Examples    :	See WCS_GET_COORD
;
; Inputs      :	WCS = A World Coordinate System structure, from FITSHEAD2WCS.
;               COORD = The intermediate coordinates, relative to the reference
;                       pixel (i.e. CRVAL hasn't been applied yet).
;               I_AXIS= The axis to apply the projection to.
;
; Opt. Inputs :	None.
;
; Outputs     :	The projected coordinates are returned in the COORD array.
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
;               WCS_GET_COORD, no error checking is performed.
;
; Side effects:	None.
;
; Prev. Hist. :	None.
;
; History     :	Version 1, 07-Jun-2005, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;
pro wcs_proj_v2w, wcs, coord, i_axis
on_error, 2
c = 2.99792458D8        ;Speed of light
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
    'WAVE': begin
        if (base_units ne 'm') and (cunit ne '') then begin
            message = 'Illegal units specification ' + cunit
            goto, handle_error
        endif
        p0 = factor * wcs.crval[i_axis]
        dpds = 1.d0
    end
    'VOPT': begin
        if (base_units ne 'm.s^-1') and (cunit ne '') then begin
            message = 'Illegal units specification ' + cunit
            goto, handle_error
        endif
        p0 = restwav * (1.d0 + factor * wcs.crval[i_axis] / c)
        dpds = restwav / c
    endcase
    'ZOPT': begin
        if (base_units ne '') and (cunit ne '') then begin
            message = 'Illegal units specification ' + cunit
            goto, handle_error
        endif
        p0 = restwav * (1.d0 + factor * wcs.crval[i_axis])
        dpds = restwav
    endcase
    else: begin
        message = 'Invalid projection ' + wcs.ctype[i_axis] + ' -- ignored'
        goto, handle_error
    endcase
endcase
;
;  Convert the reference value from the associated variable (p=wavelength) into
;  the sampled variable (x=velocity), and calculate dX/dw = dP/dS / dP/dX
;
x0 = c * (p0^2 - restwav^2) / (p0^2 + restwav^2)
dxdw = dpds * (1.d0 - x0 / c) * sqrt(c^2 - x0^2) / restwav
;
;  Calculate the sampled variable (velocity)
;
x = x0 + dxdw * factor * coord[i_axis,*]
;
;  Convert into the associated variable (wavelength).
;
p = restwav * (c + x) / sqrt(c^2 - x^2)
;
;  Convert into the final spectral coordinate variable.
;
case coord_type of
    'WAVE': s = p
    'VOPT': s = c * (p - restwav) / restwav
    'ZOPT': s = (p - restwav) / restwav
endcase
;
;  Apply the appropriate units conversion, and return.
;
coord[i_axis,*] = s / factor
return
;
;  Error handling point.
;
handle_error:
message, message, /continue
coord[i_axis,*] = coord[i_axis,*] + wcs.crval[i_axis]
;
return
end
