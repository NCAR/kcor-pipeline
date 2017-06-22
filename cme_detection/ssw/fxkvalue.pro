;---------------------------------------------------------------------------
; Document name: fxkvalue.pro
; Created by:    Liyun Wang, NASA/GSFC, February 8, 1995
;
; Last Modified: Wed Feb  8 15:14:26 1995 (lwang@achilles.nascom.nasa.gov)
;---------------------------------------------------------------------------
;
FUNCTION fxkvalue, header, strvec
;+
; PROJECT:
;       SOHO - CDS
;
; NAME:	
;       FXKVALUE()
;
; PURPOSE:
;       Get value from a set of candidate keywords of a FITS header 
;
; EXPLANATION:
;       This function routine calls FXPAR to determine the value of one of a
;       set of candidate keywords by searching though the given FITS header in
;       the order of given keyword list. The returned value corresponds to
;       that of the keyword that is matched first.
;
; CALLING SEQUENCE: 
;       Result = fxkvalue(header, string_vec)
;
; INPUTS:
;       HEADER - The FITS header returned by FXREAD
;       STRVEC - A string vector (or scalar) containing all posible keywords
;                for the concerned parameter
;
; OPTIONAL INPUTS: 
;       None.
;
; OUTPUTS:
;       Result - Value extracted from the FITS header who's keyword matches 
;                the one in STRVEC first. If no keyword is matched, the
;                returned result will be a null string, and at the same time
;                the system variable !err is set to -1.
;
; OPTIONAL OUTPUTS:
;       None.
;
; KEYWORD PARAMETERS: 
;       None.
;
; CALLS:
;       FXPAR, DATATYPE
;
; COMMON BLOCKS:
;       None.
;
; RESTRICTIONS: 
;       None.
;
; SIDE EFFECTS:
;       System variable !err is set to -1 if no keyword is matched.
;
; CATEGORY:
;       
; PREVIOUS HISTORY:
;       Written February 8, 1995, Liyun Wang, NASA/GSFC
;
; MODIFICATION HISTORY:
;       Version 1, created, Liyun Wang, NASA/GSFC, February 8, 1995
;
; VERSION:
;       Version 1, February 8, 1995
;-
;
   ON_ERROR, 2
   IF datatype(header) NE 'STR' OR datatype(strvec) NE 'STR' THEN BEGIN
      PRINT, 'Invalid data type. Expect to parameter of string type.'
      RETURN, ''
   ENDIF
   FOR i = 0, N_ELEMENTS(strvec)-1 DO BEGIN
      value = fxpar(header,strvec(i))
      IF !err NE -1 THEN RETURN, value
   ENDFOR
   !err = -1
   RETURN, ''
END

;---------------------------------------------------------------------------
; End of 'fxkvalue.pro'.
;---------------------------------------------------------------------------
