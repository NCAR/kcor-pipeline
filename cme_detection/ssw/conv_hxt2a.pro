;+
; NAME:
;	CONV_HXT2A
; PURPOSE:
;	To convert from HXT pixel location to an angle from sun center. 
; CALLING SEQUENCE:
;	arcvec = conv_hxt2a(hxt,date)
; INPUT:
;       hxt     - The pixel coordinates of the point(s) in question in 
;                 126 arcsec units (??)  Rectified HXA coordinates, in 
;                 HXT pitch units, as used in the Matsushita study
;                      (0,*) = E/W direction with W negative!
;                               NOTE: This is opposite of SXT and HELIO
;                      (1,*) = N/S direction
;       date    - The date for the conversion in question.  This is needed
;                 for SXT so that the pixel location of the center of the sun
;                 can be determined.
; OUTPUT:
;       ang     - The angle in arcseconds as viewed from the earth.
;                       (0,*) = E/W direction with W positive
;                       (1,*) = N/S direction with N positive
; OPTIONAL KEYWORD INPUT:
;	arcmin  - If set, output is in arcminutes, rather than 
;		  arcseconds.
; HISTORY:
;	version 1.0	Written 7-Jan-95 by T.Sakao
;		1.1	Option arcmin added.
;-		
;
;
function  conv_hxt2a, hxt,date, arcmin=arcmin
  pix    = conv_hxt2p(hxt)
  arcvec = conv_p2a(pix,date)
  if keyword_set(arcmin) then arcvec = arcvec/60.0
  return, arcvec
end
