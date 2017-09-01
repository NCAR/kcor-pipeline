;+
; Project     :	STEREO
;
; Name        :	WCS_FIND_SYSTEM()
;
; Purpose     :	Find alternate WCS coordinate system in FITS header
;
; Category    :	FITS, Coordinates, WCS
;
; Explanation :	This procedure examines the FITS header (or index structure),
;               and finds the letter code representing the desired alternate
;               World Coordinate System keywords.  For example, the primary
;               coordinate system has keywords CRPIX1, CRVAL1, etc., while an
;               alternate might have CRPIX1A, CRVAL1A, etc.
;
; Syntax      :	Result = WCS_FIND_SYSTEM( HEADER, SYSTEM )
;
; Examples    :	Result = WCS_FIND_SYSTEM( HEADER, 'A' )
;               Result = WCS_FIND_SYSTEM( INDEX, "Helioprojective-Cartesian")
;               Result = WCS_FIND_SYSTEM( INDEX, "CR" )  ;Carrington
;
; Inputs      :	HEADER  = Either a FITS header, or an index structure from
;                         FITSHEAD2STRUCT.
;
;               SYSTEM  = Selects which alternate coordinate system should be
;                         used.  The coordinate system can be specified in one
;                         of three ways:
;
;                         * Single letter "A" through "Z".
;                         * Value of a WCSNAME keyword in the header
;                         * One of a standard list of coordinate systems, based
;                           on the following table
;
;                                Abb.  Name
;
;                                HP    Helioprojective-Cartesian
;                                HR    Helioprojective-Radial
;                                HG    Stonyhurst-Heliographic
;                                CR    Carrington-Heliographic
;
;                         Either the full-name, or the two-letter abbreviation,
;                         can be used.  If the alternate coordinate system is
;                         not found in the header structure, then the primary
;                         coordinate system is returned.
;
; Opt. Inputs :	None.
;
; Outputs     :	The result of the function is either the null string, or a
;               single (uppercase) letter from "A" to "Z".
;
; Opt. Outputs:	None.
;
; Keywords    :	LOWERCASE = If set, then the result is returned as lowercase.
;               COLUMN    = String containing binary table column number, or
;                           the null string.
;
; Calls       :	DATATYPE, FITSHEAD2STRUCT, TAG_EXIST
;
; Common      :	None.
;
; Restrictions:	Currently, only one WCS can be examined at a time.
;
; Side effects:	None.
;
; Prev. Hist. :	None.
;
; History     :	Version 1, 1-Apr-2005, William Thompson, GSFC
;               Version 2, 21-Jun-2005, William Thompson, GSFC
;                       Add support for binary tables.
;
; Contact     :	WTHOMPSON
;-
;
function wcs_find_system, header, system, lowercase=lowercase, column=column
on_error, 2
if n_elements(column) eq 0 then column=''
;
;  Make sure that HEADER is either a string or a structure, and that SYSTEM is
;  a string.
;
if datatype(system,1) ne 'String' then message, $
  'SYSTEM must be a character string'
case datatype(header,1) of
    'String': index = fitshead2struct(header)
    'Structure': index = header
    else: message, 'HEADER must be either a string or a structure'
endcase
;
;  Extract the tag names.
;
tags = strupcase(tag_names(index))
;
;  Determine which coordinate system to look for.
;
result = ''
systest = strupcase(strtrim(system,2))
;
;  Was a single letter passed?
;
if strlen(systest) le 1 then begin
    if (systest ge 'A') and (systest le 'Z') and $
      tag_exist(index, 'crpix1'+systest, /top_level) then result = systest
;
;  Does SYSTEM match a WCSNAME entry?
;
end else begin
    if column eq '' then test = 'WCSNAME' else test = 'WCSN' + column
    w = where(strmid(tags,0,strlen(test)) eq test, count)
    if count gt 0 then begin
        wcsnames = strarr(count)
        for i=0,count-1 do wcsnames[i] = strupcase(strtrim(index.(w[i]),2))
        ww = where(systest eq wcsnames, ccount)
        if ccount gt 0 then result = strmid(tags[w[ww[0]]],7,1)
    endif
;
;  Otherwise, can one infer the system from the CTYPE entries?
;
    if result eq '' then begin
        if column eq '' then $
          w = where(strmid(tags,0,5) eq 'CTYPE', count) else $
          w = where(strmatch(tags, '*CTY' + column + '*'), count)
        if count gt 0 then begin
            ctypes = strarr(count)
            for i=0,count-1 do ctypes[i] = $
              strupcase(strmid(index.(w[i]),0,4))
            names = ['HELIOPROJECTIVE-CARTESIAN','HELIOPROJECTIVE-RADIAL',$
                     'STONYHURST-HELIOGRAPHIC','CARRINGTON-HELIOGRAPHIC']
            abbrev = ['HP','HR','HG','CR']
            ww = where((systest eq names) or (systest eq abbrev), ccount)
            if ccount gt 0 then begin
                test = abbrev[ww[0]] + 'LN'
                ww = where(ctypes eq test, ccount)
                if ccount gt 0 then begin
                    test = tags[w[ww[0]]]
                    test = strmid(test,strlen(test)-1,1)
                    if (test ge 'A') and (test le 'Z') then result=test
                endif
            endif               ;Longitude CTYPE found
        endif                   ;CTYPE tags found
    endif                       ;RESULT not yet set
endelse                         ;SYSTEM is multi-character
;
if keyword_set(lowercase) then result = strlowcase(result)
return, result
end
