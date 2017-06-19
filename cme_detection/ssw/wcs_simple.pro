;+
; Project     :	STEREO
;
; Name        :	WCS_SIMPLE()
;
; Purpose     :	Determines if a WCS structure is simple.
;
; Category    :	FITS, Coordinates, WCS
;
; Explanation :	This procedure examines the FITS World Coordinate System
;               structure from FITSHEAD2WCS, and determines whether or not the
;               structure can be described as "simple".  A simple WCS has the
;               following properties:
;
;                       * The first dimension is longitude (X)
;                       * The second dimension is latitude (Y)
;                       * The coordinate system is Helioprojective-Cartesian
;                         or Heliocentric-Cartesian
;                       * The projection is either "TAN" or blank.
;                       * The CDELT and ROLL_ANGLE tags are present, e.g. from
;                         WCS_DECOMP_ANGLE.
;
; Syntax      :	Result = WCS_SIMPLE( WCS )
;
; Examples    :	IF WCS_SIMPLE( WCS) THEN ...
;
; Inputs      :	WCS = Structure from FITSHEAD2WCS
;
; Opt. Inputs :	None.
;
; Outputs     :	The result of the function is 1 if the input is recognized as a
;               simple WCS structure, 0 otherwise.
;
; Opt. Outputs:	None.
;
; Keywords    :	ADD_TAG = If set, then the tag SIMPLE is added to the
;                         structure, containing the result.
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
; History     :	Version 1, 15-Apr-2005, William Thompson, GSFC
;               Version 2, 25-Apr-2005, William Thompson, GSFC
;                       Fixed problem with recompiling
;
; Contact     :	WTHOMPSON
;-
;
function wcs_simple, wcs, add_tag=k_add_tag
on_error, 2
;
if n_params() ne 1 then message, 'Syntax: Result = WCS_SIMPLE( WCS )'
if not valid_wcs(wcs) then message, 'Input not recognized as WCS structure'
;
;  Assume the WCS is not simple, until proved otherwise.
;
simple = 0b
;
;  Test against the above criteria.
;
if wcs.ix ne 0 then goto, finish
if wcs.iy ne 1 then goto, finish
coord_type = strtrim(strupcase(wcs.coord_type),2)
if (coord_type ne 'HELIOPROJECTIVE-CARTESIAN') and $
   (coord_type ne 'HELIOCENTRIC-CARTESIAN') then goto, finish
projection = strtrim(strupcase(wcs.projection),2)
if (projection ne 'TAN') and (projection ne '') then goto, finish
if not tag_exist(wcs, 'CDELT', /top_level) then goto, finish
if not tag_exist(wcs, 'ROLL_ANGLE', /top_level) then goto, finish
;
;  If we got this far, the WCS can be described as simple.
;
simple = 1b
;
;  Add the SIMPLE tag, if requested.
;
FINISH:
if keyword_set(k_add_tag) then begin
    if tag_exist(wcs,'SIMPLE',/top_level) then wcs.simple = simple else $
      wcs = add_tag(wcs,simple,'SIMPLE',/top_level)
endif
;
return, simple
end
