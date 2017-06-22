;+
; Project     :	STEREO
;
; Name        :	WCS_FIND_TIME
;
; Purpose     :	Find time information in FITS header
;
; Category    :	FITS, Coordinates, WCS
;
; Explanation :	This procedure extracts observation time information from a
;               FITS index structure, and adds it to a World Coordinate System
;               structure in a separate TIME substructure.
;
;               This routine is normally called from FITSHEAD2WCS.
;
; Syntax      :	WCS_FIND_TIME, INDEX, TAGS, SYSTEM, WCS
;
; Examples    :	See fitshead2wcs.pro
;
; Inputs      :	INDEX  = Index structure from FITSHEAD2STRUCT.
;               TAGS   = The tag names of INDEX
;               SYSTEM = A one letter code "A" to "Z", or the null string
;                        (see wcs_find_system.pro).
;               WCS    = A WCS structure, from FITSHEAD2WCS.
;
; Opt. Inputs :	None.
;
; Outputs     :	The output is the structure TIME, which will contain one or
;               more of the following parameters, depending on the contents of
;               the FITS header:
;
;                       Variable           FITS Keyword
;
;                       FITS_DATE          DATE
;                       OBSERV_DATE        DATE-OBS
;                       OBSERV_END         DATE-END
;                       OBSERV_MID         DATE-MID
;                       OBSERV_AVG         DATE-AVG
;                       CORRECTED_DATE     DATE_OBS
;                       CORRECTED_END      DATE_END
;                       CORRECTED_MID      DATE_MID
;                       CORRECTED_AVG      DATE_AVG
;                       EXPTIME            EXPTIME
;                       MJD_OBS            MJD-OBS
;                       MJD_AVG            MJD-AVG
;                       EQUINOX            EQUINOXa
;                       EPOCH              EPOCH
;                       RADESYS            RADESYSa
;
;               The DATE_xxx keywords are expected to be the same as DATE-xxx,
;               but corrected for the difference in light travel time between
;               the spacecraft and Earth.  If only DATE_xxx keywords are found,
;               they're treated as the DATE-xxx equivalents.  If both DATE_xxx
;               and DATE-xxx keywords are in the header, and have the same
;               value, the DATE_xxx keywords are ignored.
;
;               The meaning of the various xxx suffices are:
;
;                       OBS     Observation date, usually the start of the
;                               observation.
;                       END     End time of the observation
;                       MID     Midpoint of the observation.
;                       AVG     No exact definition, but supposed to be
;                               representative of the observation as a whole
;                               (from WCS spectral paper).
;
;               The EQUINOX, EPOCH and RADESYS keywords relate to the time
;               basis used for the celestial coordinate system.
;
;               If successful, the TIME structure is added to the WCS
;               structure.
;
; Opt. Outputs:	None.
;
; Keywords    :	COLUMN    = String containing binary table column number, or
;                           the null string.
;
;               LUNFXB    = The logical unit number returned by FXBOPEN,
;                           pointing to the binary table that the header
;                           refers to.  Usage of this keyword allows
;                           implementation of the "Greenbank Convention",
;                           where keywords can be replaced with columns of
;                           the same name.
;
;               ROWFXB    = Used in conjunction with LUNFXB, to give the
;                           row number in the table.  Default is 1.
;
; Calls       :	ANYTIM2UTC, UTC2STR, TAG_EXIST, REM_TAG, ADD_TAG,
;               WCS_FIND_KEYWORD
;
; Common      :	None.
;
; Restrictions:	Currently, only one FITS header, and one WCS, can be examined
;               at a time.
;
;               Because this routine is intended to be called only from
;               FITSHEAD2WCS, no error checking is performed.
;
; Side effects:	None.
;
; Prev. Hist. :	None.
;
; History     :	Version 1, 15-Apr-2005, William Thompson, GSFC
;               Version 2, 01-Jun-2005, William Thompson, GSFC
;                       Handle alternate format for RADESYS keyword
;               Version 3, 22-Jun-2005, William Thompson, GSFC
;                       Handle binary tables, correct error with MJD-AVG, allow
;                       DATE-AVG as one of the substitutes for DATE-OBS
;
; Contact     :	WTHOMPSON
;-
;
pro wcs_find_time, index, tags, system, wcs, column=column, lunfxb=lunfxb, $
                   rowfxb=rowfxb
