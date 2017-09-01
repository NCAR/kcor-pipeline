	FUNCTION POLY_FIT_MOST, X, Y, NDEGREE, YFIT, WEIGHT=WGT,	$
		THRESHOLD=K_THRESHOLD, DOUBLE=DOUBLE, USED=WLAST
;+
; Project     :	SOHO - CDS
;
; Name        :	POLY_FIT_MOST()
;
; Purpose     :	Fit a polynomial to a curve, ignoring outriders.
;
; Category    :	Fitting, Class4
;
; Explanation :	Polynomial fits are applied in a reiterative process, where
;		points more than 2 sigma away from the fit are removed after
;		each iteration.
;
; Syntax      :	PARAM = POLY_FIT_MOST(X, Y, NDEGREE  [, YFIT ])
;
; Examples    :	Use like POLY_FIT or POLYFITW.
;
; Inputs      :	X	= The independent variable vector
;		Y	= The dependent variable vector
;		NDEGREE	= The degree of the polynomial, e.g. 1 for a linear
;			  fit.  This can also be set to 0 to fit a simple
;			  average (unlike POLY_FIT or POLYFITW).
;
; Opt. Inputs :	None.
;
; Outputs     :	The result of the function contains the parameters of the
;		polynomial fit.
;
; Opt. Outputs:	YFIT	= The array of fitted values.
;
; Keywords    :	WEIGHT	= An array of weights to use.  If the WEIGHT keyword is
;			  passed, then POLYFITW is called instead of POLY_FIT.
;
;		DOUBLE	= If set, then the calculation is done in double
;			  precision.  (Recommended)
;
;		THRESHOLD = The multiplier of the standard deviation used to
;			    determine which points should be filtered out.  The
;			    default is 2.
;
;		USED	= Returns the indices of the points used to calculate
;			  the fit.
;
; Calls       :	POLY_FIT, POLYFITW
;
; Common      :	None.
;
; Restrictions:	None.
;
; Side effects:	None.
;
; Prev. Hist. :	None.
;
; History     :	Version 1, 18 February 1998, William Thompson, GSFC
;		Version 2, 01-May-2000, William Thompson, GSFC
;			Added keyword THRESHOLD
;		Version 3, 18-Oct-2000, William Thompson, GSFC
;			Added keyword DOUBLE
;		Version 4, 09-Apr-2002, William Thompson, GSFC
;			Added keyword USED
;
; Contact     :	WTHOMPSON
;-
;
	ON_ERROR, 2
;
;  Check the input parameters.
;
	IF N_PARAMS() LT 3 THEN MESSAGE,		$
		'Syntax:  Result = POLY_FIT_MOST(X, Y, NDEGREE  [, YFIT ])'
	IF N_ELEMENTS(X) NE N_ELEMENTS(Y) THEN MESSAGE,	$
		'X and Y arrays must have the same number of elements'
	IF (N_ELEMENTS(WGT) GT 0) AND (N_ELEMENTS(WGT) NE N_ELEMENTS(X)) $
		THEN MESSAGE,	$
			'WEIGHTS must have same number of elements as X and Y'
	IF N_ELEMENTS(X) LE NDEGREE THEN MESSAGE,	$
		'Not enough points to fit'
;
	IF N_ELEMENTS(K_THRESHOLD) EQ 1 THEN THRESHOLD=K_THRESHOLD ELSE	$
		THRESHOLD = 2
;
	IF KEYWORD_SET(DOUBLE) THEN BEGIN
	    XX = DOUBLE(X)
	    YY = DOUBLE(Y)
	END ELSE BEGIN
	    XX = X
	    YY = Y
	ENDELSE
	IF N_ELEMENTS(WGT) GT 1 THEN BEGIN
	    WW = WGT
	    IF KEYWORD_SET(DOUBLE) THEN WW = DOUBLE(WW)
	ENDIF
	W = LINDGEN(N_ELEMENTS(XX))
;
	REPEAT BEGIN
	    N = N_ELEMENTS(W)
	    XXX = XX(W)
	    YYY = YY(W)
	    IF N_ELEMENTS(WGT) GT 1 THEN BEGIN
		WWW = WW(W)
		IF NDEGREE LE 0 THEN BEGIN
		    PARAM = TOTAL(YYY*WWW) / TOTAL(WWW)
		    YFIT = PARAM
		END ELSE PARAM = POLYFITW(XXX, YYY, WWW, NDEGREE, YFIT)
	    END ELSE IF NDEGREE LE 0 THEN BEGIN
		PARAM = AVERAGE(YYY)
		YFIT = PARAM
	    END ELSE PARAM = POLY_FIT(XXX, YYY, NDEGREE, YFIT)
	    IF NDEGREE GT 0 THEN PARAM = PARAM(*)
	    DIFF = YYY - YFIT
	    WLAST = W
	    WNEW = WHERE(ABS(DIFF) LT THRESHOLD*STDEV(DIFF), COUNT) 
	    IF COUNT GT 0 THEN W = W(WNEW)
	ENDREP UNTIL (N EQ N_ELEMENTS(W)) OR (W(0) EQ -1) OR	$
		N_ELEMENTS(W) LE NDEGREE
;
	IF N_PARAMS() EQ 4 THEN BEGIN
	    IF NDEGREE LE 0 THEN YFIT = REPLICATE(YFIT, N_ELEMENTS(X)) ELSE $
		    YFIT = POLY(X, PARAM)
	ENDIF
;
	RETURN, PARAM
	END
