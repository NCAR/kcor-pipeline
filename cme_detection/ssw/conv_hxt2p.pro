function conv_hxt2p, pix, old=old
;+
; NAME:
;	CONV_HXT2P
; PURPOSE:
;	To convert from HXT pixel location to an SXT pixel location
; CALLING SEQUENCE:
; 	sxt = conv_hxt2p(hxt)
; INPUTS:
;       hxt     - The pixel coordinates of the point(s) in question in 
;		  126 arcsec units (??)  Rectified HXA coordinates, in 
;		  HXT pitch units, as used in the Matsushita study
;                       (0,*) = E/W direction with W negative!
;				NOTE: This is opposite of SXT and HELIO
;                       (1,*) = N/S direction
; OUTPUTS:
;       sxt	- The SXT pixel IDL Full Resolution coordinate
;                       (0,*) = E/W value (0,0 in lower left South-East)
;                       (1,*) = N/S value
; HISTORY:
;	Written 20-Dec-93 by M.Morrison
;	20-Dec-93 (MDM) - See CONV_P2HXT for a history
;-
;
x0 = 515.3
y0 = 703.5
theta2 = 0.67		; rotation between HXT and SXT
hxt_pitch = 126.0	; in arcsec
sxt_pxlsiz = 2.46	; in arcsec
;
hxt_x = -pix(0) * (hxt_pitch/sxt_pxlsiz)
hxt_y =  pix(1) * (hxt_pitch/sxt_pxlsiz)
;
c = cos(theta2/!radeg)
s = sin(theta2/!radeg)
;
out = float(pix)
out(0,*) =  c*hxt_x + s*hxt_y + x0
out(1,*) = -s*hxt_x + c*hxt_y + y0
;
return, out
end
