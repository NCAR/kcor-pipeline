;+
; Project     :	STEREO
;
; Name        :	WCS_DECOMP_ANGLE
;
; Purpose     :	Derive a rotation angle from WCS PC or CD matrix.
;
; Category    :	FITS, Coordinates, WCS
;
; Explanation :	This procedure examines the FITS World Coordinate System
;               structure from FITSHEAD2WCS, and tries to decompose the PC or
;               CD matrix into CDELT and CROTA values.
;
; Syntax      :	WCS_DECOMP_ANGLE, WCS, ROLL_ANGLE, CDELT, FOUND
;
; Examples    :	See usage in fitshead2wcs.pro
;
; Inputs      :	WCS = Structure from FITSHEAD2WCS
;
; Opt. Inputs :	None.
;
; Outputs     :	ROLL_ANGLE = Angle consistent with PC or CD matrix, in degrees.
;               CDELT      = Pixel spacing consistent with PC or CD matrix
;               FOUND      = Success code (0 or 1).
;
; Opt. Outputs:	None.
;
; Keywords    :	PRECISION = Precision to be used when determining if the angle
;                           can be successfully derived, and if there are any
;                           significant cross terms involving non-spatial
;                           dimensions.  The default is 1e-5, i.e. the results
;                           should be correct to about 5 significant figures.
;
;               NOXTERMS  = If set, then success is dependent on not having any
;                           cross terms involving non-spatial dimensions.
;
;               ADD_TAGS  = If set, then the ROLL_ANGLE, CDELT tags are added
;                           to the structure.
;
; Calls       :	VALID_WCS
;
; Common      :	None.
;
; Restrictions:	Currently, only one WCS can be examined at a time.
;
; Side effects:	None.
;
; Prev. Hist. :	None.
;
; History     :	Version 1, 13-Apr-2005, William Thompson, GSFC
;               Version 2, 06-Feb-2006, William Thompson, GSFC
;                       Corrected roll sign convention for PC variation
;               Version 3, 12-Sep-2007, William Thompson, GSFC
;                       Corrected CDELT sign convention for PC variation
;               Version 4, 17-Feb-2017, William Thompson, GSFC
;                       Treat special case when off-diagonal elements are very
;                       close to zero but non-symmetric.
;
; Contact     :	WTHOMPSON
;-
;
pro wcs_decomp_angle, wcs, roll_angle, cdelt, found, precision=k_precision, $
                      noxterms=noxterms, add_tags=add_tags
on_error, 2
;
if n_params() ne 4 then message, $
  'Syntax: WCS_DECOMP_ANGLE, WCS, ROLL_ANGLE, CDELT, FOUND'
if not valid_wcs(wcs) then message, 'Input not recognized as WCS structure'
;
;  Determine the precision needed for comparing the derived angles, and for
;  examining the cross terms in the PC or CD matrix.
;
if n_elements(k_precision) eq 1 then prec = abs(k_precision) else prec = 1e-5
if keyword_set(noxterms) then xprec = 0 else xprec = prec
;
;  Act according to the WCS variation.
;
ix = wcs.ix
iy = wcs.iy
naxis = wcs.naxis
n_axis = n_elements(naxis)
variation = strupcase(wcs.variation)
case variation of
;
;  The CROTA variation is straightforward.
;
    'CROTA': begin
        roll_angle = wcs.roll_angle
        cdelt = wcs.cdelt[[ix,iy]]
        found = 1
        return
    endcase
;
;  For the PC variation, first check to see if there are any significant cross
;  terms involving non-spatial dimensions.
;
    'PC': begin
        cdelt = wcs.cdelt
        pc = wcs.pc
        for i=0,n_axis-1 do begin
            for j=0,n_axis-1 do begin
                if (((i ne ix) and (i ne iy)) xor ((j ne ix) and (j ne iy))) $
                  and (i ne j) and (abs(pc[i,j]*naxis[i]) ge xprec) then begin
                    found = 0
                    return
                endif
            endfor
        endfor
