;+                                                                                         
; Project     : SOHO-CDS                                                                 
;                                                                                        
; Name        : GET_FITS_PAR                                                             
;                                                                                        
; Purpose     : get image parameters from FITS header                                    
;                                                                                        
; Category    : imaging                                                                  
;                                                                                        
; Syntax      : get_fits_par,header,xcen,ycen,dx,dy                                      
;                                                                                        
; Inputs      : HEADER = FITS header                                                     
;                                                                                        
; Outputs     : XCEN,YCEN = image FOV center                                             
;               DX,DY = image pixel spacings                                             
;               NX,NY = image dimensions                                                 
;                                                                                        
; Keywords    : ERR = error string                                                       
;               STC = output in structure format                                         
;               TIME = image time                                                        
;                                                                                        
;                                                                                        
; History     : Written 22 August 1997, D. Zarro, SAC/GSFC                               
;               Modified 16-Feb-2000, Zarro (SM&A/GSFC) - added                          
;               extra checks for non-SSW standard times                                  
;               Modified 20-Aug-2000, Zarro (EIT/GSFC) - moved                           
;               ROLL checks from INDEX2MAP to here                                       
;               Modified 4-Oct-2001, Zarro (LAC/GSFC) - fixed                            
;               potential bugs in roll calculation                                       
;               Modified 20-Dec-02, Zarro (EER/GSFC) - fixed another                     
;               roll issue. Why can't people learn to use FITS standards                 
;               after all these years.                                                   
;               Modified 4-Nov-03, Zarro (L-3/GSFC) - added axis unit check              
;               Modified 21-Mar-04, Zarro (L-3Com/GSFC) - cleaned up                     
;               Modified 29-Mar-05, Zarro (L-3Com/GSFC) - improved check for CROTA       
;               Modified,31-Mar-05, Thompson (L-3Com/GSFC) - added cdelt1,cdelt2 tags if not found
;               Modified 7-Oct-05, R.Bentley (UCL) - cdelt1/cdelt2 to handle
;                case where plate scale is in "solar radii/pixel" ("solrad" - VSM)
;               Modified 29-Mar-06, Zarro (L-3Com/GSFC) - further
;                                                         improved roll check    
;               Modified 3-Sep-06, Zarro (ADNET/GSFC) - added WAVE to ID
;               Modified 28-Mar-07, Zarro (ADNET) - check for valid CRPIXi
;               Modified 5-Mar-08,Zarro (ADNET) - fixed bug with SOHO boolean
;               Modified 6-Mar-08, W. Thompson, check if tags TELESCOP
;               and ORIGIN exist
;               27-Sept-08, Zarro (ADNET) 
;                - added more rigorous checks for roll and spacecraft 
;               21-November-08, Zarro (ADNET)
;                - restored check for missing NAXIS tags
;               24-May-10, Zarro (ADNET)
;                - made Sun center (0,0) the default roll center.
;               25-May-10, Zarro (ADNET)
;                - fixed vectorizing bug in roll
;                  calculation. I'm never going to get this right.
;               13-May-14, Zarro (ADNET)
;                - added ORIGIN as potential ID
;               27-May-14, Zarro (ADNET) added ANGLES
;               11-Jun-14, Zarro (ADNET) 
;                - changed STREGEX to STRPOS to search for
;                  header fields. STREGEX has issues with 
;                  escape characters in the search string.  
;                22-Oct-14, Zarro (ADNET)
;                - converted to double-precision arithmetic
;                30-Nov-15, Zarro (ADNET)
;                - removed redundant dimension in RCENTER
;                10-May-14, Zarro (ADNET)
;                - changed UNITS from ARCSECS to ARCSEC
;                                                                                        
; Contact     : dzarro@solar.stanford.edu                                                
;-                                                                                       
                                                                                         
