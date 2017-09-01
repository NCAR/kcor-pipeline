function conv_p2a, pix, date0, arcmin=arcmin, roll=roll, $
		hxa=hxa, cmd=cmd, suncenter=suncenter, $
		pix_size=pix_size0, radius=radius
;
;+
;NAME:
;	conv_p2a
;PURPOSE:
;	To convert from a pixel location to an angle from sun center.
;SAMPLE CALLING SEQUENCE:
;	ang = conv_p2a(pix, date)
;	ang = conv_p2a(pix, suncenter=[400,400])
;INPUT:
;	pix	- The pixel coordinates of the point(s) in question.  Larger pixel
;		  address towards the N and W.
;			(0,*) = E/W direction
;			(1,*) = N/S direction
;OPTIONAL INPUT:
;	date	- The date for the conversion in question.  This is needed
;		  for SXT so that the pixel location of the center of the sun
;		  can be determined.
;OUTPUT:
;	ang	- The angle in arcseconds as viewed from the earth.
;			(0,*) = E/W direction with W positive
;			(1,*) = N/S direction with N positive
;OPTIONAL KEYWORD INPUT:
;	roll	- This is the S/C roll value in degrees
;	
;	hxa	- If set, use HXA_SUNCENTER to determine the location of the
;		  sun center in pixels.  Default is to use GET_SUNCENTER.
;	cmd	- If set, use SXT_CMD_PNT to determine the location of the
;                 sun center in pixels. Default is to use GET_SUNCENTER.
;	suncenter- Pass the derived location of the sun center in pixels (x,y)
;
;	pix_size- The size of the pixels in arcseconds.  If not passed, it
;		  uses GT_PIX_SIZE (2.45 arcsec).  This option allows the
;		  routine to be used for ground based images.
;	radius	- The radius in pixels.  GET_RB0P is called to get the radius
;		  and it is used to get the pixel size.  This option allows the
;		  routine to be used for ground based images.
;HISTORY:
;	Written 16-Jun-93 by M.Morrison
;	29-Jun-93  (AHM) Corrected calling sequence.
;        3-Aug-93 (MDM) Corrected the date option
;       16-Oct-93 (MDM) - Removed the tilt keyword input
;-
;
n = n_elements(pix)
nout = n/2
;
;-------------------- Get the Date
;
if (n_elements(date0) eq 0) then date = anytim2ints(!stime) $
			else date = anytim2ints(date0)
if ((n_elements(date) ne nout) and (n_elements(date) ne 1)) then begin
    message, 'Improper number of dates.  Using first date for all points.', /info
    date = date(0)
endif

;-------------------- Get the pixel size
;
if (keyword_set(pix_size0)) then pix_size = pix_size0
;
if (keyword_set(radius)) then begin
    ans = get_rb0p(date)
    sunr = ans(0,*)
    ravg = total(sunr)/n_elements(sunr)
    pix_size = ravg / radius
end
;
if (n_elements(pix_size) eq 0) then pix_size = gt_pix_size()
;
;--------------------    Get the sun center location
;
if (n_elements(suncenter) eq 0) then suncenter = sxt_cen(date, hxa=hxa, cmd=cmd, roll=roll0)
;
;--------------------    Get the roll
;
if (n_elements(roll) eq 0) then if (n_elements(roll0) ne 0) then roll = roll0 else roll = 0
full_roll = -1 * (roll) / !radeg
;
out = fltarr(2, nout)
x0 = suncenter(0,*)	& if (n_elements(x0) eq 1) then x0 = x0(0)
y0 = suncenter(1,*)	& if (n_elements(y0) eq 1) then y0 = y0(0)
;
x = (pix(0,*)-x0) * pix_size	;convert to arcseconds
y = (pix(1,*)-y0) * pix_size	;convert to arcseconds
out(0,*) =  cos(full_roll)*x + sin(full_roll)*y
out(1,*) = -sin(full_roll)*x + cos(full_roll)*y
;
;--------------------    Finish up
;
if (keyword_set(arcmin)) then out = out/60.
;
return, out
end