;
;  Then form a CD-like array of just the spatial dimensions.
;
        cd = [[cdelt[ix]*pc[ix,ix], cdelt[iy]*pc[iy,ix]], $
              [cdelt[ix]*pc[ix,iy], cdelt[iy]*pc[iy,iy]]]
    endcase
;
;  For the CD variation, first check to see if there are any significant cross
;  terms involving non-spatial dimensions.
;
    'CD': begin
        cd = wcs.cd
        for i=0,n_axis-1 do begin
            for j=0,n_axis-1 do begin
                if (((i ne ix) and (i ne iy)) xor ((j ne ix) and (j ne iy))) $
                  and (i ne j) and $
                  (abs(cd[i,j]*naxis[j]) ge abs(xprec*cd[i,i])) and $
                  (abs(cd[i,j]*naxis[i]) ge abs(xprec*cd[j,j])) then begin
                    found = 0
                    return
                endif
            endfor
        endfor
;
;  Then extract the part of the array referring to the spatial dimensions.
;
        cd = [[cd[ix,ix],cd[iy,ix]], [cd[ix,iy],cd[iy,iy]]]
    endcase
endcase
;
;  Process the CD-like matrix to estimate the rotation angle.
;
if cd[1,0] gt 0 then begin
    rho_a = atan(cd[1,0], cd[0,0])
end else if cd[1,0] lt 0 then begin
    rho_a = atan(-cd[1,0],-cd[0,0])
end else rho_a = 0
if cd[0,1] gt 0 then begin
    rho_b = atan(cd[0,1],-cd[1,1])
end else if cd[0,1] lt 0 then begin
    rho_b = atan(-cd[0,1],cd[1,1])
end else rho_b = 0
;
;  If one angle is within the expected precision of 0 degrees, and the other
;  angle is within the expected precision of 180 degrees, then flip one by 180
;  degrees.
;
if (abs(rho_a) le prec) and (abs(rho_b-!dpi) le prec) then rho_b = rho_b - !dpi
if (abs(rho_a-!dpi) le prec) and (abs(rho_b) le prec) then rho_a = rho_a - !dpi
;
;  If the two angles match within the expected precision, then derive the
;  decomposed ROLL_ANGLE and CDELT.  For the CD variation, the non-spatial
;  CDELT values are taken from the diagonal elements of the CD matrix.
;
if abs(rho_a-rho_b) le prec then begin
    roll_angle = (rho_a + rho_b) / 2
    if variation eq 'CD' then begin
        cdelt = dblarr(n_axis)
        for i=0,n_axis-1 do cdelt[i] = wcs.cd[i,i]
    endif
    if cd[0,0] ne 0 then $
      cdelt[ix] = cd[0,0] / cos(roll_angle) else $
      cdelt[ix] = cd[1,0] / sin(roll_angle)
    if cd[1,1] ne 0 then $
      cdelt[iy] = cd[1,1] / cos(roll_angle) else $
      cdelt[iy] = -cd[0,1] / sin(roll_angle)
    roll_angle = roll_angle * 180.d0 / !dpi
    found = 1
end else found = 0
;
;  If the PC variation is used, and the roll angle would change the sign of the
;  CDELT values, then add 180 degrees to the roll angle.
;
if found and (variation eq 'PC') then begin
    test = cdelt * wcs.cdelt
    if (test[ix] lt 0) or (test[iy] lt 0) then begin
        roll_angle = roll_angle - sign(180.d0, roll_angle)
        cdelt = -cdelt
    endif
endif
;
;  Add the appropriate tags, if applicable.
;
if found and keyword_set(add_tags) then begin
    if tag_exist(wcs,'ROLL_ANGLE',/top_level) then $
      wcs.roll_angle = roll_angle else $
      wcs = add_tag(wcs,roll_angle,'ROLL_ANGLE',/top_level)
    if variation eq 'CD' then begin
        if tag_exist(wcs,'CDELT',/top_level) then wcs.cdelt = cdelt else $
          wcs = add_tag(wcs,cdelt,'CDELT',/top_level)
    endif
endif
;
return
end
