;+
; Project     : SOHO, YOHKOH
;
; Name        : COMP_FITS_CRPIX
;
; Purpose     : Compute CRPIX from FOV center 
;
; Category    : imaging, FITS
;
; Syntax      : crpix=comp_fits_crpix(cen,cdelt,naxis,crval)
;
; Inputs      : CEN = data coordinate of FOV center
;               CDELT = pixel scaling
;               NAXIS = pixel dimension of image
;
; Opt. Inputs : CRVAL = reference data coordinate [def=0]
;
; Outputs     : CRPIX = reference pixel coordinate
;
; History     : Written, 15 November 1998, D.M. Zarro (SM&A)
;                Modified, 22 September 2014, Zarro (ADNET)
;               - converted to double precision arithmetic
;
; Contact     : dzarro@solar.stanford.edu
;-

function comp_fits_crpix,cen,cdelt,naxis,crval

present=exist(naxis) and exist(cdelt)

if ~present then begin
 pr_syntax,'crpix=comp_fits_crpix(cen,cdelt,naxis [,crval])'
 return,0.
endif

if ~exist(cen) then cen=0.d0
if ~exist(crval) then crval=0.d0

crpix=(naxis+1.d0)/2.d0 - (double(cen)-double(crval))/double(cdelt)

return,crpix

end

