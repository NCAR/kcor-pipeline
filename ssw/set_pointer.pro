;+
; Project     : SOHO - CDS
;
; Name        : SET_POINTER
;
; Purpose     : to set a pointer value to a pointer variable
;
; Category    : Pointers
;
; Explanation : assign a pointer value to a pointer variable.
;
; Syntax      : IDL> set_pointer,pointer,value
;
; Inputs      : POINTER = pointer variable
;             : VALUE = value to assign
;
; Keywords    : NOCOPY   -  do not make internal copy of value
;               INDEX - index of pointer array to set value to
;
; Restrictions: POINTER must be defined via MAKE_POINTER
;
; Side effects: external value of POINTER is removed when /NO_COPY set
;
; History     : Version 1,  1-Sep-1995,  D.M. Zarro.  Written
;               Version 2, 17-Jul-1997, D.M. Zarro. Modified
;                 -- Updated to version 5 pointers 
;               Version 3, 18-May-2002, Zarro (L-3Com/GSFC) 
;                 -- Added check for invalid input pointer
;               24-Jan-2007, Zarro (ADNET/GSFC)
;                 - removed EXECUTE
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

pro set_pointer,pointer,value,no_copy=no_copy,index=index

if not exist(value) then begin
 message,'SYNTAX --> set_pointer,pointer,value,[/no_copy]',/cont
 return
endif

;-- check if a real pointer

if datatype(pointer) eq 'PTR' then begin
 type=2 & ptr_alloc,pointer & valid=1b
endif else valid=valid_pointer(pointer,type)

if valid then begin
 case type of
  0: widget_control,pointer,set_uvalue=value,no_copy=keyword_set(no_copy)
  1: handle_value,pointer,value,no_copy=keyword_set(no_copy),/set
  2: begin
      if keyword_set(no_copy) then arg='temporary(value)' else arg='value'
      ind=0
      if exist(index) then begin
       np=n_elements(pointer)
       if (index ge np) or (index lt 0) then begin
        message,'Input index out of range',/cont
        return
       endif
       ind=index
      endif
      if keyword_set(copy) then *pointer[ind]=temporary(value) else $
       *pointer[ind]=value
     end
 else: do_nothing=1
 endcase
endif else dprint,'%SET_POINTER: input pointer is invalid'

return & end