pro get_fits_par,header,xcen,ycen,dx,dy,err=err,time=time,stc=stc,nx=nx,$                
                ny=ny,roll=roll,current=current,rcenter=rcenter,id=id,$                  
                dur=dur,soho=soho,_extra=extra,angles=angles                                                        
                                                                                         
err=''                                                                                   
dtype=''                                                                                 
if is_struct(header) then dtype='STC'                                                    
if is_string(header) then dtype='STR'                                                    
if (dtype ne 'STC') && (dtype ne 'STR') then begin                                      
 err='input argument error'                                                              
 pr_syntax,'get_fits_par,header,xcen,ycen,dx,dy'                                         
 return                                                                                  
endif                                                                                    
                                                                                         
;-- check whether FITS header or index structure was input                               
                                                                                         
if dtype eq 'STR' then begin                                                             
 stc=fitshead2struct(header)                                                             
 if err ne '' then return                                                                
 dtype='STC'                                                                             
endif else begin
 if ~have_tag(header,'naxis1') then stc=struct2ssw(header) else stc=header                                                                    
endelse

;-- determine OBS time                                                                   
                                                                                         
nimg=n_elements(stc)                                                                     
time=strarr(nimg)                                                                        
for i=0,nimg-1 do begin                                                                  
 get_fits_time,stc[i],dtime,/current                                                     
 time[i]=dtime                                                                           
endfor                                                                                   
if nimg eq 1 then time=time[0]                                                           

;-- image roll

roll=fltarr(nimg)
for i=0,nimg-1 do roll[i]=get_fits_roll(stc[i],_extra=extra)
if nimg eq 1 then roll=roll[0]

;-- determine FITS scaling                                                               

dx=replicate(1.,nimg)
dy=dx
for i=0,nimg-1 do begin
 get_fits_cdelt,stc[i],tdx,tdy,time=time[i],err=err1
 if err1 eq '' then begin
  dx[i]=tdx & dy[i]=tdy
 endif
endfor
if nimg eq 1 then begin
 dx=dx[0] & dy=dy[0]
endif
                    
;-- compute image center                                                                 

xcen=replicate(0.,nimg)
ycen=xcen        
for i=0,nimg-1 do begin
 get_fits_cen,stc[i],txcen,tycen,dx=dx[i],dy=dy[i],time=time[i],err=err1,_extra=extra                                             
 if err1 eq '' then begin
  xcen[i]=txcen & ycen[i]=tycen
 endif 
endfor
if nimg eq 1 then begin
 xcen=xcen[0] & ycen=ycen[0]
endif

;-- take care of roll center (def to Sun center)                                       
 
rc=fltarr(nimg)                                                         
rcenter=[[rc],[rc]]
found_roll_center=0b                                                                    
roll_center_x=gt_tagval(stc,/crotacn1,found=found_roll_center_x)                        
roll_center_y=gt_tagval(stc,/crotacn2,found=found_roll_center_y)                        
found_roll_center=found_roll_center_x && found_roll_center_y                           
if found_roll_center then rcenter=comdim2(double([[roll_center_x],[roll_center_y]]))
         
;-- determine image dimensions                                                           
                                                                                         
nx=stc.naxis1                                                                            
ny=stc.naxis2                                                                            
                                                                                         
;-- update scaling                                                                       
                                                                                         
if have_tag(stc,'xcen',/exact) then stc.xcen=xcen                                        
if have_tag(stc,'ycen',/exact) then stc.ycen=ycen                                        
                                                                                         
if have_tag(stc,'cdelt1',/exact) then stc.cdelt1=dx else $                               
  stc = add_tag(stc,dx,'cdelt1',/top_level)                                              
if have_tag(stc,'cdelt2',/exact) then stc.cdelt2=dy else $                               
  stc = add_tag(stc,dy,'cdelt2',/top_level)                                              
                                                                                         
