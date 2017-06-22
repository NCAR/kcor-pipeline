;+
; Project     :	STEREO
;
; Name        :	WCS_FIND_PIXEL_LIST
;
; Purpose     :	Find pixel list information in FITS header
;
; Category    :	FITS, Coordinates, WCS
;
; Explanation :	This procedure extracts pixel list information from a
;               FITS index structure, and adds it to a World Coordinate System
;               structure in a separate PIXEL_LIST substructure.  Parts of the
;               WCS structure is modified to use the PIXEL_LIST coordinates.
;
;               This routine is normally called from FITSHEAD2WCS.
;
; Syntax      :	WCS_FIND_PIXEL_LIST, WCS, LUNFXB, INDEX, TAGS, SYSTEM
;
; Examples    :	See fitshead2wcs.pro
;
; Inputs      : WCS     = A WCS structure, from FITSHEAD2WCS.
;
;               LUNFXB  = The logical unit number returned by FXBOPEN,
;                         pointing to the binary table that the header
;                         refers to.
;
;               INDEX    = Index structure from FITSHEAD2STRUCT.
;
;               TAGS     = The tag names of INDEX
;
;               SYSTEM   = A one letter code "A" to "Z", or the null string
;                          (see wcs_find_system.pro).
;
; Opt. Inputs :	None.
;
; Outputs     :	The output is the structure PIXEL_LIST, which will contain
;               an array of coordinate positions already processed through the
;               WCS keywords.
;
; Opt. Outputs:	None.
;
; Keywords    :	None.
;
; Calls       :	FXHMAKE, FXADDPAR, NTRIM, WCS_FIND_KEYWORD, VALID_NUM,
;               FITSHEAD2WCS, FXBREAD, WCS_GET_COORD, ADD_TAG, REP_TAG_VALUE,
;               TAG_EXIST, REM_TAG, DELVARX
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
; History     :	Version 1, 11-Oct-2006, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;
pro wcs_find_pixel_list, wcs, lunfxb, index, tags, system
on_error, 2
;
;  Set up the keywords to search for, based on SYSTEM.
;
if system eq '' then begin
    ctype = 'TCTYP'
    cunit = 'TCUNI'
    crval = 'TCRVL'
    cdelt = 'TCDLT'
    crpix = 'TCRPX'
end else begin
    ctype = 'TCTY'
    cunit = 'TCUN'
    crval = 'TCRV'
    cdelt = 'TCDE'
    crpix = 'TCRP'
endelse
;
;  Scan the header for TCTYPn or TCTYna keywords.  If none are found, then
;  return immediately--the header does not contain a pixel list.
;
wctype = where(strmatch(tags, ctype + '*' + system), naxes)
if naxes eq 0 then return
;
;  Make a fake FITS header out of the pixel list keywords.
;
fxhmake, fhead
fxaddpar, fhead, 'naxis', naxes
for i=1,naxes do fxaddpar, fhead, 'naxis'+ntrim(i), 1
;
;  Get the column number that the pixel list refers to.
;
col = strarr(naxes)
for i=0,naxes-1 do begin
    tag = tags[wctype[i]]
    i0 = strlen(ctype)
    i1 = strlen(tag) - i0 - strlen(system)
    col[i] = strmid(tag, i0, i1)
endfor
;
;  Add the pixel list parameters that go with each axis.
;
for i=0,naxes-1 do begin
    si = ntrim(i+1)
    fxaddpar, fhead, 'CTYPE' + si, index.(wctype[i])
;
    w = where(tags eq cunit+col[i]+system, count)
    if count gt 0 then fxaddpar, fhead, 'CUNIT'+si, index.(w[0])
;
    w = where(tags eq crval+col[i]+system, count)
    if count gt 0 then fxaddpar, fhead, 'CRVAL'+si, index.(w[0])
;
    w = where(tags eq cdelt+col[i]+system, count)
    if count gt 0 then fxaddpar, fhead, 'CDELT'+si, index.(w[0])
;
;  Add 1 to CRPIX to handle the IDL/FITS offset.  (Simpler than subtracting 1
;  from the values inside the table columns.)
;
    w = where(tags eq crpix+col[i]+system, count)
    if count gt 0 then fxaddpar, fhead, 'CRPIX'+si, index.(w[0]) + 1
;
    w = where(tags eq 'TCRD'+col[i]+system, count)
    if count gt 0 then fxaddpar, fhead, 'CRDER'+si, index.(w[0])
;
    w = where(tags eq 'TCSY'+col[i]+system, count)
    if count gt 0 then fxaddpar, fhead, 'CSYER'+si, index.(w[0])
