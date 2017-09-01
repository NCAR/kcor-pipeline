	PRO GET_VIEWPORT, SC1, SC2, SC3, SC4, CHARSIZE=CHARSIZE
;+
; Project     : SOHO - CDS
;
; Name        : 
;	GET_VIEWPORT
; Purpose     : 
;	Gets current viewport values, in device coordinates.
; Explanation : 
;	Gets the current values of the viewport, in the form of the
;	old-fashioned variables !SC1, !SC2, !SC3, and !SC4.  This supports
;	those routines that were originally developed for IDL version 1.
;
;	The routine calculates the system variables by generating a dummy plot
;	without actually drawing to the screen.
;
; Use         : 
;	GET_VIEWPORT, SC1, SC2, SC3, SC4
; Inputs      : 
;	None.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	SC1, SC2, SC3, SC4 are the device coordinates of the viewport.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	CHARSIZE = Character size to take into account when calculating plot
;		   size.
; Calls       : 
;	None.
; Common      : 
;	None.
; Restrictions: 
;	In general, the SERTS graphics devices routines use the special system
;	variables !BCOLOR and !ASPECT.  These system variables are defined in
;	the procedure DEVICELIB.  It is suggested that the command DEVICELIB be
;	placed in the user's IDL_STARTUP file.
;
; Side effects: 
;	None.
; Category    : 
;	Utilities, Devices.
; Prev. Hist. : 
;	William Thompson, November 1992.
;	William Thompson, November 1992, modified to get parameters by
;		generating a dummy plot rather than calculating directly, so as
;		to be compatible with !P.MULTI.
;	William Thompson, December 1992, corrected bug where certain system
;		variables were being changed by this routine.
; Written     : 
;	William Thompson, GSFC, November 1992.
; Modified    : 
;	Version 1, William Thompson, GSFC, 27 April 1993.
;		Incorporated into CDS library.
;	Version 2, William Thompson, GSFC, 12 January 1994.
;		Modified to avoid problems that may arise when !X.STYLE or
;		!Y.STYLE is not zero.
;	Version 3, William Thompson, GSFC, 8 October 1996
;		Added keyword CHARSIZE
;	Version 4, 14-May-2001, William Thompson, GSFC
;		Use modern system variables.
; Version     : 
;	Version 4, 14-May-2001
;-
;
	ON_ERROR, 2
;
;  Check the number of parameters.
;
	IF N_PARAMS() NE 4 THEN MESSAGE,	$
		'Syntax:  GET_VIEWPORT, SC1, SC2, SC3, SC4'
;
;  Save the current settings of the system variables.
;
	P = !P  &  X = !X  &  Y = !Y  &  Z = !Z
;
;  Determine the character size to use.
;
	IF N_ELEMENTS(CHARSIZE) EQ 1 THEN !P.CHARSIZE = CHARSIZE
;
;  Do a dummy plot.
;
	PLOT,[0,0],[1,1],/NODATA,XSTYLE=4,YSTYLE=4,TITLE='',/NOERASE
;
;  Get the values of !SC1, etc.
;
	SC1 = !X.WINDOW(0) * !D.X_SIZE
	SC2 = !X.WINDOW(1) * !D.X_SIZE
	SC3 = !Y.WINDOW(0) * !D.Y_SIZE
	SC4 = !Y.WINDOW(1) * !D.Y_SIZE
;
;  Restore the system variables.
;
	!P = P  &  !X = X  &  !Y = Y  &  !Z = Z
;
	RETURN
	END
