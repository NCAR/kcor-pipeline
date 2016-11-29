;+
; Project     : SOHO - CDS
;
; Name        : GET_HANDLER_ID
;
; Purpose     : to get widget ID of base associated with event handler
;
; Category    : widgets
;
; Explanation : examines XMANAGER common for registered ID's
;
; Syntax      : IDL> widget_id = get_handler_id(handler)
;
; Inputs      : HANDLER = event handler name
;
; Opt. Inputs : None
;
; Outputs     : WIDGET_ID = most recent widget ID associated with handler
;
; Opt. Outputs: None
;
; Keywords    : GHOSTS = other widget ID's related to handler name
;               ALL = return all ID's associated with handler
;
; Common      : None
;
; Restrictions: None
;
; Side effects: None
;
; History     : Version 1,  22-Aug-1996,  D.M. Zarro.  Written
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-
    
function get_handler_id,handler,ghosts=ghosts,first=first,all=all
widget_id=-1

if datatype(handler) ne 'STR' then return,widget_id
xmanager_com,ids,names,status=status
if not status then return,widget_id

wlook=where(strupcase(trim(handler)) eq strupcase(trim(names)),cnt)
if cnt gt 0 then begin
 if keyword_set(first) then begin
  widget_id=ids(wlook(0))
  if cnt gt 1 then ghosts=ids(wlook(1:cnt-1))
 endif else begin
  widget_id=ids(wlook(cnt-1))
  if cnt gt 1 then ghosts=ids(wlook(0:cnt-2))
 endelse
endif

if keyword_set(all) and exist(ghosts) then return,[widget_id,ghosts] else $
 return,widget_id 

end