;
    w = where(tags eq 'TCNA'+col[i]+system, count)
    if count gt 0 then fxaddpar, fhead, 'CNAME'+si, index.(w[0])
;
;  If using the primary system, then look for the rotation angle.
;
    if system eq '' then begin
        w = where(tags eq 'TCROT'+si, count)
        if count gt 0 then fxaddpar, fhead, 'CROTA'+si, index.(w[0])
    endif
;
;  Add the keyword parameters that aren't attached to a particular axis.
;
    w = where(tags eq 'WCSN'+col[i]+system, count)
    if count gt 0 then fxaddpar, fhead, 'WCSNAME', index.(w[0])
;
    w = where(tags eq 'EQUI'+col[i]+system, count)
    if count gt 0 then fxaddpar, fhead, 'EQUINOX', index.(w[0])
;
    w = where(tags eq 'MJDOB'+col[i], count)
    if count gt 0 then fxaddpar, fhead, 'MJD-OBS', index.(w[0])
;
    w = where(tags eq 'RADE'+col[i]+system, count)
    if count gt 0 then fxaddpar, fhead, 'RADESYS', index.(w[0])
;
    w = where(tags eq 'LONP'+col[i]+system, count)
    if count gt 0 then fxaddpar, fhead, 'LONPOLE', index.(w[0])
;
    w = where(tags eq 'LATP'+col[i]+system, count)
    if count gt 0 then fxaddpar, fhead, 'LATPOLE', index.(w[0])
;
    w = where(tags eq 'RFRQ'+col[i]+system, count)
    if count gt 0 then fxaddpar, fhead, 'RESTFRQ', index.(w[0])
;
    w = where(tags eq 'RWAV'+col[i]+system, count)
    if count gt 0 then fxaddpar, fhead, 'RESTWAV', index.(w[0])
;
    w = where(tags eq 'SPEC'+col[i]+system, count)
    if count gt 0 then fxaddpar, fhead, 'SPECSYS', index.(w[0])
;
    w = where(tags eq 'SOBS'+col[i]+system, count)
    if count gt 0 then fxaddpar, fhead, 'SSYSOBS', index.(w[0])
;
    w = where(tags eq 'MJDA'+col[i], count)
    if count gt 0 then fxaddpar, fhead, 'MJD-AVG', index.(w[0])
;
    w = where(tags eq 'DAVG'+col[i], count)
    if count gt 0 then fxaddpar, fhead, 'DATE-AVG', index.(w[0])
;
    w = where(tags eq 'OBSGX'+col[i], count)
    if count gt 0 then fxaddpar, fhead, 'OBSGEO-X', index.(w[0])
;
    w = where(tags eq 'OBSGY'+col[i], count)
    if count gt 0 then fxaddpar, fhead, 'OBSGEO-Y', index.(w[0])
;
    w = where(tags eq 'OBSGZ'+col[i], count)
    if count gt 0 then fxaddpar, fhead, 'OBSGEO-Z', index.(w[0])
;
    w = where(tags eq 'VSYS'+col[i]+system, count)
    if count gt 0 then fxaddpar, fhead, 'VELOSYS', index.(w[0])
;
    w = where(tags eq 'ZSOU'+col[i]+system, count)
    if count gt 0 then fxaddpar, fhead, 'ZSOURCE', index.(w[0])
;
    w = where(tags eq 'SSRC'+col[i]+system, count)
    if count gt 0 then fxaddpar, fhead, 'SSYSSRC', index.(w[0])
;
    w = where(tags eq 'VANG'+col[i]+system, count)
    if count gt 0 then fxaddpar, fhead, 'VELANGL', index.(w[0])
;
;  Add the cross-term keyword parameters.
;
    for j=0,naxes-1 do begin
        sj = ntrim(j+1)
        w = where(tags eq 'TV'+col[i]+'_'+col[j]+system, count)
        if count gt 0 then fxaddpar, fhead, 'PC'+si+'_'+sj, index.(w[0])
;
        w = where(tags eq 'TC'+col[i]+'_'+col[j]+system, count)
        if count gt 0 then fxaddpar, fhead, 'CD'+si+'_'+sj, index.(w[0])
    endfor
