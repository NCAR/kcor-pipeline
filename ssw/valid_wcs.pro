;+
; Project     :	STEREO
;
; Name        :	VALID_WCS()
;
; Purpose     :	Tests validity of WCS structure.
;
; Category    :	FITS, Coordinates, WCS
;
; Explanation :	This procedure examines an input structure to determine whether
;               or not it's a valid FITS World Coordinate System structure,
;               e.g. from the routine FITSHEAD2WCS.
;
; Syntax      :	Result = VALID_WCS( WCS )
;
; Examples    :	IF NOT VALID_WCS( WCS ) THEN MESSAGE, 'Not a valid WCS'
;
; Inputs      :	WCS  = The variable to be examined.
;
; Opt. Inputs :	None.
;
; Outputs     :	The result of the function is 1 if the input is recognized as a
;               WCS structure, 0 otherwise.
;
; Opt. Outputs:	None.
;
; Keywords    :	None.
;
; Calls       :	IS_STRUCT, TAG_EXIST
;
; Common      :	None.
;
; Restrictions:	Currently, only one WCS can be examined at a time.
;
; Side effects:	None.
;
; Prev. Hist. :	None.
;
; History     :	Version 1, 15-Apr-2005, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;
function valid_wcs, wcs
on_error, 2
;
;  Currently, WCS must be scalar.
;
if n_elements(wcs) ne 1 then return, 0b
;
;  The input must be a structure.
;
if not is_struct(wcs) then return, 0b
;
;  Check to see if the required tags are present.
;
if not tag_exist(wcs, /top_level, 'COORD_TYPE') then return, 0b
if not tag_exist(wcs, /top_level, 'WCSNAME')    then return, 0b
if not tag_exist(wcs, /top_level, 'VARIATION')  then return, 0b
if not tag_exist(wcs, /top_level, 'COMPLIANT')  then return, 0b
if not tag_exist(wcs, /top_level, 'PROJECTION') then return, 0b
if not tag_exist(wcs, /top_level, 'NAXIS')      then return, 0b
if not tag_exist(wcs, /top_level, 'IX')         then return, 0b
if not tag_exist(wcs, /top_level, 'IY')         then return, 0b
if not tag_exist(wcs, /top_level, 'CRPIX')      then return, 0b
if not tag_exist(wcs, /top_level, 'CTYPE')      then return, 0b
if not tag_exist(wcs, /top_level, 'CUNIT')      then return, 0b
;
;  Check for tags based on the value of VARIATION.
;
case strupcase(wcs.variation) of
    'PC': begin
        if not tag_exist(wcs, /top_level, 'CDELT') then return, 0b
        if not tag_exist(wcs, /top_level, 'PC')    then return, 0b
    endcase
    'CD': if not tag_exist(wcs, 'CD')  then return, 0b
    'CROTA': begin
        if not tag_exist(wcs, /top_level, 'ROLL_ANGLE') then return, 0b
        if not tag_exist(wcs, /top_level, 'CDELT')      then return, 0b
        if not tag_exist(wcs, /top_level, 'PC')         then return, 0b
    endcase
    else: return, 0b
endcase
;
;  If we got this far, the structure must be valid.
;
return, 1b
end
