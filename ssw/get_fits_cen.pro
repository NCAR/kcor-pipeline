;+
; Project     : SOHO, YOHKOH
;
; Name        : GET_FITS_CEN
;
; Purpose     : Return XCEN and/or YCEN from FITS-like stucture
;
; Category    : imaging, FITS
;
; Syntax      : get_fits_cen,struct,xcen,ycen,dx,dy
;
; Inputs      : struct - FITS-like structure
;
; Outputs     : XCEN, (and/or YCEN) - center of FOV in data units
;
; Keywords    : TIME - optional time
;               DX, DY - pixel spacing
;
; History     : Written, 12 November 1998, D.M. Zarro (SM&A)
;               Modified, 16 Sept 2001, Zarro (EITI/GSFC)
;               -added check for non-zero XCEN/YCEN
;               20 Sept 2008, Zarro (ADNET)
;               - added call to comp_pc_cen
;               25 May 2010, Zarro (ADNET)
;               - removed call to comp_pc_cen
;
; Contact     : dzarro@solar.stanford.edu
;-

pro get_fits_cen,struct,xcen,ycen,dx=dx,dy=dy,time=time,err=err,verbose=verbose

xcen=0. & ycen=0.
if ~is_struct(struct) then begin
 pr_syntax,'get_fits_cen,struct,xcen,ycen'
 return
endif

verbose=keyword_set(verbose)
;if have_tag(struct,'pc1_1') then begin
; if verbose then message,'computing XCEN/YCEN from PC matrix',/cont
; comp_pc_cen,struct,xcen,ycen
; return
;endif

if ~exist(dx) or ~exist(dy) then begin
 get_fits_cdelt,struct,dx,dy,err=err
 if err ne '' then return
endif

cdelt1=dx & cdelt2=dy
crpix1=0.d0 & crpix2=0.d0
naxis1=struct.naxis1
naxis2=struct.naxis2

if have_tag(struct,'crpix1',/exact) and $
 have_tag(struct,'crpix2',/exact) then begin
 crpix1=struct.crpix1
 crpix2=struct.crpix2
 xcen=comp_fits_cen(crpix1,cdelt1,naxis1)
 ycen=comp_fits_cen(crpix2,cdelt2,naxis2)
endif

;-- compute XCEN, YCEN from FITS keywords    

zero_cen=1b
have_cen=have_tag(struct,'xcen',/exact) and have_tag(struct,'ycen',/exact)                                              
if have_cen then zero_cen=(struct.xcen eq 0.) and (struct.ycen eq 0.)

if have_tag(struct,'crval1',/exact) and $
 have_tag(struct,'crval2',/exact) then begin
 crval1=struct.crval1
 crval2=struct.crval2
 xcen=comp_fits_cen(crpix1,cdelt1,naxis1,crval1)
 ycen=comp_fits_cen(crpix2,cdelt2,naxis2,crval2)          
 if ~have_cen or zero_cen[0] then begin
  if verbose then message,'computing XCEN/YCEN from CRVALs',/cont
  return
 endif
endif
                     
;-- look for XCEN/YCEN fields 

if have_cen then begin
 xcen=struct.xcen
 ycen=struct.ycen
 if verbose then message,'getting XCEN/YCEN from header fields',/cont
 return
endif

;-- look for Carrington coordinates

if have_tag(struct,'car_d$lat',/exact) and $
  have_tag(struct,'car_d$lon',/exact) then begin
 lat=struct.car_d$lat*!radeg
 lon=struct.car_d$lon*!radeg
 terr=''
 dtime=anytim2utc(time,err=terr,/vms)
 if terr ne '' then begin
  get_fits_time,struct,dtime,err=err
  if err ne '' then return
 endif
 np=n_elements(lat)
 if (n_elements(dtime) ne np) then dtime=replicate(dtime,np)
; lon=lon+tim2carr(dtime)
 xcen=fltarr(np) & ycen=fltarr(np)
 for i=0,n_elements(dtime)-1 do begin
  xy=append_arr(xy,hel2arcmin(lat[i],lon[i],date=dtime[i])*60.)
  xcen[i]=xy[0] & ycen[i]=xy[1]
 endfor
 dprint,'% GET_FITS_CEN: computing XCEN/YCEN from LAT/LON'
endif

return & end
