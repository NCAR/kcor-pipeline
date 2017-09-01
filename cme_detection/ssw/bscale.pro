	PRO BSCALE,IMAGE,NOSCALE=NOSCALE,MISSING=MISSING,MAX=MAX,MIN=MIN, $
		TOP=TOP,BOTTOM=BOTTOM,VELOCITY=VELOCITY,COMBINED=COMBINED, $
                LOWER=LOWER
;+
; Project     : SOHO - CDS
;
; Name        : 
;	BSCALE
; Purpose     : 
;	Scale images into byte arrays suitable for displaying.
; Explanation : 
;	Depending on the keywords passed, the routine BYTSCLI, FORM_INT or
;	FORM_VEL is used to scale the image.
; Use         : 
;	BSCALE, IMAGE
; Inputs      : 
;	IMAGE	= Image to be scaled.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	IMAGE	= The scaled image is returned in place of the original.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	NOSCALE  = If set, then the image is not scaled.
;	MISSING	 = Value flagging missing pixels.  These points are scaled to
;		   zero.
;	MAX	 = The maximum value of IMAGE to be considered in scaling the
;		   image, as used by BYTSCL.  The default is the maximum value
;		   of IMAGE.
;	MIN	 = The minimum value of IMAGE to be considered in scaling the
;		   image, as used by BYTSCL.  The default is the minimum value
;		   of IMAGE.
;	TOP	 = The maximum value of the scaled image array, as used by
;		   BYTSCL.  The default is !D.TABLE_SIZE-1.
;	BOTTOM	 = The minimum value of the scaled image array, as used by
;		   BYTSCL.  The default is 0.
;	VELOCITY = If set, then the image is scaled using FORM_VEL as a
;		   velocity image.  Can be used in conjunction with COMBINED
;		   keyword.  Ignored if NOSCALE is set.
;	COMBINED = Signals that the image is to be displayed in one of two
;		   combined color tables.  Can be used by itself, or in
;		   conjunction with the VELOCITY or LOWER keywords.
;	LOWER	 = If set, then the image is placed in the lower part of the
;		   color table, rather than the upper.  Used in conjunction
;		   with COMBINED keyword.
; Calls       : 
;	BYTSCLI, FORM_INT, FORM_VEL, GET_IM_KEYWORD, IM_KEYWORD_SET,
;	WHERE_MISSING, GOOD_PIXELS
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
;	None.
; Category    : 
;	Utilities, Image_display.
; Prev. Hist. : 
;	William Thompson, May 1992.
;	William Thompson, August 1992, renamed BADPIXEL to MISSING.
;	William Thompson, September 1992, use COMBINED keyword in place of
;					  INTENSITY.
; Written     : 
;	William Thompson, GSFC, May 1992.
; Modified    : 
;	Version 1, William Thompson, GSFC, 14 May 1993.
;		Incorporated into CDS library.
;	Version 2, William Thompson, GSFC, 14 June 1993.
;		Added support for monochrome (dithered) devices.
;	Version 3, William Thompson, GSFC, 22 October 1993.
;		Modified to call BYTSCLI instead of BYTSCL.
;	Version 4, William Thompson, GSFC, 17 July 1996
;		Fixed bug when image contains nothing but missing pixels.
;	Version 5, William Thompson, GSFC, 8 December 1997
;		Pass TOP to FORM_INT and FORM_VEL.
;	Version 6, William Thompson, GSFC, 6 January 1998
;		Corrected interaction between MIN and MISSING
;	Version 7, Zarro (SAC/GSFC), 1 March 1998
;		Threw in calls to TEMPORARY for better memory management
;       Version 8, William Thompson, GSFC, 29 April 2005
;               Use WHERE_MISSING, GOOD_PIXELS to treat NaN values
;       Version 9, William Thompson, GSFC, 3 Jan 2006
;               Added keyword BOTTOM, remove call to EXECUTE
;       Version 10, Zarro, ADNET, 13 Sept 2010
;               Changed image() to image[] to avoid collision with
;               IDL version 8 image function.
;-
;
	ON_ERROR,2
	GET_IM_KEYWORD, MISSING, !IMAGE.MISSING
;
	IF N_PARAMS() EQ 0 THEN MESSAGE,'Syntax:  Result = BSCALE( IMAGE )'
;
;  Find out how to scale the image.  The possibilities are either no scaling,
;  intensity scaling, velocity scaling, or ordinary scaling.  The default is
;  the last.
;
	IF IM_KEYWORD_SET(NOSCALE,!IMAGE.NOSCALE) THEN RETURN
;
;  Velocity scaling.
;
	IF KEYWORD_SET(VELOCITY) THEN BEGIN
		IMAGE = FORM_VEL(TEMPORARY(IMAGE),MIN=MIN,MAX=MAX,MISSING=MISSING, $
			COMBINED=COMBINED,TOP=TOP,BOTTOM=BOTTOM)
;
;  Intensity scaling (for combining with velocity images).
;
	END ELSE IF IM_KEYWORD_SET(COMBINED,!IMAGE.COMBINED) OR		$
			KEYWORD_SET(LOWER) THEN BEGIN
		IMAGE = FORM_INT(TEMPORARY(IMAGE),MIN=MIN,MAX=MAX,MISSING=MISSING, $
			LOWER=LOWER,TOP=TOP,BOTTOM=BOTTOM)
;
;  Ordinary scaling.  First, set any missing pixels to the mininum of the good
;  array.
;
	END ELSE BEGIN
                WMISSING = WHERE_MISSING(IMAGE, NMISSING, MISSING=MISSING)
                IF NMISSING GT 0 THEN BEGIN
                    IMIN = MIN(GOOD_PIXELS(IMAGE, MISSING=MISSING))
                    IMAGE[WMISSING] = IMIN
		ENDIF
;
;  Get the MIN and MAX values, if any.
;
		GET_IM_KEYWORD,MAX,!IMAGE.MAX
		GET_IM_KEYWORD,MIN,!IMAGE.MIN
;
;  The default top color depends on whether the device is monochrome or not.
;
		MAXCOLOR = !D.TABLE_SIZE - 1
		IF MAXCOLOR EQ 1 THEN MAXCOLOR = 255
		GET_IM_KEYWORD, TOP, !IMAGE.TOP
		IF N_ELEMENTS(TOP) EQ 1 THEN MAXCOLOR=TOP
;
;  Subtract BOTTOM from MAXCOLOR
;
                MINCOLOR = 0B
                IF TAG_EXIST(!IMAGE,'BOTTOM') THEN $
                  GET_IM_KEYWORD, BOTTOM, !IMAGE.BOTTOM
                IF N_ELEMENTS(BOTTOM) EQ 1 THEN MINCOLOR = BYTE(BOTTOM)
                MAXCOLOR = (MAXCOLOR - MINCOLOR) > 1B
;
;  Use BYTSCLI to scale the image.
;
                IMAGE = BYTSCLI(TEMPORARY(IMAGE), MAX=MAX, MIN=MIN, $
                                TOP=MAXCOLOR) + MINCOLOR
;
;  If missing pixels were detected, then set them to zero.
;
		IF NMISSING GT 0 THEN IMAGE[WMISSING] = 0B
	ENDELSE
;
	RETURN
	END
