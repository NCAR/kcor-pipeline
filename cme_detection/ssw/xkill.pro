;+
; Project     :	SDAC
;
; Name        :	XKILL
;
; Purpose     :	To kill a widget
;
; Use         :	XKILL,ID
;              
; Inputs      :	IDn = widget id (or name) to kill
;
; Keywords    :	ALL = if set, then destroy all active widgets
;               WAIT = wait specified seconds before killing
;
; Category    :	Widgets
;
; Written     :	Dominic Zarro (ARC)
;
; Version     :	Version 1.0, 18 September 1993
;               Modified, 1-Mar-07, Zarro (ADNET) 
;                - removed EXECUTE
;                - only kill widget ids in first argument
;-

pro xkill,id,id1,id2,id3,id4,id5,id6,id7,id8,id9,all=all,wait=wait,_extra=extra

if is_number(wait) then if (wait gt 0) then wait,wait
if keyword_set(all) then begin
 widget_control,/reset,/clear_events,bad_id=destroyed
 return
endif

nwid=n_elements(id)
if nwid eq 0 then return
for i=0,nwid-1 do begin
 if is_string(id[i]) then wid=get_handler_id(id[i]) else wid=id[i]
 if xalive(wid) then widget_control,wid,/destroy,/clear_events,bad_id=destroyed
endfor

return & end
