;+
; Project     : SOHO, YOHKOH
;
; Name        : COMP_FITS_CRVAL
;
; Purpose     : Compute CRVAL from FOV center 
;
; Category    : imaging, FITS
;
; Explanation : 
;
; Syntax      : crval=comp_fits_crval(cen,cdelt,naxis,crpix)
;
; Examples    :
;
; Inputs      : CEN = data coordinate of FOV center
;               CDELT = pixel scaling
;               NAXIS = pixel dimension of image
;
; Opt. Inputs : CRPIX = reference pixel coordinate [def=0]
;
; Opt. Inputs : None
;
; Outputs     : CRVAL = reference pixel coordinate value
;
; History     : Written, 15 November 1998, D.M. Zarro (SM&A)
;
; Contact     : dzarro@solar.stanford.edu
;-

function comp_fits_crval,cen,cdelt,naxis,crpix

present=exist(naxis) and exist(cdelt)

if not present then begin
 pr_syntax,'crval=comp_fits_crval(cen,cdelt,naxis [,crpix])'
 return,0.
endif

if not exist(cen) then cen=0.
if not exist(crpix) then crpix=0.

crval=float(cen)-float(cdelt)*( (float(naxis)+1.)/2. - float(crpix) )
return,crval

end

