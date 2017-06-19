;+
; Project     :	SDAC
;
; Name        :	XALIVE
;
; Purpose     :	To check if an X widget is alive
;;
; Use         :	ALIVE=XALIVE(ID)
;              
; Inputs      :	ID = widget id to check
;
; Outputs     :	1/0 if alive/dead
;
; Keywords    : NAME = set if input ID is widget event handler name
;               COUNT = no of multiple instances 
;
; Category    :	Widgets
;
; Written     :	Dominic Zarro (ARC)
;
; Version     :	Version 1.0, 18 September 1993
;               Version 2.0, 16 November 1999 
;                -- allowed ID to be widget handler name
;               Modified, 24 June 2010
;                - relaxed LONG requirement for ID
;-

function xalive,id,name=name,count=count,ids=ids

ids=-1 & count=0

if ~exist(id) then return,0b

sz=size(id)
dtype=sz[n_elements(sz)-2]
if keyword_set(name) and (dtype eq 7) then $
 ids=get_handler_id(id,/all) else ids=id

chk=is_number(ids)
if ~chk[0] then return,0b
ids=long(ids)
nid=n_elements(ids)

if nid gt 1 then begin
 for i=0,nid-1 do out=append_arr(out,xalive(ids[i],name=name))
 alive=where(out gt 0b,count)
 if count gt 0 then ids=ids[alive]
 return,out
endif

out=0                  
sz=size(ids)
dtype=sz[n_elements(sz)-2]
if (dtype eq 3) then out=widget_info(ids,/valid)
out=byte(out)
alive=where(out gt 0b,count)
if count gt 0 then ids=ids[alive]
     
return,out

end
