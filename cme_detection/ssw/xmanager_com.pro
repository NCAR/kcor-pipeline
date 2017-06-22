;+
; Project     : SOHO - CDS     
;                   
; Name        : XMANAGER_COM
;               
; Purpose     : return widget ID's and application names from
;               XMANAGER common block
;               
; Category    : widgets
;               
; Explanation : useful to check what the heck XMANAGER is doing when
;               an application crashes. Actually, a shell around two
;               lower-level versions that work differently between
;               pre- and post-IDL version 3.6.
;               
; Syntax      : IDL> XMANAGER_COM,IDS,NAMES
;    
; Examples    : 
;
; Inputs      : None.
;               
; Opt. Inputs : None
;               
; Outputs     : IDS = long array of widget IDS
;               NAMES = companion string array of associated application names
;               NUMMANAGED = number of widgets being managed
;               STATUS = 1 if valid entries found in XMANAGER common
;
; Opt. Outputs: None.
;               
; Keywords    : None.
;
; Common      : None.
;               
; Restrictions: None.
;               
; Side effects: None.
;               
; History     : Version 1,  17-July-1996,  D M Zarro.  Written
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-            

pro xmanager_com,ids,names,nummanaged,status=status

vers=float(strmid(!version.release,0,3))
new_vers=vers ge 4
if new_vers then begin
 recompile,'xmanager',/quiet
 call_procedure,'xmanager_com_new',ids,names,nummanaged
endif else call_procedure,'xmanager_com_old',ids,names,nummanaged
status=(datatype(ids) eq 'LON') and (datatype(names) eq 'STR')
return & end

