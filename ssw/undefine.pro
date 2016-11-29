PRO undefine, a

;+
; $Id: undefine.pro,v 1.2 2008/02/15 22:49:30 nathan Exp $
; Project	: SOHO - LASCO/EIT, STEREO - SECCHI
;
; Name		: UNDEFINE
;
; Purpose	: change a variable to type 'UND' (undefined)
;
; Category	: Utilities, Array
;
; Explanation	: 
;
; Syntax	: undefine, a
;
; Examples      :
;
; Inputs	: 
;
; Opt. Inputs	: 
;
; Outputs	: 
;
; Opt. Outputs	:
;
; Keywords	: 
;
; Common	:
;
; Restrictions  : None.
;
; Side effects	: None.
;
; History	: 12 jun 1993,Alo Eple, MPAe,Written
;
; $Log: undefine.pro,v $
; Revision 1.2  2008/02/15 22:49:30  nathan
; updated comment
;
; Revision 1.1  2008/02/15 20:45:53  nathan
; moved from lasco/idl/display
;
; Contact	:
;-
;


IF datatype(a) EQ 'UND' THEN RETURN

a0 = TEMPORARY(a)

RETURN

END
