;+
; Project     :	STEREO
;
; Name        :	WCS_FIND_TABLE
;
; Purpose     :	Find lookup table information in FITS header
;
; Category    :	FITS, Coordinates, WCS
;
; Explanation :	This procedure extracts lookup table information from a
;               FITS index structure, and adds it to a World Coordinate System
;               structure in a separate LOOKUP_TABLE substructure.
;
;               This routine is normally called from FITSHEAD2WCS.
;
; Syntax      :	WCS_FIND_TABLE, WCS, FILENAME
;
; Examples    :	See fitshead2wcs.pro
;
; Inputs      : WCS      = A WCS structure, from FITSHEAD2WCS.
;               FILENAME = The name of the FITS file.
;
; Opt. Inputs :	None.
;
; Outputs     :	The output is the structure LOOKUP_TABLE, which will contain
;               the following parameters:
;
;                       COORDNAME = String array of names pointing to structure
;                                   tags containing coordinate arrays, one for
;                                   each dimension.  For example, if the value
;                                   is "coord1", then lookup_table.coord1 will
;                                   contain the coordinate array for that
;                                   dimensions.  The name will be blank for
;                                   non-tabular dimensions.
;
;                       INDEXNAME = String array of names pointing to tags
;                                   containing index arrays, if applicable.
;
;                       AXISNUM   = The axis number, starting with 0.
;
;                       COORDn    = The coordinate array(s)
;
;                       INDEXn    = The index array(s), if any
;
; Opt. Outputs:	None.
;
; Keywords    :	None.
;
; Calls       :	TAG_EXIST, FXBOPEN, FXBREAD, FXBCLOSE, REM_TAG, ADD_TAG
;
; Common      :	None.
;
; Restrictions:	Currently, only one FITS header, and one WCS, can be examined
;               at a time.
;
; Side effects:	None.
;
; Prev. Hist. :	None.
;
; History     :	Version 1, 06-Jun-2005, William Thompson, GSFC
;               Version 2, 23-Jun-2005, William Thompson, GSFC
;                       Removed unnecessary paramters from call
;
; Contact     :	WTHOMPSON
;-
;
pro wcs_find_table, wcs, filename
on_error, 2
;
;  Set up the variables to store the information about the table projections.
;
n_axis = n_elements(wcs.naxis)
extname   = strarr(n_axis)
extver    = replicate(1, n_axis)
extlevel  = replicate(1, n_axis)
coordcol  = strarr(n_axis)
indexcol  = strarr(n_axis)
axisnum   = intarr(n_axis)
coordname = strarr(n_axis)
indexname = strarr(n_axis)
i_coord = 0
i_index = 0
;
;  Look for axes using the TAB projection.
;
for i = 0,n_axis-1 do begin
    ctype = strupcase(wcs.ctype[i])
    if strmid(ctype,4,strlen(ctype)-4) eq '-TAB' then begin
;
;  Look for the PS and PV keywords.
;
        if not tag_exist(wcs, 'proj_snames') then begin
            message, /continue, $
              'Required TABLE keywords not found -- not projecting'
            return
        endif
;
        keyword = 'PS' + ntrim(i+1) + '_0'
        w = where(wcs.proj_snames eq keyword, nn)
        if nn eq 0 then begin
            message, /continue, 'Required TABLE keyword ' + keyword + $
              ' not found -- not projecting'
            return
        endif
        extname[i] = wcs.proj_svalues[w[0]]
;
        keyword = 'PS' + ntrim(i+1) + '_1'
        w = where(wcs.proj_snames eq keyword, nn)
        if nn eq 0 then begin
            message, /continue, 'Required TABLE keyword ' + keyword + $
              ' not found -- not projecting'
            return
        endif
        coordcol[i] = wcs.proj_svalues[w[0]]
;
        w = where(wcs.proj_snames eq 'PS'+ntrim(i+1)+'_2', nn)
        if nn ne 0 then indexcol[i] = wcs.proj_svalues[w[0]]