if have_tag(stc,'cunit1',/exact) then begin                                     
 cunit1=strtrim(strlowcase(stc(0).cunit1),2)
 if strpos(strlowcase(stc(0).cunit1),'deg') gt -1 then stc.cdelt1=stc.cdelt1*3600.       
 if strpos(strlowcase(stc(0).cunit1),'rad') gt -1 then stc.cdelt1=!radeg*stc.cdelt1*3600.
 if (strpos(cunit1,'solrad') eq 0) && have_tag(stc,'eph_r0') then stc.cdelt1=stc.cdelt1*stc.eph_r0
 stc.cunit1='arcsec' & dx=stc.cdelt1                                                    
endif                                                                                    
                                                                                         
if have_tag(stc,'cunit2',/exact) then begin                                              
 cunit2=strtrim(strlowcase(stc(0).cunit2),2)
 if strpos(strlowcase(stc(0).cunit2),'deg') gt -1 then stc.cdelt2=stc.cdelt2*3600.       
 if strpos(strlowcase(stc(0).cunit2),'rad') gt -1 then stc.cdelt2=!radeg*stc.cdelt2*3600.
 if (strpos(cunit2,'solrad') eq 0) && have_tag(stc,'eph_r0') then stc.cdelt2=stc.cdelt2*stc.eph_r0
 stc.cunit2='arcsec' & dy=stc.cdelt2                                                    
endif                                                                                    
                 
if have_tag(stc,'crpix1',/exact) then crpix1=stc.crpix1 else begin
 crpix1=(nx-1)/2.
 stc = add_tag(stc,crpix1,'crpix1',/top_level)                                              
endelse
 
if have_tag(stc,'crpix2',/exact) then crpix2=stc.crpix2 else begin
 crpix2=(ny-1)/2.
 stc = add_tag(stc,crpix2,'crpix2',/top_level)
endelse

if have_tag(stc,'crval1',/exact) then stc.crval1=comp_fits_crval(xcen,dx,nx,stc.crpix1)  
if have_tag(stc,'crval2',/exact) then stc.crval2=comp_fits_crval(ycen,dy,ny,stc.crpix2)  
                                                                                         
;-- check for miscellaneous stuff                                                        
                                                                                         
blank=comdim2(replicate('',nimg))                                                        
                                                                                         
;-- exposure time                                                                        
                                                                                         
dur=comdim2(replicate(0.,nimg))
case 1 of                                                          
 have_tag(stc,'exptime',/exact): dur=float(stc.exptime) 
 have_tag(stc,'sht_mdur',/exact): dur=float(stc.sht_mdur) 
 have_tag(stc,'dur',/exact): dur=float(stc.dur)
 else: begin
  if tag_exist(stc,'date_obs') && tag_exist(stc,'date_end') then $                       
   dur=anytim2tai(stc.date_end)-anytim2tai(stc.date_obs)                                  
 end                                                                                    
endcase

keys=['spacec','obsrvtry','observa','telesc','instrume','detect','orig','wavelnth','wave_len']
id=strarr(nimg)
for i=0,nimg-1 do begin
 for j=0,n_elements(keys)-1 do begin
  if have_tag(stc[i],keys[j],k,/start) then begin
   item=trim(stc[i].(k[0]))
   if is_string(item) then begin
    chk=strpos(strupcase(id[i]),strupcase(item))
    if chk lt 0 then id[i]=id[i]+' '+item                 
   endif
  endif                     
 endfor
endfor
id=strcompress(trim(id))                                                    

soho=bytarr(nimg)
chk=where(stregex(id,'SOHO',/bool,/fold),count)
if count gt 0 then soho[chk]=1b
if count eq 1 then soho=soho[0]
                       
;-- check for ANGLES

if have_tag(stc,'L0',/exact) && have_tag(stc,'B0',/exact) && have_tag(stc,'RSUN',/exact) then begin
 angles=replicate({l0:0., b0:0., rsun:0.},nimg)
 angles.l0=stc.l0
 angles.b0=stc.b0
 angles.rsun=stc.rsun
endif                                               

return & end                                                                             
