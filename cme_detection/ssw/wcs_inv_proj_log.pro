;+
; Project     :	STEREO
;
; Name        :	WCS_INV_PROJ_LOG
;
; Purpose     :	Inverse of WCS_PROJ_LOG
;
; Category    :	FITS, Coordinates, WCS
;
; Explanation :	This routine is called from WCS_GET_PIXEL to apply the inverse
;               logarithmic (LOG) projection to convert from real-world
;               coordinates to intermediate relative coordinates.
;
; Syntax      :	WCS_INV_PROJ_LOG, WCS, COORD, I_AXIS
;
; Examples    :	See WCS_GET_PIXEL
;
; Inputs      :	WCS = A World Coordinate System structure, from FITSHEAD2WCS.
;               COORD = The coordinates, e.g. from WCS_GET_COORD.
;               I_AXIS= The axis to apply the de-projection to.
;
; Opt. Inputs :	None.
;
; Outputs     :	The de-projected coordinates are returned in the COORD array.
;
; Opt. Outputs:	None.
;
; Keywords    :	None.
;
; Calls       :	None.
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
; History     :	Version 1, 06-Jun-2005, William Thompson, GSFC
;               Version 2, 18-Mar-2008, WTT, bug fix
;
; Contact     :	WTHOMPSON
;-
;
pro wcs_inv_proj_log, wcs, coord, i_axis
on_error, 2
;
s0 = wcs.crval[i_axis]
coord[i_axis,*] = s0*(alog(coord[i_axis,*]) - alog(s0))
;
end