;
        if tag_exist(wcs, 'proj_names') then begin
            w = where(wcs.proj_names eq 'PV'+ntrim(i+1)+'_1', nn)
            if nn ne 0 then extver[i] = wcs.proj_values[w[0]]
        endif
;
        if tag_exist(wcs, 'proj_names') then begin
            w = where(wcs.proj_names eq 'PV'+ntrim(i+1)+'_2', nn)
            if nn ne 0 then extlevel[i] = wcs.proj_values[w[0]]
        endif
;
;  Subtract one from the axis number to convert to IDL notation.
;
        if tag_exist(wcs, 'proj_names') then begin
            w = where(wcs.proj_names eq 'PV'+ntrim(i+1)+'_3', nn)
            if nn ne 0 then axisnum[i] = wcs.proj_values[w[0]] - 1
        endif
;
;  Find any already existing entries with the same values of EXTNAME, EXTVER,
;  EXTLEVEL, and COORDCOL.
;
        w = where((extname[i] eq extname) and (extver[i] eq extver) and $
                  (extlevel[i] eq extlevel) and (coordcol[i] eq coordcol))
        w = min(w)
        if w lt i then coordname[i] = coordname[w] else begin
;
;  If new, read the array from the file.
;
            errmsg = ''
            fxbopen, unit, filename, extname[i], errmsg=errmsg
            if errmsg ne '' then begin
                message, /continue, errmsg
                return
            endif
            fxbread, unit, data, coordcol[i], 1, errmsg=errmsg
            fxbclose, unit
            if errmsg ne '' then begin
                message, /continue, errmsg
                fxbclose, unit
                return
            endif
            i_coord = i_coord + 1
            coordname[i] = 'coord' + ntrim(i_coord)
            test = execute(coordname[i] + ' = data')
        endelse
;
;  Find any already existing entries with the same values of EXTNAME, EXTVER,
;  EXTLEVEL, COORDCOL, and INDEXCOL.
;
        if indexcol[i] ne '' then begin
            w = where((extname[i] eq extname) and (extver[i] eq extver) $
                      and (extlevel[i] eq extlevel) and $
                      (coordcol[i] eq coordcol) and (indexcol[i] eq indexcol))
            w = min(w)
            if w lt i then indexname[i] = indexname[w] else begin
;
;  If new, read the array from the file.
;
                errmsg = ''
                fxbopen, unit, filename, extname[i], errmsg=errmsg
                if errmsg ne '' then begin
                    message, /continue, errmsg
                    return
                endif
                fxbread, unit, data, indexcol[i], 1, errmsg=errmsg
                fxbclose, unit
                if errmsg ne '' then begin
                    message, /continue, errmsg
                    fxbclose, unit
                    return
                endif
                i_index = i_index + 1
                indexname[i] = 'index' + ntrim(i_index)
                test = execute(indexname[i] + ' = data')
            endelse
        endif
    endif                       ;ctype is xxxx-TAB
endfor                          ;Stepping over axes
;
;  If coordinate arrays were created, then create the substructure.
;
if i_coord gt 0 then begin
    command = 'lookup_table = {coordname: coordname, ' + $
      'indexname: indexname, axisnum: axisnum'
    for i=1,i_coord do command = command + ', coord' + ntrim(i) + ': coord' + $
      ntrim(i)
    for i=1,i_index do command = command + ', index' + ntrim(i) + ': index' + $
      ntrim(i)
    command = command + '}'
    test = execute(command)
;
;  Add the LOOKUP_TABLE tag to the WCS structure.
;
    if tag_exist(wcs,'LOOKUP_TABLE',/top_level) then $
      wcs = rem_tag(wcs,'LOOKUP_TABLE')
    wcs = add_tag(wcs, lookup_table, 'LOOKUP_TABLE', /top_level)
;
;  If any of the tabular axes were previously assumed to be spatial, make sure
;  that a spherical projection is not assumed.
;
    tab_index = where(coordname ne '')
    w = where((tab_index eq wcs.ix) or (tab_index eq wcs.iy), count)
    if count gt 0 then wcs.projection = ''
endif
;
end