on_error, 2
if n_elements(column) eq 0 then column=''
;
;  Look for the FITS creation date.
;
w = where(tags eq 'DATE', count)
if count gt 0 then fits_date=index.(w[0]) else fits_date=''
;
;  Look for the following keywords and values.  The supposition is that the
;  versions using an underscore have been corrected for the difference in light
;  travel time between the spacecraft and Earth.
;
;       DATE-OBS  observ_date      DATE_OBS  corrected_date
;       DATE-END  observ_end       DATE_END  corrected_end
;       DATE-MID  observ_mid       DATE_MID  corrected_mid
;       DATE-AVG  observ_avg       DATE_AVG  corrected_avg.
;
;  If necessary, add in the time part from a separate keyword.
;
insuffix = ['OBS','END','MID','AVG']
outsuffix = ['date','end','mid','avg']
;
;  First look for a DATE-xxx keyword.
;
for i=0,n_elements(insuffix)-1 do begin
    observ = ''
    val = wcs_find_keyword(index, tags, '', '', count, $
                           ['DATE_D$'+insuffix[i], 'DATE-'+insuffix[i]], $
                           lunfxb=lunfxb, rowfxb=rowfxb)
    if count gt 0 then begin
;
;  If the time part is zero, check to see if there's also a TIME-xxx keyword.
;
        date = strtrim(val[0],2)
        if date ne '' then begin
            utc = anytim2utc(date)
            if utc.time eq 0 then begin
                val = wcs_find_keyword(index, tags, '', '', count, $
                           ['TIME_D$'+insuffix[i], 'TIME-'+insuffix[i]], $
                           lunfxb=lunfxb, rowfxb=rowfxb)
                if count gt 0 then begin
                    utc1 = anytim2utc(val[0])
                    utc.time = utc1.time
                endif
            endif
            observ = utc2str(utc)
        endif
    endif
;
;  Also look for DATE_xxx, which may (or may not) be a time corrected for the
;  difference in light travel time between the spacecraft and Earth.
;
    corrected = ''
    val = wcs_find_keyword(index, tags, '', '', count, $
                           'DATE_'+insuffix[i], lunfxb=lunfxb, rowfxb=rowfxb)
    if count gt 0 then begin
;
;  If the time part is zero, check to see if there's also a TIME_xxx keyword.
;
        date = strtrim(val[0],2)
        if date ne '' then begin
            utc = anytim2utc(date)
            if utc.time eq 0 then begin
                val = wcs_find_keyword(index, tags, '', '', count, $
                           'TIME_'+insuffix[i], lunfxb=lunfxb, rowfxb=rowfxb)
                if count gt 0 then begin
                    utc1 = anytim2utc(val[0])
                    utc.time = utc1.time
                endif
            endif
            corrected = utc2str(utc)
        endif
    endif
;
;  If the DATE-xxx keyword wasn't found, use the DATE_xxx keyword instead.
;
    if observ eq '' then observ = corrected
;
;  If the DATE-xxx and DATE_xxx forms are the same, then deassign the latter.
;
    if observ eq corrected then corrected = ''
;
;  Store the results in the proper variables.
;
    test = execute("observ_"    + outsuffix[i] + " = observ")
    test = execute("corrected_" + outsuffix[i] + " = corrected")
endfor
;
;  If the column is passed, then also look for the DAVGn form of DATE-AVG.
;
if column ne '' then begin
    val = wcs_find_keyword(index, tags, '', '', count, '', 'DAVG', $
                           lunfxb=lunfxb, rowfxb=rowfxb, /allow_primary)
    if count ne 0 then observ_avg = val[0]
endif
;
;  Also look for the following keywords and values.  These aren't expected to
;  have a MJD_xxx variation.
;
;       MJD-OBS  mjd_obs
;       MJD-AVG  mjd_avg
;
mjdsuffix = ['obs','avg']
mjdbin  = ['MJDOB','MJDA']
for i = 0,n_elements(mjdsuffix)-1 do begin
    val = wcs_find_keyword(index, tags, column, '', count, /allow_primary, $
                           'MJD_D$'+strupcase(mjdsuffix[i]), mjdbin[i], $
                           lunfxb=lunfxb, rowfxb=rowfxb)
    if count gt 0 then begin
        mjd_float = val[0]
        mjd = long(mjd_float)
        time = round(86400000L * (mjd_float-mjd))
        utc = {mjd: mjd, time: time}
        mjd_date = utc2str(utc)
        test = execute('mjd_' + mjdsuffix[i] + ' = mjd_float')
        test = execute('mjd_' + mjdsuffix[i] + '_date = mjd_date')
    end else test = execute('mjd_' + mjdsuffix[i] + '_date = ""')
