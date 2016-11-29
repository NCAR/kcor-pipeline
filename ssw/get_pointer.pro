;+
; Project     : SOHO - CDS
;
; Name        : GET_POINTER()
;
; Purpose     : to get a pointer value from a pointer variable
;
; Category    : Help
;
; Explanation : retrieves a pointer value from a pointer variable.
;
; Syntax      : IDL> value = get_pointer(pointer)
;
; Inputs      : POINTER = pointer variable
;
; Opt. Inputs : None
;
; Outputs     : Value associated with POINTER
;
; Opt. Outputs: None
;
; Keywords    : NOCOPY   -  do not make internal copy of value
;             : UNDEFINED - 0/1 if returned value is defined/undefined
;
; Common      : None
;
; Restrictions: POINTER must be defined via MAKE_POINTER
;
; Side effects: memory value of POINTER is removed when /NO_COPY set
;
; History     : Version 1,  1-Sep-1995,  D.M. Zarro.  Written
;               Version 2,  17-July-1997,  D.M. Zarro. Modified
;                -- Updated to version 5 pointers
;               Version 3,  17-Nov-1999,  D.M. Zarro. Modified
;                -- Added check for allocated heap variable in pointer
;               24-Jan-2007, Zarro (ADNET/GSFC)
;                 - removed EXECUTE
;    
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

function get_pointer,pointer,no_copy=no_copy,$
         undefined=undefined,quiet=quiet,status=status

;-- check if pointer is valid

status=0

valid=valid_pointer(pointer,type)
if (n_elements(valid) eq 1) then begin
 case type of
  0: widget_control,pointer,get_uvalue=value,no_copy=keyword_set(no_copy)
  1: handle_value,pointer,value,no_copy=keyword_set(no_copy)
  2: begin
      has_val=0b
      alloc=call_function('ptr_valid',pointer)
      if alloc then has_val=n_elements(*pointer) ne 0
      if has_val then begin
       if keyword_set(no_copy) then value=temporary(*pointer) else $
        value=*pointer
      endif
     end
 else: do_nothing=1
 endcase
endif else begin
 if not keyword_set(quiet) then begin
  dprint,'% GET_POINTER: invalid pointer passed to '+get_caller()
 endif
endelse

status=exist(value)
undefined=1-status
if undefined then value=-1

return,value & end
