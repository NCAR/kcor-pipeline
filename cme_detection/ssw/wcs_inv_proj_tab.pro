;+
; Project     :	STEREO
;
; Name        :	WCS_INV_PROJ_TAB
;
; Purpose     :	Inverse of WCS_PROJ_TAB
;
; Category    :	FITS, Coordinates, WCS
;
; Explanation :	This routine is called from WCS_GET_PIXEL to apply the inverse
;               lookup table (TAB) projection to convert from real-world
;               coordinates to intermediate relative coordinates.
;
; Syntax      :	WCS_INV_PROJ_TAB, WCS, COORD
;
; Examples    :	See WCS_GET_PIXEL
;
; Inputs      :	WCS = A World Coordinate System structure, from FITSHEAD2WCS.
;               COORD = The coordinates, e.g. from WCS_GET_COORD.
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
;               Currently, the projection is not applied when more than three
;               axes are linked through the same coordinate table array.
;
;               The EXTVER and EXTLEVEL parameters are not yet enforced.
;
; Side effects:	None.
;
; Prev. Hist. :	None.
;
; History     :	Version 1, 06-Jun-2005, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;
pro wcs_inv_proj_tab, wcs, coord
on_error, 2
;
;  Step through each axis, and check if the axis uses the -TAB projection.
;
n_axis = n_elements(wcs.naxis)
processed = bytarr(n_axis)
for i_axis = 0,n_axis-1 do begin
    ctype = wcs.ctype[i_axis]
    test = strupcase( strmid( ctype, 4, strlen(ctype)-4 ))
    if test eq '-TAB' then begin
;
;  Make sure that the LOOKUP_TABLE structure is present.
;
        if tag_exist(wcs, 'LOOKUP_TABLE') then begin
            coordname = wcs.lookup_table.coordname
            indexname = wcs.lookup_table.indexname
            axisnum   = wcs.lookup_table.axisnum
;
;  See which other axes are associated through the same coordinate array.
;
            ww = where(coordname[i_axis] eq coordname, count)
;
;  Interpolate from the coordinate values to the index values.
;
            test = execute('y = wcs.lookup_table.' + coordname[i_axis])
            case count of
                1: begin
                    y = reform(y)
                    x = reform(coord[i_axis,*])
                    j = dindgen(n_elements(y))
                    x0 = interpol(j,y,x)
                endcase
                else: message, /continue, $
                  'N-dimensional TAB case not supported yet'
            endcase
;
;  If there's an index array, then interpolate from the index values into the
;  intermediate values.
;
            for i=0,count-1 do begin
                test = execute('x = x' + ntrim(axisnum[ww[i]]))
                if indexname[ww[i]] ne '' then begin
                    test = execute('y = wcs.lookup_table.' + indexname[ww[i]])
                    x = interpolate(y-1.d0, x)
                endif
                coord[ww[i],*] = x + 1
            endfor
        endif                   ;Lookup table exists
;
;  Subtract the reference value, whether or not the lookup table was applied.
;
        coord[i_axis,*] = coord[i_axis,*] - wcs.crval[i_axis]
    endif                       ;Dimension uses table projection
endfor                          ;I_AXIS
;
return
end
