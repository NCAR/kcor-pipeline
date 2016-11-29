;+
; Project     :	STEREO
;
; Name        :	WCS_PROJ_LOG
;
; Purpose     :	Convert intermediate coordinates in LOG projection.
;
; Category    :	FITS, Coordinates, WCS
;
; Explanation :	This routine is called from WCS_GET_COORD to apply the
;               logarithmic (LOG) projection to intermediate relative
;               coordinates.
;
; Syntax      :	WCS_PROJ_LOG, WCS, COORD, I_AXIS
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
; History     :	Version 1, 06-Jun-2005, William Thompson, GSFC
;               Version 2, 18-Mar-2008, WTT, bug fix
;
; Contact     :	WTHOMPSON
;-
;
pro wcs_proj_log, wcs, coord, i_axis
on_error, 2
;
s0 = wcs.crval[i_axis]
coord[i_axis,*] = s0*exp(coord[i_axis,*]/s0)
;
end
