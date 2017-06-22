;+
; Project     : HESSI
;
; Name        : PTR_ALLOC
;
; Purpose     : to allocate a heap variable to a null pointer
;
; Category    : Pointers
;
; Explanation : A pointer is useless without heap memory being
;               allocated to it when initialized.
;               This procedure attempts to rectify this.
;
; Syntax      : IDL> ptr_alloc,pointer
;
; Inputs      : POINTER = Pointer variable
;
; Outputs     : POINTER = Pointer variable with allocated memory
;
; History     : 17-Nov-1999,  D.M. Zarro (SM&A/GSFC) -  Written
;               17-May-2000, Zarro (EIT/GSFC) - added check for undefined
;               input
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

pro ptr_alloc,pointer

if n_elements(pointer) eq 0 then pointer=ptr_new(/all)

for i=0,n_elements(pointer)-1 do begin
 if ~(ptr_valid(pointer[i]))[0] then begin
  sz=size(pointer[i])
  ns=n_elements(sz)
  if sz[ns-2] eq 10 then ptr_free,pointer[i]
  temp_ptr=ptr_new(/all)
 endif else temp_ptr=pointer[i]
 if i eq 0 then new_ptr=temp_ptr else new_ptr=[new_ptr,temp_ptr]
endfor
pointer=new_ptr
return


end
