;+
; Project     :	STEREO
;
; Name        :	FITSHEAD2WCS()
;
; Purpose     :	Extract WCS data from FITS header
;
; Category    :	FITS, Coordinates, WCS
;
; Explanation :	This procedure examines the FITS header (or index structure),
;               and extracts the embedded World Coordinate System information.
;
; Syntax      :	WCS = FITSHEAD2WCS( HEADER )
;
; Examples    :	FXREAD, FILENAME, DATA, HEADER
;               WCS = FITSHEAD2WCS( HEADER )
;
; Inputs      :	HEADER = Either a FITS header, or an index structure from
;                        FITSHEAD2STRUCT.
;
; Opt. Inputs :	None.
;
; Outputs     :	WCS = Structure containing World Coordinate System
;                     information, including the following tags:
;
;                   COORD_TYPE= The type of coordinate system, which is one of
;                               the following:
;
;                               Helioprojective-Cartesian (default if angular)
;                               Heliocentric-Cartesian (if not angular)
;                               Heliocentric-Radial (only if labels HCPA,SOLI)
;                               Helioprojective-Radial
;                               Stonyhurst-Heliographic
;                               Carrington-Heliographic
;
;                               Celestial-Equatorial
;                               Celestial-Galactic
;                               Celestial-Ecliptic
;                               Celestial-Helioecliptic
;                               Celestial-Supergalactic
;
;                   WCSNAME   = The WCSNAME keyword from the FITS header.  If
;                               not found, then will be the same as COORD_TYPE.
;                   VARIATION = Either 'PC', 'CD', or 'CROTA'
;                   COMPLIANT = True if all required WCS keywords found.
;                               Having COMPLIANT=0 doesn't mean that the
;                               returned WCS structure is wrong, but it does
;                               mean that some of the information was inferred,
;                               rather than read directly.
;                   PROJECTION= The coordinate projection.  Default is 'TAN'
;                               for angular coordinates, blank otherwise.
;                   NAXIS     = The array dimensions.
;                   IX        = IDL index for the longitude (X) dimension.
;                               Note that the IDL index is 1 less than the FITS
;                               index.  For example, if the header had the
;                               keyword "CTYPE1='HPLN-TAN'", then IX=0.
;                   IY        = IDL index for the latitude (Y) dimension.
;                               The default is IX=0, IY=1.
;                   CRPIX     = Reference pixels.  Note that these are in FITS
;                               notation, which is 1 higher than IDL notation.
;                               The reference pixel may also be fractional,
;                               e.g. 10.5, and may be outside the array bounds.
;                   CRVAL     = Reference values.
;                   CTYPE     = Axis type, e.g. 'HPLN-TAN'
;                   CNAME     = Character string describing axis, free form.
;                   CUNIT     = Axis units, e.g. 'arcsec'
;                   SIMPLE    = True if the WCS can be described as simple.
;                               See wcs_simple.pro for details.
;
;                     The presence of the following keywords depends on whether
;                     the header uses the PC, CD, or CROTA variation.
;
;                   CDELT     = Axis scale.  May be omitted if VARIATION='CD'.
;                   PC        = Transformation matrix (CD or CROTA).
;                   CD        = Alternate transformation matrix (CD only).
;                   ROLL_ANGLE= Coordinate rotation angle.  Always present for
;                               CROTA cases.  May also be present if PC or CD
;                               matrix can be decomposed into a rotation angle.
;
;                     The following keywords may be present, depending on the
;                     FITS header.
;
;                   PROJ_NAMES  = Names of additional keywords associated with
;                                 the projection, e.g. LONPOLE, PV2_1.  The
;                                 SYSTEM character, if any, is stripped off.
;                   PROJ_VALUES = Array of values associated with PROJ_NAMES.
;
;                     The structure may also contain the following
;                     substructures for TIME and POSITION information.
;
;                   TIME        = Substructure of time values.  See
;                                 wcs_find_time.pro for more information.
;                   POSITION    = Substructure of position values.  See
;                                 wcs_find_position.pro for more information.
;
; Opt. Outputs:	None.
;
; Keywords    :	SYSTEM  = Selects which alternate coordinate system should be
;                         used.  See wcs_find_system.pro for more information.
;
;               MINIMAL = If set, then only a minimal WCS is generated, to save
;                         processing time.  Used by INDEX2MAP.
;
;               COLUMN  = Binary table column name or number.
;
;               FILENAME= Used with headers containing the -TAB projection, so
;                         that the lookup tables can be read.
;
;               LUNFXB  = The logical unit number returned by FXBOPEN,
;                         pointing to the binary table that the header
;                         refers to.  Usage of this keyword allows
;                         implementation of the "Greenbank Convention",
;                         where keywords can be replaced with columns of
;                         the same name.  It's also needed for tables
;                         containing "iVn_Xa" or "iPVn_Xa" columns, and for
;                         tables containing pixel lists.
;
;               ROWFXB  = Used in conjunction with LUNFXB, to give the
;                         row number in the table.  Default is 1.
;
;               PIXEL_LIST = If set, then look for pixel list information in
;                            the binary table.  Used in conjunction with
;                            LUNFXB, but does not require ROWFXB.
;
;               NOPROJECTION = If set, do not automatically default to the TAN
;                              projection.  Generally used for heliographic
;                              coordinates with non-standard axis labels.
;
;               ERRMSG	= If defined and passed, then any error messages will
;			  be returned to the user in this parameter rather than
;			  depending on the MESSAGE routine in IDL.  If no
;			  errors are encountered, then a null string is
;			  returned.  In order to use this feature, ERRMSG must
;			  be defined first, e.g.
;
;				ERRMSG = ''
;				WCS = FITSHEAD2WCS( HEADER, ERRMSG=ERRMSG, ...)
;				IF ERRMSG NE '' THEN ...
;
;               The following keywords are passed to WCS_DECOMP_ANGLE.
;
;               PRECISION = Precision to be used when determining if the angle
;                           can be successfully derived, and if there are any
;                           significant cross terms involving non-spatial
;                           dimensions.  The default is 1E-4, i.e. the results
;                           should be correct to about 4 significant figures.
;
;               NOXTERMS  = If set, then success is dependent on not having any
;                           cross terms involving non-spatial dimensions.
;
; Calls       :	DATATYPE, GET_FITS_PAR, IS_STRING, WCS_FIND_SYSTEM,
;               BOOST_ARRAY, VALID_NUM, WCS_FIND_KEYWORD, WCS_DECOMP_ANGLE,
;               WCS_SIMPLE, WCS_FIND_TIME, WCS_FIND_POSITION, WCS_FIND_SPECTRUM
;
; Common      :	None.
;
; Restrictions:	Currently only supports one FITS header at a time.  Binary
;               tables are not yet supported.
;
; Notes       : The PC and CD matrices are ordered by row and column.  The
;               following examples show how they are applied.
;
;                       IJ = [I,J]      ;IDL Pixel coordinates
;                       XY = CDELT * (PC # (IJ + 1 - CRPIX)) + CRVAL
;
;               or
;
;                       XY = (CD # (IJ + 1 - CRPIX)) + CRVAL
;
;               Note that the +1 in the equations above takes care of the
;               one-pixel offset between the IDL and FITS pixel notations.
;
;               With spherical map projections, CRVAL is applied as part of the
;               projection, rather than added in as above.
;
; Side effects:	If the FITS file doesn't contain CTYPE keywords, then either
;               HPLN-TAN/HPLT-TAN (angles) or SOLX/SOLY (distances) are assumed
;               for the first two axes.
;
; Prev. Hist. :	None.
;
; History     :	Version 1, 22-Apr-2005, William Thompson, GSFC
;               Version 2, 25-Apr-2005, William Thompson, GSFC
;                       Handle case where header doesn't have NAXIS.
;               Version 3, 26-Apr-2005, William Thompson, GSFC
;                       Add keyword ERRMSG -- use when no NAXIS
;                       Roll angle doesn't need to be present if zero
;               Version 4, 03-Jun-2005, William Thompson, GSFC
;                       Improved logic of what assumptions to make
;               Version 5, 08-Jun-2005, William Thompson, GSFC
;                       Add call to WCS_FIND_SPECTRUM
;                       Add CNAME, Add PS keywords
;               Version 6, 14-Jun-2005, William Thompson, GSFC
;                       Add support for the lookup table projection
;               Version 7, 23-Jun-2005, William Thompson, GSFC
;                       Add support for binary tables
;                       Fixed bug with calculation of PC from CROTA
;               Version 8, 06-Feb-2006, William Thompson, GSFC
;                       Fixed bug reading PC,CD matrices for alternate systems
;               Version 9, 1-Mar-2006, William Thompson, GSFC
;                       Exit gracefully if no axes found.
;               Version 9, 15-Mar-2006, William Thompson, GSFC
;                       Fix some common units strings errors
;               Version 10, 12-Mar-2006, William Thompson, GSFC
;                       Added keyword PIXEL_LIST
;               Version 11, 18-Mar-2008, WTT, Call ID_UNESC to unescape tags
;                       Fixed bug for binary tables.
;               Version 12, 10-Dec-2008, WTT, add support for
;                       Heliocentric-Radial based on HCPA and SOLI type labels
;               Version 13, 07-Oct-2009, WTT, added keyword NOPROJECTION
;                       Don't default to TAN for heliographic coordinates.
;               Version 14, 07-Apr-2010, WTT, default to TAN only for HPC
;               Version 15, 18-Aug-2010, WTT, pass keywords to WCS_FIND_POSITION
;               Version 16, 22-Jun-2011, WTT, fix bug using XCEN,YCEN and
;                      default values of DX, DY.  Don't use XCEN,YCEN if CRPIX
;                      values are present, and don't assume the center of the
;                      array if CRVAL is present.
;
; Contact     :	WTHOMPSON
;-
;
function fitshead2wcs, header, system=k_system, minimal=minimal, $
                       errmsg=errmsg, column=k_column, filename=filename, $
                       lunfxb=lunfxb, rowfxb=rowfxb, pixel_list=pixel_list, $
                       noprojection=noprojection, _extra=_extra
on_error, 2
if n_params() ne 1 then begin
    message = 'Syntax: WCS = FITSHEAD2WCS( HEADER )'
    goto, handle_error
endif
;
;  Make sure that HEADER is a structure, and extract the tag names.
;
case datatype(header,1) of
    'String': index = fitshead2struct(header)
    'Structure': index = header
    else: begin
        message = 'HEADER must be either a string or a structure'
        goto, handle_error
    endcase
endcase
tags = id_unesc(strupcase(tag_names(index)))
;
;  If the COLUMN keyword was passed, then look for the column.
;
if n_elements(k_column) eq 1 then begin
    if datatype(k_column,1) eq 'String' then begin
        test = strupcase( strtrim(k_column, 2) )
        w = where(strmid(tags,0,5) eq 'TTYPE', count)
        if count eq 0 then begin
            message = 'Binary table column ' + test + ' not found'
            goto, handle_error
        endif
        ttype = strarr(count)
        for i=0,count-1 do ttype[i] = strupcase( strtrim(index.(w[i]),2) )
        w = where(ttype eq test, count)
        if count eq 0 then begin
            message = 'Binary table column ' + test + ' not found'
            goto, handle_error
        end else begin
            ttype = ttype[w[0]]
            column = strmid(ttype,5,strlen(ttype)-5)
        endelse
    end else begin
        column = ntrim(k_column)
        w = where(tags eq 'TFORM'+ntrim(column), count)
        if count eq 0 then begin
            message = 'Binary table column ' + ntrim(column) + ' not found'
            goto, handle_error
        endif
    endelse
;
;  Parse some information about the column.
;
    message = ''
    case datatype(header,1) of
        'String': sheader = header
        'Structure': sheader = struct2fitshead(header)
    endcase
    fxbtform, sheader, fxb_tbcol, fxb_idltype, fxb_format, fxb_numval, $
      fxb_maxval, errmsg=message
    if message ne '' then goto, handle_error
;
;  If the coordinate system cross-reference system is used, then find the
;  corresponding column.
;
    orig_column = column
    if not is_string(k_system) then system = '' else $
      system = wcs_find_system(index, k_system, column=column)
    val = wcs_find_keyword(index, tags, column, system, count, '', 'WCSX', $
                           lunfxb=lunfxb, rowfxb=rowfxb)
    if count gt 0 then begin
        cross_ref = val[0]
        val = wcs_find_keyword(index, tags, '*', system, count, '', 'WCST', $
                               lunfxb=lunfxb, rowfxb=rowfxb, names=names)
        if count gt 0 then begin
            w = where(names eq cross_ref, nn)
            if nn gt 0 then begin
                name = names[w[0]]
                colnum = strmid(name,4,strlen(name)-4-strlen(system))
                if valid_num(colnum) then begin
                    orig_column = column
                    column = colnum
                end else message, /continue, $
                  'Unable to parse cross-reference ' + cross_ref
            end else message, /continue, $
              'Unable to find cross-reference ' + cross_ref
        end else message, /continue, 'No WCSTn' + system + ' keywords found'
    endif
end else begin
    column = ''
    orig_column = ''
endelse
;
;  Determine which coordinate system to look for.
;
if not is_string(k_system) then system = '' else $
  system = wcs_find_system(index, k_system, column=column)
;
;  Assume the WCS is valid (i.e. complete) until one starts having to make
;  assumptions.
;
compliant = 1
;
;  Determine the number of WCS axes, either from the NAXIS keyword (or TDIM for
;  binary tables), or from a WCSAXES keyword.  Also store the size of each
;  axis, which may include extra axes at the end with dimensions of 1, if the
;  WCSAXES keyword is set.
;
if column eq '' then begin
    if tag_exist(index, 'NAXIS', /top_level) then n_axis = index.naxis else $
      begin
        message = 'NAXIS keyword not found'
        goto, handle_error
    endelse
    w = where(tags eq 'WCSAXES'+system, count)
    if count gt 0 then n_axis = index.(w[0])
;
;  If no axes were found, then exit gracefully.
;
    if n_axis le 0 then begin
        message = 'No axes found'
        if n_elements(errmsg) eq 0 then errmsg = ''
        goto, handle_error
    endif
;
    naxis = replicate(1L, n_axis)
    for i=1,n_axis do begin
        w = where(tags eq 'NAXIS'+ntrim(i), count)
        if count gt 0 then naxis[i-1] = index.(w[0])
    endfor
end else begin
    val = wcs_find_keyword(index, tags, orig_column, '', count, '', 'TDIM', $
                           lunfxb=lunfxb, rowfxb=rowfxb)
    if count gt 0 then begin
        tdim = fxbtdim(val[0])
        n_axis = n_elements(tdim)
    end else begin
        n_axis = 1
        tdim = fxb_numval > fxb_maxval
    endelse
    val = wcs_find_keyword(index, tags, column, system, count, '', 'WCAX', $
                           lunfxb=lunfxb, rowfxb=rowfxb)
    if count gt 0 then n_axis = val[0]
    naxis = replicate(1L, n_axis)
    naxis[0] = tdim
endelse
;
;  Get some defaults to apply later.
;
if (column ne '') or (n_axis lt 2) then begin
    xcen = 0.0
    ycen = 0.0
    dx = 1.0
    dy = 1.0
    roll = 0.0
end else get_fits_par, index, xcen, ycen, dx, dy, roll=roll
;
;  Determine what kind of WCS is to be extracted.  There are three
;  possibilities:
;
;       1.  PC matrix with CDELT keywords (but not CROTA)
;       2.  CD matrix (CDELT and CROTA are ignored, if present)
;       3.  One or more CROTA keywords.  These keywords may not be interpreted
;           correctly if the data array has more than two axes.
;
;  A header with both a PC matrix and one or more CROTA keywords is marked as
;  invalid.  If none of these variations are found, then CROTA is assumed.
;
crota_present = 0
pc_present = 0
cd_present = 0
for i=1,n_axis do begin
    if system ne '' then begin
        val = wcs_find_keyword(index, tags, column, '', count, $
          'CROTA'+ntrim(i), ntrim(i)+'CROT', lunfxb=lunfxb, rowfxb=rowfxb)
        crota_present = crota_present or (count ge 1)
    endif
    for j=1,n_axis do begin
        val = wcs_find_keyword(index, tags, column, system, count, $
          'PC' + ntrim(i) + '_' + ntrim(j), ntrim(i) + ntrim(j) + 'PC', $
          lunfxb=lunfxb, rowfxb=rowfxb)
        pc_present = pc_present or (count gt 0)
        val = wcs_find_keyword(index, tags, column, system, count, $
          'CD' + ntrim(i) + '_' + ntrim(j), ntrim(i) + ntrim(j) + 'CD', $
          lunfxb=lunfxb, rowfxb=rowfxb)
        cd_present = cd_present or (count gt 0)
    endfor
endfor
if pc_present then begin
    variation = 'PC'
    if crota_present then compliant = 0
end else if cd_present then begin
    variation = 'CD'
end else variation = 'CROTA'
;
;  Extract the CTYPE keywords, and determine which axis is longitude (X), and
;  which is latitude (Y).  If CTYPE is not found, then assume that the first
;  axis is SOLARX, and the second axis is SOLARY, using the old-style
;  notation.  This may be changed further down.
;
ctype = strarr(n_axis)
ctype_assumed = bytarr(n_axis)
for i=1,n_axis do begin
    val = wcs_find_keyword(index, tags, column, system, count, $
      'CTYPE' + ntrim(i), ntrim(i) + ['CTYP','CTY'], lunfxb=lunfxb, $
      rowfxb=rowfxb)
    if count gt 0 then ctype[i-1] = strupcase(val[0]) else begin
        compliant = 0
        case i of
            1: begin
                ctype[i-1] = 'SOLARX'
                ctype_assumed[i-1] = 1
            endcase
            2: begin
                ctype[i-1] = 'SOLARY'
                ctype_assumed[i-1] = 1
            endcase
            else: ctype[i-1] = ''
        endcase
    endelse
endfor
ctype_prefix = strmid(ctype,0,4)
w = where((strmid(ctype,1,4) eq 'LON-') or (strmid(ctype,2,3) eq 'LN-') or $
          (strmid(ctype,0,4) eq 'HECX') or (strmid(ctype,0,4) eq 'HCPA') or $
          (ctype eq 'SOLARX') or (ctype eq 'SOLAR-X') or $
          (ctype eq 'SOLAR_X') or (ctype eq 'SOLX'), count)
if count gt 0 then ix = w[0] else begin
    compliant = 0
    ix = 0
endelse
w = where((strmid(ctype,1,4) eq 'LAT-') or (strmid(ctype,2,3) eq 'LT-') or $
          (strmid(ctype,0,4) eq 'HECY') or (strmid(ctype,0,4) eq 'SOLI') or $
          (ctype eq 'SOLARY') or (ctype eq 'SOLAR-Y') or $
          (ctype eq 'SOLAR_Y') or (ctype eq 'SOLY'), count)
if count gt 0 then iy = w[0] else begin
    compliant = 0
    iy = (ix+1) mod n_axis
endelse
;
;  Extract the expected WCS keywords.  If the WCS keywords are not found, then
;  signal that the WCS is not valid (i.e. not complete), and use an alternate
;  interpretation.
;
crpix = dblarr(n_axis)
crval = dblarr(n_axis)
cunit = strarr(n_axis)
cunit_assumed = bytarr(n_axis)
cname = strarr(n_axis)
for i=1,n_axis do begin
;
;  If neither CRPIX nor CRVAL is found, then use the center of the array.
;  Otherwise, the default is 0.
;
    crp = wcs_find_keyword(index, tags, column, system, pixcount, $
      'CRPIX' + ntrim(i), ntrim(i) + ['CRPX','CRP'], lunfxb=lunfxb, $
      rowfxb=rowfxb)
    val = wcs_find_keyword(index, tags, column, system, count, $
      'CRVAL' + ntrim(i), ntrim(i) + ['CRVL','CRV'], lunfxb=lunfxb, $
      rowfxb=rowfxb)
    if pixcount gt 0 then crpix[i-1] = crp[0] else begin
        compliant = 0
        if count eq 0 then crpix[i-1] = (naxis[i-1] + 1.d0) / 2.d0
    endelse
;
;  If both CRPIX and CRVAL are not found, use XCEN,YCEN for the longitude and
;  latitude dimensions.  Otherwise, the default is 0.
;
    if count gt 0 then crval[i-1] = val[0] else begin
        compliant = 0
        if pixcount eq 0 then begin
            if i eq (ix+1) then crval[i-1] = xcen
            if i eq (iy+1) then crval[i-1] = ycen
        endif
    endelse
;
;  If CUNIT is not found, then assume degrees.  Further down, this may be
;  changed to arcseconds.
;
    val = wcs_find_keyword(index, tags, column, system, count, $
      'CUNIT' + ntrim(i), ntrim(i) + ['CUNI','CUN'], lunfxb=lunfxb, $
      rowfxb=rowfxb)
    if count gt 0 then cunit[i-1] = val[0] else begin
        compliant = 0
        if i le 2 then begin
            cunit[i-1] = 'deg'
            cunit_assumed[i-1] = 1
        endif
    endelse
;
;  Look for optional CNAME values.
;
    val = wcs_find_keyword(index, tags, column, system, count, $
      'CNAME' + ntrim(i), ntrim(i) + ['CNAM','CNA'], lunfxb=lunfxb, $
      rowfxb=rowfxb)
    if count gt 0 then cname[i-1] = val[0]
endfor
;
;  Correct non-compliant units strings.
;
w = where(strlowcase(strmid(cunit,0,3)) eq 'deg', count)
if count gt 0 then cunit[w] = 'deg'
w = where(strlowcase(strmid(cunit,0,6)) eq 'arcmin', count)
if count gt 0 then cunit[w] = 'arcmin'
w = where(strlowcase(strmid(cunit,0,6)) eq 'arcsec', count)
if count gt 0 then cunit[w] = 'arcsec'
;
;  Extract those keywords whose presence depends on which WCS variation was
;  used.
;
case variation of
    'PC': begin
        cdelt = dblarr(n_axis)
        pc = dblarr(n_axis,n_axis)
        for i=1,n_axis do begin
;
;  If CDELT was not found, then use the default values DX,DY for the longitude
;  and latitude dimensions.  Otherwise, the default is 1.
;
            cdelt[i-1] = 1
            val = wcs_find_keyword(index, tags, column, system, count, $
              'CDELT' + ntrim(i), ntrim(i) + ['CDLT','CDE'], lunfxb=lunfxb, $
              rowfxb=rowfxb)
            if count gt 0 then cdelt[i-1] = val[0] else begin
                compliant = 0
                if i eq (ix+1) then cdelt[i-1] = dx
                if i eq (iy+1) then cdelt[i-1] = dy
            endelse
;
;  The default for the PC matrix is 1 along the diagonal, and 0 elsewhere.  The
;  absence of a PC matrix does not make the WCS invalid.
;
            pc[i-1,i-1] = 1
            for j=1,n_axis do begin
                val = wcs_find_keyword(index, tags, column, system, count, $
                  'PC'+ntrim(i)+'_'+ntrim(j), ntrim(i)+ntrim(j)+'PC', $
                  lunfxb=lunfxb, rowfxb=rowfxb)
                if count gt 0 then pc[i-1,j-1] = val[0]
            endfor
        endfor
    endcase                     ;PC variation
;
;  There are no defaults for the CD matrix.
;
    'CD': begin
        cd = dblarr(n_axis,n_axis)
        for i=1,n_axis do begin
            for j=1,n_axis do begin
                val = wcs_find_keyword(index, tags, column, system, count, $
                  'CD'+ntrim(i)+'_'+ntrim(j), ntrim(i)+ntrim(j)+'CD', $
                  lunfxb=lunfxb, rowfxb=rowfxb)
                if count gt 0 then cd[i-1,j-1] = val[0]
            endfor
        endfor
    endcase                     ;CD variation
;
;  If one or more CROTA keywords are found, then the first one is used to
;  generate a PC matrix applied to the spatial axes.
;
    'CROTA': begin
        if crota_present then begin
            crota = dblarr(n_axis)
            crota_found = bytarr(n_axis)
            for i=1,n_axis do begin
                val = wcs_find_keyword(index, tags, column, '', count, $
                                       'CROTA'+ntrim(i), ntrim(i)+'CROT', $
                                       lunfxb=lunfxb, rowfxb=rowfxb)
                if count gt 0 then begin
                    crota[i-1] = val[0]
                    crota_found[i-1] = 1
                endif
            endfor
;
;  Check the CROTA values for consistency.  Normally, one uses the value from
;  the latitude (Y) axis.
;
            w = where(crota_found eq 1, count)
            if crota_found[iy] then roll_angle = crota[iy] else $
              roll_angle = crota[w[0]]
            crota_valid = 1
            if count gt 1 then for i=1,count-1 do $
              if crota[w[i]] ne roll_angle then begin
                compliant = 0
                crota_valid = 0
            endif
        end else begin                  ;From GET_FITS_PAR
            compliant = roll eq 0
            roll_angle = roll
        endelse
;
;  The CDELT keywords are treated the same as in the PC variation.
;
        cdelt = dblarr(n_axis)
        for i=1,n_axis do begin
            cdelt[i-1] = 1
            val = wcs_find_keyword(index, tags, column, system, count, $
                  'CDELT' + ntrim(i), ntrim(i) + ['CDLT','CDE'], $
                  lunfxb=lunfxb, rowfxb=rowfxb)
            if count gt 0 then cdelt[i-1] = val[0] else begin
                compliant = 0
                if i eq (ix+1) then cdelt[i-1] = dx
                if i eq (iy+1) then cdelt[i-1] = dy
            endelse
        endfor
;
;  Generate a PC matrix based on the rotation angle.
;
        pc = dblarr(n_axis,n_axis)
        for i=0,n_axis-1 do pc[i,i] = 1
        if n_axis gt 1 then begin
            if (cdelt[ix] eq 0) or (cdelt[iy] eq 0) then $
              compliant = 0 else begin
                lambda = cdelt[iy] / cdelt[ix]
                cos_a = cos(roll_angle * !dpi / 180.d0)
                sin_a = sin(roll_angle * !dpi / 180.d0)
                pc[ix,ix] = cos_a
                pc[ix,iy] = -lambda * sin_a
                pc[iy,ix] = sin_a / lambda
                pc[iy,iy] = cos_a
            endelse
        endif
    endcase                     ;CROTA variation
endcase
;
;  Determine what kind of coordinate system is being used, and the projection,
;  based on the CTYPE values.  The default is helioprojective-cartesian with
;  the TAN projection.
;
prefix = strupcase(strmid(ctype[ix],0,4))
case prefix of
    'HPLN': coord_type = 'Helioprojective-Cartesian'
    'HRLN': coord_type = 'Helioprojective-Radial'
    'HGLN': coord_type = 'Stonyhurst-Heliographic'
    'CRLN': coord_type = 'Carrington-Heliographic'
    'RA--': coord_type = 'Celestial-Equatorial'
    'GLON': coord_type = 'Celestial-Galactic'
    'ELON': coord_type = 'Celestial-Ecliptic'
    'HLON': coord_type = 'Celestial-Helioecliptic'
    'SLON': coord_type = 'Celestial-Supergalactic'
    else:   if (prefix eq 'HCPA') and $
      (strupcase(strmid(ctype[iy],0,4)) eq 'SOLI') then $
      coord_type = 'Heliocentric-Radial' else begin
        unit = strmid(strupcase(cunit[ix]),0,3)
        if (unit eq 'ARC') or (unit eq 'DEG') or (unit eq 'MAS') or $
          (unit eq 'RAD') then coord_type = 'Helioprojective-Cartesian' else $
          coord_type = 'Heliocentric-Cartesian'
    endelse
endcase
;
;  Check to see if the X and Y axes have the same projection.  If so, then
;  store it in the structure.
;
if strmid(ctype[ix],4,1) eq '-' then $
  projectionx = strupcase(strmid(ctype[ix],5,3)) else projectionx = ''
if strmid(ctype[iy],4,1) eq '-' then $
  projectiony = strupcase(strmid(ctype[iy],5,3)) else projectiony = ''
if projectionx eq projectiony then projection=projectionx else projection=''
;
;  If not determined yet, and both the X and Y axes are angular, and the
;  coordinate type is Helioprojective-Cartesian, then assume the TAN
;  projection.
;
if projection eq '' and (coord_type eq 'Helioprojective-Cartesian') and $
  (not keyword_set(noprojection)) then begin
    unitx = strmid(strupcase(cunit[ix]),0,3)
    unity = strmid(strupcase(cunit[iy]),0,3)
    if ((unitx eq 'ARC') or (unitx eq 'DEG') or (unitx eq 'MAS') or $
        (unitx eq 'RAD')) and (unitx eq unity) and (n_axis ge 2) then $
      projection = 'TAN' else projection = ''
endif
;
;  If the coordinate type is Helioprojective-Cartesian, and the projection is
;  TAN, then assume arcseconds instead of degrees, and refine the assumptions
;  for CTYPE.
;
if (coord_type eq 'Helioprojective-Cartesian') and (projection eq 'TAN') then $
  begin
    w = where(cunit_assumed, n)
    if n gt 0 then cunit[w] = 'arcsec'
    if ctype_assumed[ix] then ctype[ix] = 'HPLN-TAN'
    if ctype_assumed[iy] then ctype[iy] = 'HPLT-TAN'
end else if (coord_type eq 'Heliocentric-Cartesian') then begin
    if ctype_assumed[ix] then ctype[ix] = 'SOLX'
    if ctype_assumed[iy] then ctype[iy] = 'SOLY'
endif
;
;  Get the WCSNAME value.  If not found, use the WCS type determined above.
;
val = wcs_find_keyword(index, tags, column, system, count, 'WCSNAME', 'WCSN', $
                       lunfxb=lunfxb, rowfxb=rowfxb)
if count gt 0 then wcsname = val[0] else wcsname = coord_type
;
;  Extract the LONPOLE and LATPOLE keywords associated with the projection.
;  Store these in the arrays PROJ_NAMES and PROJ_VALUES.
;
delvarx, proj_names, proj_values
val = wcs_find_keyword(index, tags, column, system, count, 'LONPOLE', 'LONP', $
                       lunfxb=lunfxb, rowfxb=rowfxb, /allow_primary)
if count gt 0 then begin
    boost_array, proj_names, 'LONPOLE'
    boost_array, proj_values, val[0]
endif
val = wcs_find_keyword(index, tags, column, system, count, 'LATPOLE', 'LATP', $
                       lunfxb=lunfxb, rowfxb=rowfxb, /allow_primary)
if count gt 0 then begin
    boost_array, proj_names, 'LATPOLE'
    boost_array, proj_values, val[0]
endif
;
;  Extract any PVi_ma keywords.
;
val = wcs_find_keyword(index, tags, column, system, count, 'PV*_*', $
                       ['*V#_*','*PV#_*'], lunfxb=lunfxb, rowfxb=rowfxb, $
                       names=names)
for i=0,count-1 do begin
    name = names[i]
    if system eq '' then systest='' else systest=strmid(name,strlen(name)-1,1)
    if system eq systest then begin
        if column eq '' then begin
            test = strmid(name,2,strlen(name)-2-strlen(system))
            underscore = strpos(test,'_')
            ii = strmid(test,0,underscore)
            mm = strmid(test,underscore+1,strlen(test)-underscore-1)
            if valid_num(ii) and valid_num(mm) then begin
                boost_array, proj_names, 'PV' + test
                boost_array, proj_values, val[i]
            endif
        end else begin
            v = strpos(name,'V')
            if strmid(name,v-1,1) eq 'P' then ii = strmid(name,0,v-1) else $
              ii = strmid(name,0,v)
            test = strmid(name,v+1,strlen(name)-v-1-strlen(system))
            underscore = strpos(test,'_')
            nn = strmid(test,0,underscore)
            mm = strmid(test,underscore+1,strlen(test)-underscore-1)
            if valid_num(ii) and valid_num(mm) and (nn eq column) then begin
                boost_array, proj_names, 'PV' + ii + '_' + mm
                boost_array, proj_values, val[i]
            endif
        endelse
    endif
endfor
;
;  Extract any iVn_Xa keywords.
;
if (column ne '') and (n_elements(lunfxb) eq 1) then begin
    if fxbisopen(lunfxb) then begin
        if n_elements(rowfxb) eq 1 then row=rowfxb else row = 1
        fxbfind, fxbheader(lunfxb), 'TTYPE', cols, vals, n_found
        w = where(strmatch(vals,'*V'+column+'_X'+system), nn)
        if nn gt 0 then for i=0,nn-1 do begin
            name = vals[w[i]]
            v = strpos(name,'V')
            if strmid(name,v-1,1) eq 'P' then ii = strmid(name,0,v-1) else $
              ii = strmid(name,0,v)
            if valid_num(ii) then begin
                fxbread, lunfxb, data, cols[w[i]], row
                for j=0,n_elements(data)-1 do begin
                    boost_array, proj_names, 'PV' + ii + '_' + ntrim(j)
                    boost_array, proj_values, data[j]
                endfor
            endif
        endfor
    endif
endif
;
;  Extract any PSi_ma keywords.
;
delvarx, proj_snames, proj_svalues
val = wcs_find_keyword(index, tags, column, system, count, 'PS*_*', $
                       ['*V#_*','*PS#_*'], lunfxb=lunfxb, rowfxb=rowfxb, $
                       names=names)
for i=0,count-1 do begin
    name = names[i]
    if system eq '' then systest='' else systest=strmid(name,strlen(name)-1,1)
    if system eq systest then begin
        if column eq '' then begin
            test = strmid(name,2,strlen(name)-2-strlen(system))
            underscore = strpos(test,'_')
            ii = strmid(test,0,underscore)
            mm = strmid(test,underscore+1,strlen(test)-underscore-1)
            if valid_num(ii) and valid_num(mm) then begin
                boost_array, proj_snames, 'PS' + test
                boost_array, proj_svalues, val[i]
            endif
        end else begin
            s = strpos(name,'S')
            if strmid(name,s-1,1) eq 'P' then ii = strmid(name,0,s-1) else $
              ii = strmid(name,0,s)
            test = strmid(name,s+1,strlen(name)-s-1-strlen(system))
            underscore = strpos(test,'_')
            nn = strmid(test,0,underscore)
            mm = strmid(test,underscore+1,strlen(test)-underscore-1)
            if valid_num(ii) and valid_num(mm) and (nn eq column) then begin
                boost_array, proj_snames, 'PS' + ii + '_' + mm
                boost_array, proj_svalues, val[i]
            endif
        endelse
    endif
endfor
;
;  Create the structure containing the extracted information.
;
command = 'wcs = {coord_type: coord_type, wcsname: wcsname, naxis: naxis, ' + $
  'variation: variation, compliant: compliant, projection: projection, ' + $
  'ix: ix, iy: iy, crpix: crpix, crval: crval, ctype: ctype, ' + $
  'cname: cname, cunit: cunit' 
case variation of
    'PC': command = command + ', cdelt: cdelt, pc: pc'
    'CD': command = command + ', cd: cd'
    'CROTA': command = command + $
      ', cdelt: cdelt, roll_angle: roll_angle, pc: pc'
endcase
if n_elements(proj_names) gt 0 then command = command + $
  ', proj_names: proj_names[*], proj_values: proj_values[*]'
if n_elements(proj_snames) gt 0 then command = command + $
  ', proj_snames: proj_snames[*], proj_svalues: proj_svalues[*]'
command = command + '}'
test = execute(command)
;
;  If the WCS is of the PC or CD variety, then see if it can be broken down
;  into CDELT and CROTA values.  If so, then add them to the structure.
;
if (variation eq 'PC') or (variation eq 'CD') then $
  wcs_decomp_angle, wcs, roll_angle, cdelt, found, /add_tags, _extra=_extra
;
;  Determine whether or not the WCS is simple.
;
simple = wcs_simple( wcs, /add_tag )
if keyword_set(minimal) then return, wcs
;
;  Add any time, position, and spectral axis information from the FITS header.
;
wcs_find_time,     index, tags, system, wcs, column=column, $
  lunfxb=lunfxb, rowfxb=rowfxb
wcs_find_position, index, tags, system, wcs, lunfxb=lunfxb, rowfxb=rowfxb, $
  _extra=_extra
wcs_find_spectrum, index, tags, system, wcs, column=column, $
  lunfxb=lunfxb, rowfxb=rowfxb
;
;  If the optional filename keyword was passed, then look for lookup table
;  information.
;
if n_elements(filename) eq 1 then wcs_find_table, wcs, filename
;
;  If the PIXEL_LIST keyword was passed, and LUNFXB is defined, then look for
;  pixel list information.
;
if keyword_set(pixel_list) and (n_elements(lunfxb) eq 1) then $
  wcs_find_pixel_list, wcs, lunfxb, index, tags, system
;
return, wcs
;
HANDLE_ERROR:
if n_elements(errmsg) ne 0 then errmsg = 'FITSHEAD2WCS: ' + message else $
  message, message, /continue
end
