;+
; Project     : SOHO - CDS
;
; Name        : VALID_POINTER
;
; Purpose     : check if input pointer is a valid pointer
;
; Category    : Help
;
; Explanation : Prior to version 3.6, unrealized widget IDs could be
;               used as pointer variables. From 3.6 to version 4, handles
;               could be used as pointers. Version 5 now supports true 
;               pointers.
;
; Syntax      : IDL> valid=valid_pointer(pointer,type)
;
; Inputs      : POINTER = pointer variable
;
; Opt. Inputs : None
;
; Outputs     : VALID = 1/0 if valid/invalid pointer
;
; Opt. Outputs: TYPE = 0 if unrealized widget
;                    = 1 if handle
;                    = 2 if true pointer
;
; Keywords    : None
;
; Common      : None
;
; Restrictions: None
;
; Side effects: None
;
; History     : Version 1,  17-Jul-1997,  D.M. Zarro.  Written
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

function valid_pointer,pointer,type

type=-1
if not exist(pointer) then return,0

;-- array input?

np=n_elements(pointer)
if np gt 1 then begin
 valid=bytarr(np)
 type=intarr(np)
 for i=0,np-1 do begin
  valid(i)=valid_pointer(pointer(i),ptype)
  type(i)=ptype
 endfor
 return,valid
endif

vers=float(strmid(!version.release,0,3))

;-- check if a real pointer first

if (vers ge 5.) then begin
 valid=datatype(pointer) eq 'PTR'
 if valid then begin
  type=2
  return,valid
 endif
endif

;-- check if pointer is a valid handle 

if (vers ge 3.6) then begin
 if datatype(pointer) eq 'LON' then begin
  valid=call_function('handle_info',pointer,/valid_id)
  if valid then begin
   type=1
   return,valid
  endif
 endif
endif

;-- check if pointer is an unrealized widget

if xalive(pointer) then begin
 valid=1-widget_info(pointer,/realized)
 if valid then begin
  type=0
  return,valid
 endif
endif


return,0 & end
