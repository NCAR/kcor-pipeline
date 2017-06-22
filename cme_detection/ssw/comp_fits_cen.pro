;+
; Project     : SOHO, YOHKOH
;
; Name        : COMP_FITS_CEN
;
; Purpose     : compute XCEN (or YCEN) from FITS standard keywords
;
; Category    : imaging, FITS
;
; Syntax      : xcen=comp_fits_cen(crpix1,cdelt1,naxis1,crval1)
;                                   OR
;               ycen=comp_fits_cen(crpix2,cdelt2,naxis2,crval2)
;
; Inputs      : CRPIX = reference pixel coordinate
;               CDELT = pixel scaling
;               NAXIS = pixel dimension of image
;
; Opt. Inputs : CRVAL = reference data coordinate [def=0]

; Outputs     : CEN = center of FOV in data units
;
; History     : Written, 15 November 1998, D.M. Zarro (SM&A)
;               Modified, 22 September 2014, Zarro (ADNET)
;               - converted to double precision arithmetic
;
; Contact     : dzarro@solar.stanford.edu
;-

function comp_fits_cen,crpix,cdelt,naxis,crval

present=exist(naxis) and exist(crpix) and exist(cdelt)

if ~present then begin
 pr_syntax,'cen=comp_fits_cen(crpix,cdelt,naxis [,crval])'
 return,0.
endif

if ~exist(crval) then crval=0.d0

cen=double(crval)+double(cdelt)*( (naxis+1.d0)/2.d0 -double(crpix))

return,cen
end

