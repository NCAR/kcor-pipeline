	FUNCTION AVERAGE, ARRAY, DIMENSION, MISSING=MISSING
;+
; Project     : SOHO - CDS
;
; Name        : 
;	AVERAGE()
; Purpose     : 
;	Averages an array over one or all of its dimensions.
; Explanation : 
;	Calculates the average value of an array, or calculates the average
;	value over one dimension of an array as a function of all the other
;	dimensions.
; Use         : 
;	Result = AVERAGE( ARRAY )
;	Result = AVERAGE( ARRAY, DIMENSION )
;	Result = AVERAGE( ARRAY, [Dim1, Dim2, ... ] )
; Inputs      : 
;	ARRAY	  = Input array.  May be any type except string or structure.
; Opt. Inputs : 
;	DIMENSION = Optional dimension to do average over.  Valid inputs are 1
;		    through the total number of dimensions of ARRAY.
; Outputs     : 
;	The average value of the array when called with one parameter.
;
;	If DIMENSION is passed, then the result is an array with all the
;	dimensions of the input array except for the dimension specified,
;	each element of which is the average of the corresponding vector
;	in the input array.
;
;	For example, if A is an array with dimensions of (3,4,5), then the
;	command B = AVERAGE(A,2) is equivalent to
;
;		B = FLTARR(3,5)
;		FOR J = 0,4 DO BEGIN
;		    FOR I = 0,2 DO BEGIN
;			B(I,J) = TOTAL( A(I,*,J) ) / 4.
;		    ENDFOR
;		ENDFOR
;
;	It is also possible to pass an array of dimensions.  The dimensions are
;	processed in reverse order.  For example,
;
;		B = AVERAGE(A, [1,3])
;
;	is equivalent to
;
;		B = AVERAGE(A, 3)
;		B = AVERAGE(B, 1)
;
; Opt. Outputs: 
;	None.
; Keywords    : 
;	MISSING	= Value signifying missing pixels.  Any pixels with this value
;		  are not included in the average.  If there are no non-missing
;		  pixels, then MISSING is returned.
; Calls       : 
;	IS_NOT_MISSING, WHERE_MISSING, WHERE_NOT_MISSING, FLAG_MISSING
; Common      : 
;	None.
; Restrictions: 
;	The dimension specified must be valid for the array passed.
; Side effects: 
;	None.
; Category    : 
;	Utilities, Arrays.
; Prev. Hist. : 
;	Taken from an earlier routine by W. Thompson called AVG, but the
;	definition of the DIMENSION parameter is different to be consistent
;	with current usage in IDL.
; Written     : 
;	William Thompson, GSFC, 9 April 1993.
; Modified    : 
;	Version 1, William Thompson, GSFC, 9 April 1993.
;	Version 2, William Thompson, GSFC, 3 February 1996
;		Added missing keyword.
;	Version 3, 03-Jul-2000, William Thompson, GSFC
;		Modified to use /DOUBLE with TOTAL.  However, the answer
;		retains the datatype of the previous version of this routine.
;	Version 4, 14-Nov-2000, William Thompson, GSFC
;		Modified to also support version 4.
;	Version 5, 16-Nov-2001, William Thompson, GSFC
;		Allow DIMENSION to be a vector.
;	Version 6, 16-Apr-2002, William Thompson, GSFC
;		Fix bug when trailing dimensions are 1.
;       Version 7, 29-Apr-2005, William Thompson, GSFC
;               Handle NaN values
;       Version 8, 1-Jul-2005, William Thompson, GSFC
;               Fixed bug when entire array is missing
; Version     : 
;	Version 8, 1-Jul-2005
;-
;
	ON_ERROR,2
;
;  Check the input parameters.
;
	IF N_PARAMS() LT 1 THEN MESSAGE,	$
		'Syntax:  Result = AVERAGE( ARRAY  [, DIMENSION ] )'
	IF N_ELEMENTS(ARRAY) EQ 0 THEN MESSAGE,	$
		'ARRAY not defined'
;
;  Dimension not passed.  Return a simple average.  If the keyword MISSING was
;  sent, then only average together the points not equal to the missing value.
;  If there are no non-missing pixels, then return the missing value.
;
	IF N_PARAMS(0) EQ 1 THEN BEGIN
	    AVER = ARRAY(0) * 1.0
            W = WHERE_NOT_MISSING(ARRAY,MISSING=MISSING,COUNT)
            IF COUNT EQ 0 THEN AVER[0] = ARRAY[0] ELSE $
              AVER[0] = TOTAL(ARRAY[W],/DOUBLE) / COUNT
;
;  Dimension passed.  Check DIMENSION, and make sure that ARRAY is an array.
;
	END ELSE BEGIN
		IF N_ELEMENTS(DIMENSION) EQ 0 THEN BEGIN
			MESSAGE,'DIMENSION not defined'
		END ELSE IF N_ELEMENTS(DIMENSION) GT 1 THEN BEGIN
		    DIM = REVERSE(DIMENSION(SORT(DIMENSION)))
		    RETURN, AVERAGE( AVERAGE(ARRAY,DIM(0),MISSING=MISSING), $
			    DIM(1:*), MISSING=MISSING)
		ENDIF
		S = SIZE(ARRAY)
		IF S(0) EQ 0 THEN MESSAGE,'ARRAY must be an array'
;
;  Return an array collapsed along one of the dimensions.
;
		DIM = DIMENSION(0)
		IF (DIM GE 1) AND (DIM LE S(0)) THEN BEGIN
;
;  Create an array with the right dimensions, of at least floating point type.
;
		    SZ = SIZE(ARRAY)
		    TYPE = SZ(SZ(0)+1) > 4
		    SZ = SZ(WHERE(INDGEN(N_ELEMENTS(SZ)) NE DIM))
		    AVER = MAKE_ARRAY(TYPE=TYPE, DIMENSION=SZ(1:SZ(0)-1), $
			    /NOZERO)
;
;  Start by calculating the numerator, substituting 0 wherever the missing
;  pixel flag is seen.
;
                    TEMP = ARRAY
                    W = WHERE_MISSING(ARRAY, MISSING=MISSING, COUNT)
                    IF COUNT GT 0 THEN TEMP(W) = 0
                    SZ = SIZE(TEMP)
                    IF SZ(0) LT DIM THEN	$
                      AVER(0,0,0,0,0,0,0) = TEMP	ELSE $
                      AVER(0,0,0,0,0,0,0) = TOTAL(TEMP, DIM, /DOUBLE)
;
;  Next calculate the denominator as the total number of points which are good.
;  Substitute the MISSING pixel value where-ever there are no good pixels to
;  average together.
;
                    TEMP = IS_NOT_MISSING(ARRAY, MISSING=MISSING)
                    IF SZ(0) LT DIM THEN DENOM = TEMP ELSE $
                                         DENOM = TOTAL(TEMP, DIM)
                    AVER = TEMPORARY(AVER) / (DENOM > 1)
                    W = WHERE(DENOM EQ 0, COUNT)
                    IF COUNT GT 0 THEN FLAG_MISSING, AVER, W, MISSING=MISSING
		END ELSE BEGIN
			MESSAGE,'Dimension out of range'
		ENDELSE
	ENDELSE
;
	RETURN, AVER
	END
