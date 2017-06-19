;+
; Project     : SOHO - CDS
;
; Name        : MAKE_POINTER
;
; Purpose     : to make a pointer variable
;
; Category    : Help
;
; Explanation : creates a pointer variable.
;               Pointer variable can be a:
;               - unrealized WIDGET)
;               - HANDLE (version 3.6 or greater
;               - real POINTER (version 5 or greater)
;
; Syntax      : IDL> make_pointer,pointer
;
; Inputs      : None
;
; Opt. Inputs : None
;
; Outputs     : POINTER = pointer variable
;
; Opt. Outputs: CHILD = optional child of parent pointer is returned
;
; Keywords    : WIDGET =  force creating unrealized widget ID 
;               HANDLE =  force creating HANDLE
;               DIM = pointer dimensions 
;               STATUS = 1/0 if success/failuer
;
; Common      : None
;
; Restrictions: See explanation
;
; Side effects: None
;
; History     : Version 1,  1-Sep-1995,  D.M. Zarro.  Written
;               Version 2, 17-Jul-1997, D.M. Zarro. Modified
;                 -- Updated to version 5 pointers
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

pro make_pointer,pointer,child,dim=dim,widget=widget,handle=handle,$
                 status=status

dprint,'% make_pointer: '+get_caller()
vers=float(strmid(!version.release,0,3))

if not exist(dim) then ndim=1 else ndim=dim > 1
pointer=lonarr(ndim)
want_child=n_params() eq 2
if want_child then child=pointer

for i=0,ndim-1 do begin
 case 1 of
  (vers lt 3.6) or keyword_set(widget) : begin
   pointer(i)=widget_base()
   if want_child then child(i)=widget_base(pointer(i))
  end
  ((vers ge 3.6) and (vers lt 5)) or keyword_set(handle) : begin
   pointer(i)=call_function('handle_create')
   if want_child then child(i)=call_function('handle_create',pointer(i),/first_child)
  end
  (vers ge 5.) : pointer=call_function('ptrarr',ndim,/all)
  else: do_nothing=1
 endcase
endfor

if ndim eq 1 then begin
 pointer=pointer(0) 
 if exist(child) then child=child(0)
endif

status=valid_pointer(pointer)
return

end
