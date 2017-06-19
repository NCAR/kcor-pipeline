;+
; Project     : SOHO, YOHKOH
;
; Name        : GET_FITS_TIME
;
; Purpose     : Get FITS observation time from header
;
; Category    : imaging, FITS
;
; Explanation : Try to get FITS time from several formats
;
; Syntax      : get_fits_time,stc,time
;
; Inputs      : STC - FITS header in structure format (such as from HEAD2STC)
;
; Outputs     : TIME - time in UTC units
;
; Keywords    : ERR - error message
;               CURRENT - set to default to current time
;
; History     : Written, 15 November 1998, D.M. Zarro (SM&A)
;               Modified, 15 Feb 2000, Zarro (SM&A/GSFC) - added
;               more checks for different time tag varieties
;               Modified, 15 Aug 2000, Zarro (EIT/GSFC) -- fixed
;               vector problem
;               Modified, 21 Mar 2004, Zarro (L-3Com/GSFC) -- added
;               more time format checks
;               Modified, 2 May 2009, Zarro (ADNET)
;               - switched order of date/time search
;               Modified, 13 May 2014, Zarro (ADNET)
;               - fixed bug with time tag search ending prematurely.
;               Modified, 4 Oct 2014, Zarro (ADNET)
;               - vectorized
;
; Contact     : dzarro@solar.stanford.edu
;-

pro get_fits_time_scalar,stc,time,err=err,current=current

err=''
time=''


;-- Try different combinations of FITS date/time standards.
;-- Have to check that the time is often included in the date part
;   (but not always!)

dformats=['date_obs','date_d$obs','date','date__obs','dateobs']
tformats=['time_obs','time_d$obs','time','time__obs','timeobs']

for i=0,n_elements(dformats)-1 do begin
 err=''
 time=''
 dformat=dformats[i] 
 if ~have_tag(stc,dformat,dindex,/exact) then continue
 dfield=stc.(dindex)
 if ~is_string(dfield) then continue
 time=anytim2utc(dfield,/vms,err=err)
 if is_string(err) then continue

;-- time included in date then we are done

 have_time=strpos(dfield,':') gt -1
 if have_time then return 

;-- if not, then examine time fields

 time=anytim2utc(dfield,/vms,/date)
 tformat=tformats[i]
 if have_tag(stc,tformat,tindex,/exact) then begin
  tfield=stc.(tindex)
  if is_string(tfield) then begin             ;-- add time part if present
   terr=''
   dtime=anytim2utc(tfield,/time,/vms,err=terr)
   if terr eq '' then  time=time+' '+dtime
  endif
 endif
 return
endfor

;-- try SOHO/Yohkoh formats

err=''
time=''
if tag_exist(stc,'time',/recurse) then begin
 if tag_exist(stc,'mjd',/recurse) then begin
  if (required_tags(stc,/mjd) gt 0) and (required_tags(stc,/time) gt 0) then begin
   time=anytim2utc(stc,/vms,err=err)
   if err eq '' then return
  endif
 endif
 if tag_exist(stc,'day',/recurse) then begin
  if (required_tags(stc,/day) gt 0) and (required_tags(stc,/time) gt 0) then begin
   time=anytim(stc,/vms,error=error)
   if error eq 0 then return 
  endif
 endif
endif
                     
;-- try old STARTIME (desperate)

err=''
time=''
if tag_exist(stc,'startime') then begin
 time=anytim2utc( double(stc.startime)+anytim2tai('1-jan-1970'),/vms,err=err)
 if err eq '' then return 
endif

;-- try T_START = YYMMDDHHMMSSSS (even more desperate)

err=''
time=''
if tag_exist(stc,'t_start') then begin
 tstart=trim(stc.t_start)
 yy=strmid(tstart,0,2)
 mon=get_month(fix(strmid(tstart,2,2))-1)
 dd=strmid(tstart,4,2)
 hh=strmid(tstart,6,2)
 mm=strmid(tstart,8,2)
 ss=strmid(tstart,10,2)
 dtime=dd+'-'+mon+'-'+yy+' '+hh+':'+mm+':'+ss
 time=anytim2utc(dtime,/vms,err=err)
 if err eq '' then return 
endif

if keyword_set(current) then begin
 err=''
 get_utc,time,/vms
 return
endif

;-- if we got here then we are in trouble

time=''
err='Could not determine FITS time from tags.'

return & end

;--------------------------------------------------------------------------------
pro get_fits_time,stc,time,err=err,_extra=extra

err=''
time=''
if ~is_struct(stc) then begin
 err='Input argument error'
 pr_syntax,'get_fits_time,stc,time'
 return
endif

np=n_elements(stc)
time=strarr(np)
for i=0,np-1 do begin
 get_fits_time_scalar,stc[i],stime,err=err,_extra=extra
 time[i]=stime
endfor

if np eq 1 then time=time[0]

return & end
