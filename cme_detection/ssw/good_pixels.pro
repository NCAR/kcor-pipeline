	FUNCTION GOOD_PIXELS,ARRAY,MISSING=MISSING
;+
; Project     : SOHO - CDS
;
; Name        : 
;	GOOD_PIXELS()
; Purpose     : 
;	Returns all the good (not missing) pixels in an image.
; Explanation : 
;	Returns a vector array containing only those pixels that are finite
;	(e.g. not NaN), and not equal to the missing pixel flag value.  Mainly
;	used for statistical purposes, e.g. PLOT_HISTO,GOOD_PIXELS(A).  The
;	missing pixel flag can be set either with the MISSING keyword, or with
;	the SETFLAG,MISSING=...  command.
; Use         : 
;	Result = GOOD_PIXELS( ARRAY, <keywords> )
; Inputs      : 
;	ARRAY	= Array to extract pixels from.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	Result of function is a linear array containing the values of all
;	pixels that are not flagged as missing.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	MISSING = Value flagging missing pixels.
; Calls       : 
;	GET_IM_KEYWORD
; Common      : 
;	None.
; Restrictions: 
;	In general, the SERTS image display routines use several non-standard
;	system variables.  These system variables are defined in the procedure
;	IMAGELIB.  It is suggested that the command IMAGELIB be placed in the
;	user's IDL_STARTUP file.
;
;	Some routines also require the SERTS graphics devices software,
;	generally found in a parallel directory at the site where this software
;	was obtained.  Those routines have their own special system variables.
;
; Side effects: 
;	If no pixels are missing, then the original undisturbed array is
;	returned.
; Category    : 
;	Utilities, Image_display.
; Prev. Hist. : 
;	William Thompson, July 1991.
;	William Thompson, August 1992, renamed BADPIXEL to MISSING.
; Written     : 
;	William Thompson, GSFC, July 1991.
; Modified    : 
;	Version 1, William Thompson, GSFC, 13 May 1993.
;		Incorporated into CDS library.
;	Version 2, William Thompson, GSFC, 30 April 1996
;		If there are no non-missing pixels, then return the missing
;		pixel flag value.
;       Version 3, William Thompson, GSFC, 29 April 2005
;               Also use FINITE() function.
; Version     : 
;	Version 3, 29 April 2005
;-
;
	GET_IM_KEYWORD, MISSING, !IMAGE.MISSING
;
	IF N_ELEMENTS(MISSING) EQ 1 THEN $
            W = WHERE((ARRAY NE MISSING) AND FINITE(ARRAY), COUNT)  ELSE $
            W = WHERE(FINITE(ARRAY), COUNT)
        IF COUNT EQ N_ELEMENTS(ARRAY) THEN RETURN, ARRAY ELSE $
          IF COUNT GT 0 THEN RETURN, ARRAY[W] ELSE $
          RETURN, ARRAY[0]
;
	END
