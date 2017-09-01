function struct2ssw, structs, data, nofill=nofill, loud=loud, _extra=_extra
;+
;   Name: struct2ssw
;
;   Purpose: add SSW standard tags to input structure, optionally rationalize
;
;   Input Parameters:
;      structs - vector of strutuctures to work on
;      data - optional - corresponding data , for deriving missing fields
;
;   History:
;      24-October-1998 - S.L.Freeland - combine a few useful functions
;      28-October-1998 - S.L.Freeland - allow scalar input index...
;  
;   Category:
;      structure, fits, image , 2D , 3D , SSW , alignment, time
;-
sswtemplate=sswfits_struct(n_elements(structs)>1,/addfits) ; get 'standard' e
loud=keyword_set(loud)
fillit=1-keyword_set(nofill)

if not data_chk(structs,/struct) then begin
   box_message,['Structure input required', $
		'IDL> sswstr=struct2ssw(structures [,data] [,/nofill] )']
   return, sswtemplate
endif    

existtag=tag_names(structs)
retval=structs

sswtag=tag_names(sswtemplate(0))
need=rem_elem(sswtag,existtag,count)

if count gt 0 then begin 
   needtemp=str_subset(sswtemplate,sswtag(need))
   retval=join_struct(retval,needtemp)
endif else begin
  if loud then box_message,'Input structure already contains all SSW tags'
endelse   

scalarize=n_elements(retval) eq 1
if scalarize then begin
   retval=replicate(retval,2)          ; kludge for not
endif

if fillit then begin
   if loud then box_message,'Filling SSW fields'
   retval=sswstruct_fill(retval,loud=loud,_extra=_extra)
endif

if scalarize then retval=retval(0)

return, retval
end







