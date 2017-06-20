;+
; Project     : SOHO - CDS
;
; Name        : FREE_POINTER()
;
; Purpose     : to free a pointer variable
;
; Category    : Help
;
; Explanation : removes a pointer variable.
;
; Syntax      : IDL> free_pointer(pointer)
;
; Inputs      :  POINTER = pointer variable
;
; Opt. Inputs : None
;
; Outputs     : None
;
; Opt. Outputs: None
;
; Keywords    : None
;
; Common      : None
;
; Restrictions: POINTER becomes invalid
;
; Side effects: None
;
; History     : Version 1,  1-Sep-1995,  D.M. Zarro.  Written
;               Version 2, 17-Jul-1997, D.M. Zarro. Modified
;                 -- Updated to version 5 pointers
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

pro free_pointer,pointer

if not exist(pointer) then return

;-- array input?

np=n_elements(pointer)
if np gt 1 then begin
 for i=0,np-1 do free_pointer,pointer(i)
 return
endif

;-- valid pointer?

valid=valid_pointer(pointer,type)
if valid then begin
 case type of
  0: xkill,pointer
  1: handle_free,pointer
  2: ptr_free,pointer
 else: do_nothing=1
 endcase
endif

return & end
