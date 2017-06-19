;+
; Project     :	STEREO
;
; Name        :	WCS_FIND_KEYWORD()
;
; Purpose     :	Finds keywords in primary or table header.
;
; Category    :	FITS, Coordinates, WCS
;
; Explanation :	This procedure examines the FITS index structure, and finds the
;               requested WCS keyword.  Keywords will have one form for the
;               primary FITS header, and another form for binary tables.  For
;               example, a keyword might appear as "WCSAXES" in the primary
;               header, but as "WCAX3" in the binary table header.  Each may
;               also have alternate forms.
;
;               This routine is normally called from FITSHEAD2WCS.
;
; Syntax      :	Value = WCS_FIND_KEYWORD(INDEX, TAGS, COLUMN, SYSTEM, COUNT, $
;                                        PRIMARY, BINTABLE)
;
; Examples    :	See fitshead2wcs.pro
;
; Inputs      :	INDEX    = Index structure from FITSHEAD2STRUCT.
;
;               TAGS     = The tag names of INDEX
;
;               COLUMN   = String containing binary table column number, or
;                          the null string.
;
;               SYSTEM   = A one letter code "A" to "Z", or the null string
;                          (see wcs_find_system.pro).
;
;               PRIMARY  = String(*) to test against primary headers.
;
;               BINTABLE = String(*) to test against binary table headers.
;                          Most keywords end in the column number and the
;                          system code.  If the column number is in a different
;                          location, this can be signalled with a "#"
;                          character, e.g. '3V#_1'.
;
;               PRIMARY and BINTABLE can also be string arrays, in order of
;               preference.  If the string contains '*', then STRMATCH is used.
;
; Opt. Inputs :	Although the normal usage is to include all of the parameters,
;               the BINTABLE parameter can be left off.
;
; Outputs     :	COUNT    = The number of matches found.
;
;               The result of the function is the value(s) of the keyword,
;               or -1 if not found.
;
; Opt. Outputs:	None.
;
; Keywords    :	ALLOW_PRIMARY = If set, then the primary header form can also
;                               be used in binary tables.
;
;               NAMES         = The names of the tags found, for when the input
;                               strings contain "*".
;
;               LUNFXB        = The logical unit number returned by FXBOPEN,
;                               pointing to the binary table that the header
;                               refers to.  Usage of this keyword allows
;                               implementation of the "Greenbank Convention",
;                               where keywords can be replaced with columns of
;                               the same name.
;
;               ROWFXB        = Used in conjunction with LUNFXB, to give the
;                               row number in the table.  Default is 1.
;
; Calls       :	FXBISOPEN, FXBCOLNUM, FXBREAD, FXBHEADER, FXBFIND
;
; Common      :	None.
;
; Restrictions:	Because this routine is intended to be called only from
;               FITSHEAD2WCS, no error checking is performed.
;
; Side effects:	None.
;
; Prev. Hist. :	None.
;
; History     :	Version 1, 22-Jun-2005, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;
function wcs_find_keyword, index, tags, column, system, count, primary, $
                           bintable, allow_primary=allow_primary, $
                           names=names, lunfxb=lunfxb, rowfxb=rowfxb
on_error, 2
result = -1
count = 0
;
if n_elements(column) eq 0 then column = ''
if n_elements(rowfxb) ne 0 then row = rowfxb else row = 1
;
;  If applicable, first look for the binary table header form.
;
if column ne '' then begin
    i = 0
    while (count eq 0) and (i lt n_elements(bintable)) do begin
;
;  Add the column number and system to the test string.
;
        test = bintable[i]
        w = strpos(test, '#')
        if w lt 0 then test = test + column else $
          test = strmid(test,0,w) + column + strmid(test,w+1,strlen(test)-w-1)
        test = test + system
;
;  Search for the string.
;
        if strpos(test,'*') ge 0 then $
          w = where(strmatch(tags, test), count) else $
          w = where(tags eq test, count)
        if count gt 0 then begin
            result = index.(w[0])
            if count gt 1 then begin
                result = replicate(result, count)
                for j=1,count-1 do result[j] = index.(w[j])
            endif
            names = tags[w]
        endif
;
;  If the logical unit number was passed, then see if there's a column of the
;  same name.  This is known as the "Greenbank Convention".
;
        if (count eq 0) and (n_elements(lunfxb) eq 1) then begin
            if fxbisopen(lunfxb) then begin
                errmsg = ''
                if strpos(test,'*') ge 0 then begin
                    fxbfind, fxbheader(lunfxb), 'TTYPE', cols, vals, n_found
                    w = where(strmatch(vals,test), nn)
                    if nn gt 0 then begin
                        fxbread, lunfxb, data, cols[w[0]], row
                        result = data[0]
                        names = vals[w[0]]
                        if nn gt 1 then for j=1,nn-1 do begin
                            fxbread, lunfxb, data, cols[w[j]], row
                            result = [result, data[0]]
                            names  = [names, vals[w[j]]]
                        endfor
                        count = n_elements(result)
                    endif
                end else begin
                    colnum = fxbcolnum(lunfxb, test, errmsg=errmsg)
                    if (colnum gt 0) and (errmsg eq '') then begin
                        fxbread, lunfxb, data, colnum, row
                        result = data[0]
                        names  = test
                        count = n_elements(data)
                    endif
                endelse
            endif
        endif
;
        i = i + 1
    endwhile
endif
;
;  If applicable, look for the primary header form.  For binary tables, this is
;  only relevant if the keyword hasn't been found yet.
;
if (column eq '') or keyword_set(allow_primary) then begin
    i = 0
    while (count eq 0) and (i lt n_elements(primary)) do begin
        test = primary[i] + system
        if strpos(test,'*') ge 0 then $
          w = where(strmatch(tags, test), count) else $
          w = where(tags eq test, count)
        if count gt 0 then begin
            result = index.(w[0])
            if count gt 1 then begin
                result = replicate(result, count)
                for j=1,count-1 do result[j] = index.(w[j])
            endif
            names = tags[w]
        endif
;
;  If the logical unit number was passed, then see if there's a column of the
;  same name.  This is known as the "Greenbank Convention".
;
        if (count eq 0) and (n_elements(lunfxb) eq 1) then begin
            if fxbisopen(lunfxb) then begin
                errmsg = ''
                if strpos(test,'*') ge 0 then begin
                    fxbfind, fxbheader(lunfxb), 'TTYPE', cols, vals, n_found
                    w = where(strmatch(vals,test), nn)
                    if nn gt 0 then begin
                        fxbread, lunfxb, data, cols[w[0]], row
                        result = data[0]
                        names = vals[w[0]]
                        if nn gt 1 then for j=1,nn-1 do begin
                            fxbread, lunfxb, data, cols[w[j]], row
                            result = [result, data[0]]
                            names  = [names, vals[w[j]]]
                        endfor
                        count = n_elements(result)
                    endif
                end else begin
                    colnum = fxbcolnum(lunfxb, test, errmsg=errmsg)
                    if (colnum gt 0) and (errmsg eq '') then begin
                        fxbread, lunfxb, data, colnum, row
                        result = data[0]
                        names  = test
                        count = n_elements(data)
                    endif
                endelse
            endif
        endif
;
        i = i + 1
    endwhile
endif
;
return, result
end
