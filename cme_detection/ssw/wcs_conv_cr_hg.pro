;+
; Project     :	STEREO
;
; Name        :	WCS_CONV_CR_HG
;
; Purpose     :	Convert Heliographic Carrington to Stonyhurst coordinates
;
; Category    :	Coordinates, WCS
;
; Explanation : This routine converts Heliographic (HG) Carrington longitude
;               into Stonyhurst longitude.
;
; Syntax      :	WCS_CONV_CR_HG, CRLN, HGLN
;
; Examples    :	WCS_CONV_CR_HG, CRLN, HGLN, WCS=WCS
;
; Inputs      :	CRLN    = Carrington-Heliographic longitude
;
; Opt. Inputs :	None.
;
; Outputs     :	HGLN    = Stonyhurst-Heliographic longitude
;
; Opt. Outputs:	None.
;
; Keywords    :	WCS     = World Coordinate System structure.  Used to determine
;                         B0, L0, and the units of the data.  See
;                         WCS_CONV_FIND_HG_ANGLES for more information
;
;               ANG_UNITS = String describing the input angular units.  See
;                           WCS_CONV_FIND_ANG_UNITS for more information.
;
;               POS_LONG = If set, then force the output longitude to be
;                         positive, i.e. between 0 and 360 degrees.  The
;                         default is to return values between +/- 180 degrees.
;
; Calls       :	WCS_CONV_FIND_ANG_UNITS, WCS_CONV_FIND_HG_ANGLES
;
; Common      :	None.
;
; Restrictions:	None.
;
; Side effects: None.
;
; Prev. Hist. :	None.
;
; History     :	Version 1, 12-Dec-2008, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;
pro wcs_conv_cr_hg, crln, hgln, wcs=wcs, pos_long=pos_long, _extra=_extra
on_error, 2
;
if n_params() ne 2 then message, $
  'Syntax: WCS_CONV_CR_HG, CRLN, HGLN'
if n_elements(crln) eq 0 then message, 'CRLN not defined'
;
;  Determine the conversion factor between the data and degrees, and convert
;  the data into degrees.
;
wcs_conv_find_ang_units, cx, cy, wcs=wcs, type='Stonyhurst-Heliographic', $
  /to_degrees
hgln = cx * crln
;
;  Get the L0 angles for both Stonyhurst and Carrington coordinates.
;
wcs_conv_find_hg_angles, b0, hgln0, wcs=wcs, carrington=0, _extra=_extra
wcs_conv_find_hg_angles, b0, crln0, wcs=wcs, carrington=1, _extra=_extra
;
;  Calculate the difference, and apply it to the longitude.
;
hgln = hgln - (crln0 - hgln0)
w = where(hgln lt (-180), count)
if count gt 0 then hgln[w] = hgln[w] + 360
w = where(hgln gt 180, count)
if count gt 0 then hgln[w] = hgln[w] - 360
;
;  If /POS_LONG is set, then add 360 degrees to negative longitude
;  values.
;
if keyword_set(pos_long) then begin
    w = where(hgln lt 0, count)
    if count gt 0 then hgln[w] = hgln[w] + 360
endif
;
;  Convert back to the original units.
;
if cx ne 1 then hgln = hgln / cx
;
return
end
