;+
; Project     : HESSI
;
; Name        : GET_MONTH
;
; Purpose     : get month name 
;
; Category    : utility date time 
;
; Syntax      : month=get_month(id)
;
; Inputs      : ID = month number (0 for Jan, 1 for Feb, etc)
;                or  month name (Jan, Feb, etc)
;
; Outputs     : MONTH = string month corresponding to ID
;                 or  month number corresponding to month
;
; Keywords    : TRUNCATE = truncate to 3 characters
;
; History     : Written 6 Jan 1999, D. Zarro (SM&A/GSFC)
;
; Contact     : dzarro@solar.stanford.edu
;-

function get_month,id,truncate=truncate

if not exist(id) then id=0
months=['January','February','March','April','May','June','July','August',$
         'September','October','November','December']

error=0
catch,error
if error ne 0 then begin
 catch,/cancel
 message,err_state(),/cont
 return,-1
endif

np=n_elements(id)
sz=size(id)
dtype=sz[n_elements(sz)-2]

if dtype eq 7 then begin
 piece=strmid(strtrim(strlowcase(id),2),0,3)
 pmonth= strmid(strlowcase(months),0,3)
 mon=intarr(np)
 i=-1
 repeat begin 
  i=i+1
  chk=where( piece eq pmonth[i],count)
  if count gt 0 then mon[chk]=i+1
  done=where(mon,mcount)
 endrep until (mcount eq np) or (i eq 11)
 mon=mon-1
endif else begin
 mon=months(0 > fix(id) < 11)
 if keyword_set(truncate) then mon=strmid(mon,0,3)
endelse


if np eq 1 then mon=mon[0]

return,mon
end