endfor
;
;  If observ_date is still undefined, then use the value of MJD-OBS, DATE-AVG,
;  or MJD-AVG.
;
if observ_date eq '' then observ_date = mjd_obs_date
if observ_date eq '' then observ_date = observ_avg
if observ_date eq '' then observ_date = mjd_avg_date
;
;  Look for the keyword EXPTIME.
;
val = wcs_find_keyword(index, tags, '', '', count, 'EXPTIME', $
                       lunfxb=lunfxb, rowfxb=rowfxb)
if count gt 0 then exptime = val[0]
;
;  Look for the keyword EQUINOXa.  If found, also look for RADESYSa.  If not
;  found, look for EPOCH.
;
val = wcs_find_keyword(index, tags, column, system, count, 'EQUINOX', 'EQUI', $
                       /allow_primary, lunfxb=lunfxb, rowfxb=rowfxb)
if count gt 0 then begin
    equinox = val[0]
    val = wcs_find_keyword(index, tags, column, system, count, $
                           ['RADESYS','RADECSYS'], 'RADE', /allow_primary, $
                           lunfxb=lunfxb, rowfxb=rowfxb)
    if count gt 0 then radesys = val[0]
end else begin
    val = wcs_find_keyword(index, tags, '', '', count, 'EPOCH', $
                           lunfxb=lunfxb, rowfxb=rowfxb)
    if count gt 0 then epoch = val[0]
endelse
;
;  Start creating the TIME structure, beginning with the FITS creation date.
;
command = 'time = {'
n_tags = 0
if fits_date ne '' then begin
    command = command + 'fits_date: fits_date'
    n_tags = n_tags + 1
endif
;
;  Add the DATE-xxx/DATE_xxx parameters.
;
prefix = ['observ','corrected']
for i=0,n_elements(prefix)-1 do begin
    for j=0,n_elements(outsuffix)-1 do begin
        name = prefix[i] + '_' + outsuffix[j]
        test = execute('date = ' + name)
        if date ne '' then begin
            if n_tags gt 0 then command = command + ', '
            command = command + name + ': ' + name
            n_tags = n_tags + 1
        endif
    endfor
endfor
;
;  Add the MJD-xxx values.
;
for i=0,n_elements(mjdsuffix)-1 do begin
    name = 'mjd_' + mjdsuffix[i]
    test = execute('mjd_date = ' + name + '_date')
    if mjd_date ne '' then begin
        if n_tags gt 0 then command = command + ', '
        command = command + name + ': ' + name
        n_tags = n_tags + 1
    endif
endfor
;
;  Add in the other miscellaneous keywords.
;
if n_elements(exptime) ne 0 then begin
    if n_tags gt 0 then command = command + ', '
    command = command + 'exptime: exptime'
    n_tags = n_tags + 1
endif
;
if n_elements(equinox) ne 0 then begin
    if n_tags gt 0 then command = command + ', '
    command = command + 'equinox: equinox'
    n_tags = n_tags + 1
endif
;
if n_elements(radesys) ne 0 then begin
    if n_tags gt 0 then command = command + ', '
    command = command + 'radesys: radesys'
    n_tags = n_tags + 1
endif
;
if n_elements(epoch) ne 0 then begin
    if n_tags gt 0 then command = command + ', '
    command = command + 'epoch: epoch'
    n_tags = n_tags + 1
endif
;
;  Assuming that at least one time value was found, create the TIME structure.
;
if n_tags gt 0 then begin
    command = command + '}'
    test = execute(command)
;
;  Add the TIME tag to the WCS structure.
;
    if tag_exist(wcs, 'TIME', /top_level) then wcs = rem_tag(wcs, 'TIME')
    wcs = add_tag(wcs, time, 'TIME', /top_level)
endif
;
return
end