;
;  Add the coordinate parameters.
;
    val = wcs_find_keyword(index, tags, '', system, count, $
                           'TV'+col[i]+'_*', names=names)
    for k=0,count-1 do begin
        name = names[k]
        if system eq '' then systest='' else $
          systest=strmid(name,strlen(name)-1,1)
        if system eq systest then begin
            test = strmid(name,2,strlen(name)-2-strlen(system))
            underscore = strpos(test,'_')
            ii = strmid(test,0,underscore)
            mm = strmid(test,underscore+1,strlen(test)-underscore-1)
            if valid_num(ii) and valid_num(mm) then $
              fxaddpar, fhead, 'PV' + si + '_' + mm, val[k]
        endif
    endfor
;
    val = wcs_find_keyword(index, tags, '', system, count, $
                           'TS'+col[i]+'_*', names=names)
    for k=0,count-1 do begin
        name = names[k]
        if system eq '' then systest='' else $
          systest=strmid(name,strlen(name)-1,1)
        if system eq systest then begin
            test = strmid(name,2,strlen(name)-2-strlen(system))
            underscore = strpos(test,'_')
            ii = strmid(test,0,underscore)
            mm = strmid(test,underscore+1,strlen(test)-underscore-1)
            if valid_num(ii) and valid_num(mm) then $
              fxaddpar, fhead, 'PS' + si + '_' + mm, val[k]
        endif
    endfor
endfor                          ;I=0,Naxes-1
;
;  Convert the fake FITS header into a WCS.
;
fwcs = fitshead2wcs(fhead)
;
;  Read in the pixel values from the table, and apply the coordinate
;  projection.  Add to the WCS structure.
;
pixel = dblarr(naxes, index.naxis2)
for i=0,naxes-1 do begin
    fxbread, lunfxb, xx, fix(col[i])
    pixel[i,*] = xx
endfor
coord = wcs_get_coord(fwcs, pixel)
wcs = add_tag(wcs, coord, 'pixel_list')
;
;  Reconfigure the WCS to incorporate the WCS information.
;
naxis = replicate(1,naxes)
naxis[0] = index.naxis2
wcs = rep_tag_value(wcs, naxis, 'naxis')
wcs = rep_tag_value(wcs, replicate(1,    naxes), 'crpix')
wcs = rep_tag_value(wcs, replicate(1.d0, naxes), 'crval')
wcs = rep_tag_value(wcs, replicate(1.d0, naxes), 'cdelt')
wcs = rep_tag_value(wcs, fwcs.ctype, 'ctype')
wcs = rep_tag_value(wcs, fwcs.cname, 'cname')
wcs = rep_tag_value(wcs, fwcs.cunit, 'cunit')
wcs = rep_tag_value(wcs, 0.d0, 'roll_angle')
wcs.projection = 'PIXEL-LIST'
wcs.coord_type = fwcs.coord_type
wcs.wcsname    = fwcs.wcsname
wcs.variation  = 'PC'
wcs.compliant  = fwcs.compliant
wcs.ix         = fwcs.ix
wcs.iy         = fwcs.iy
wcs.simple     = fwcs.simple
pc = dblarr(naxes,naxes)
for i=0,naxes-1 do pc[i,i] = 1.d0
wcs = rep_tag_value(wcs, pc, 'pc')
if tag_exist(wcs,'CD') then wcs = rem_tag(wcs,'CD')
;
;  Merge information from the TIME substructure.
;
if tag_exist(fwcs, 'time') then begin
    if tag_exist(wcs,'time') then time = wcs.time else delvarx, time
    ftime = fwcs.time
    ftags = tag_names(ftime)
    for itag = 0,n_elements(ftags)-1 do $
      time = rep_tag_value(time, ftime.(i), ftags[i])
    wcs = rep_tag_value(wcs, time, 'time')
endif
;
;  Merge information from the POSITION substructure, but only if POS_ASSUMED=0.
;
if tag_exist(fwcs, 'position') then begin
    if tag_exist(wcs,'position') then position = wcs.position else $
      delvarx, position
    fposition = fwcs.position
    ftags = tag_names(fposition)
    if fposition.pos_assumed eq 0 then begin
        for itag = 0,n_elements(ftags)-1 do $
          position = rep_tag_value(position, fposition.(i), ftags[i])
        wcs = rep_tag_value(wcs, position, 'position')
    endif
endif
;
;  Merge information from the SPECTRUM substructure.
;
if tag_exist(fwcs, 'spectrum') then begin
    if tag_exist(wcs,'spectrum') then spectrum = wcs.spectrum else $
      delvarx, spectrum
    fspectrum = fwcs.spectrum
    ftags = tag_names(fspectrum)
    for itag = 0,n_elements(ftags)-1 do $
      spectrum = rep_tag_value(spectrum, fspectrum.(i), ftags[i])
    wcs = rep_tag_value(wcs, spectrum, 'spectrum')
endif
;
end
