;+
; Project     : SOHO, YOHKOH
;
; Name        : GET_FITS_CDELT
;
; Purpose     : Get FITS CDELT values from header
;
; Category    : imaging, FITS
;
; Explanation : Try to determine FITS scaling info
;
; Syntax      : get_fits_cdelt,stc
;
; Inputs      : STC - FITS header in structure format (such as from HEAD2STC)
;
; Outputs     : CDELT1, CDELT2 - image pixel scaling
;
; Keywords    : TIME - optional image time (if already determined)
;               ERR  - error message
;
; History     : Written, 15 November 1998, D.M. Zarro (SM&A)
;               Modified, 22 September 2014, Zarro (ADNET)
;               - converted to double-precision arithmetic
;
; Contact     : dzarro@solar.stanford.edu
;-


pro get_fits_cdelt,stc,cdelt1,cdelt2,time=time,err=err

err=''

if ~is_struct(stc) then begin
 err='Input argument error'
 pr_syntax,'get_fits_cdelt,stc,cdelt1,cdelt2'
 return
endif

cdelt1=1.d0 & cdelt2=1.d0

;-- look in the obvious places first

stc=rep_tag_name(stc,'cdel1','cdelt1',/quiet)
stc=rep_tag_name(stc,'cdel2','cdelt2',/quiet)

stc=rep_tag_name(stc,'dxb_img','cdelt1',/quiet)
stc=rep_tag_name(stc,'dyb_img','cdelt2',/quiet)

cdelt1=double(gt_tagval(stc,/cdelt1,found=found1,missing=1.))
cdelt2=double(gt_tagval(stc,/cdelt2,found=found2,missing=1.))

;-- try to figure it from any radius information stored in FITS file

if ~found1 or ~found2 then begin
 soho=strpos(string(gt_tagval(stc[0],/telescop)),'SOHO') ne -1 
 rad=gt_tagval(stc[0],'radius',found=found3)
 if ~found3 then rad=gt_tagval(stc[0],'solar_r',found=found3)
 if found3 then begin
  terr=''
  dtime=anytim2utc(time,err=terr)
  if terr ne '' then get_fits_time,stc,dtime,/current
  h=double(pb0r(dtime,/arc,soho=soho[0]))
  cdelt1=h[2]/rad
  cdelt2=cdelt1
 endif
endif

if (cdelt1[0] eq 0.d0) or (cdelt2[0] eq 0.d0) then $
 err='Could not determine FITS scaling'

return & end

