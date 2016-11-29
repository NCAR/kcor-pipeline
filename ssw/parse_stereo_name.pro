;+
; Project     :	STEREO - SSC
;
; Name        :	PARSE_STEREO_NAME
;
; Purpose     :	Parses spacecraft name for SPICE input
;
; Category    :	STEREO, Orbit
;
; Explanation :	This routine parses various versions of the names of the two
;               STEREO observatories into an input usable by the SPICE
;               software.
;
; Syntax      :	Output = PARSE_STEREO_NAME( SPACECRAFT, Default )
;
; Examples    :	SC = PARSE_STEREO_NAME( SPACECRAFT, ['Ahead', 'Behind'])
;
; Inputs      :	SPACECRAFT = Can be one of the following forms:
;
;                               'A'             'B'
;                               'STA'           'STB'
;                               'Ahead'         'Behind'
;                               'STEREO Ahead'  'STEREO Behind'
;                               'STEREO-Ahead'  'STEREO-Behind'
;                               'STEREO_Ahead'  'STEREO_Behind'
;
;                            Case is not important, and abbreviations are
;                            possible.  If not one of the above forms, the
;                            original string is returned, trimmed and converted
;                            to uppercase.
;
;               DEFAULT = Two-element string array containing the default
;                         values for the two spacecraft.  When the spacecraft
;                         name is recognized, the returned will be the
;                         appropriate element of DEFAULT.
;
; Opt. Inputs :	None.
;
; Outputs     :	The result of the function is the spacecraft name to be passed
;               to SPICE.
;
; Opt. Outputs:	None.
;
; Keywords    : None.
;
; Calls       :	None.
;
; Common      :	None.
;
; Restrictions:	None.
;
; Side effects:	None.
;
; Prev. Hist. :	Based on code embedded in various routines.
;
; History     :	Version 1, 01-Sep-2006, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;
function parse_stereo_name, spacecraft, default
on_error, 2
;
;  Check the input values.
;
if n_elements(spacecraft) ne 1 then message, $
  'SPACECRAFT must be a scalar'
if n_elements(default) ne 2 then message, $
  'DEFAULT must have two elements'
;
;  Convert the input into a trimmed, uppercase string.
;
sc = strtrim(strupcase(spacecraft),2)
n = strlen(sc)
;
;  If the string is recognized, then return the appropriate default value.
;
if (sc eq strmid('AHEAD',0,n)) or $
  (sc eq strmid('STEREO AHEAD',0,n)) or $
  (sc eq strmid('STEREO-AHEAD',0,n)) or $
  (sc eq strmid('STEREO_AHEAD',0,n)) or $
  (sc eq 'STA') then sc = default[0]
;
if (sc eq strmid('BEHIND',0,n)) or $
  (sc eq strmid('STEREO BEHIND',0,n)) or $
  (sc eq strmid('STEREO-BEHIND',0,n)) or $
  (sc eq strmid('STEREO_BEHIND',0,n)) or $
  (sc eq 'STB') then sc = default[1]
;
return, sc
end
