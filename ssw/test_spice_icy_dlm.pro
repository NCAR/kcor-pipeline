;+
; Project     :	STEREO - SSC
;
; Name        :	TEST_SPICE_ICY_DLM()
;
; Purpose     :	Test to see if the SPICE/Icy DLM is available
;
; Category    :	STEREO, Orbit
;
; Explanation :	Calls CSPICE_B1950 via EXECUTE to see if the SPICE/Icy DLM is
;               available.
;
; Syntax      :	Result = TEST_SPICE_ICY_DLM()
;
; Examples    :	IF TEST_SPICE_ICY_DLM() THEN ... ELSE ...
;
; Inputs      :	None.
;
; Opt. Inputs :	None.
;
; Outputs     :	The result of the function is 1 if the DLM is available;
;               otherwise the result is 0.
;
; Opt. Outputs:	None.
;
; Keywords    :	None.
;
; Calls       :	None.
;
; Common      :	None.
;
; Restrictions:	None.
;
; Side effects:	None.
;
; Prev. Hist. :	None.
;
; History     :	Version 1, 15-Sep-2005, William Thompson, GSFC
;               Version 2, 29-Sep-2005, William Thompson, GSFC
;                       Removed QuietExecution argument for pre-6.1 compliance
;
; Contact     :	WTHOMPSON
;-
;
function test_spice_icy_dlm
return, execute('test = cspice_b1950()',1)
end
