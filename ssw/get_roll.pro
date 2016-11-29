function get_roll, times, notsxt=notsxt, sxt_offset=sxt_offset, att=att, $
   predict=predict, status=status, bad=bad
;
;+
;NAME:
;	get_roll
;PURPOSE:
;	To return the roll angle of the SXT image (or S/C) relative to solar 
;	north in degrees counter clockwise (this convention is the opposite
;	of that in the ADS raw database)
;SAMPLE CALLING SEQUENCE:
;	roll = get_roll(times, status=status)
;	roll = get_roll(/sxt_offset)
;	roll = get_roll(times, /notsxt)
;	roll = get_roll(att=att)
;INPUT:
;	times	- The set of times that the roll is needed.
;OPTIONAL KEYWORD INPUT:
;	sxt_offset - If set, just return the scalar value which is the offset
;		  the SXT CCD north relative to solar north (for the case 
;		  where S/C north and solar north are aligned).  The value is
;		  in degress counter clockwise.
;	notsxt	- If set, do not incorporate the SXT offset between CCD north
;		  and S/C north.
;	predict	- If set, then use the coefficients for the fit to the seasonal
;		  changes in the S/C roll.
;OPTIONAL KEYWORD INPUT/OUTPUT:
;	att	- An ATT structure can be passed in and the proper value will be
;		  scaled to degrees and the SXT offset optionally incorporated.
;OPTIONAL KEYWORD OUTPUT:
;       status - roll status (0=predicted, 1=processed from ADS)
; 
;METHOD:
;	The default is to incorporate the roll offset between the CCD north
;	axis and the S/C north axis, such as to return the roll between the
;	SXT CCD north axis and the solar axis.
;
;	If the ATT database is not available, then a function is used which
;	approximates the seasonal variation of the S/C roll.
;
;	The SXT data taken between 1-Sep-92 and 5-Sep-92 can be used to
;	verify the sign conventions of the roll.  Canopus was lost and the S/C
;	roll was large.
;		* ATT roll value is 10 degrees (counter clockwise positive)
;		* ADS raw roll value was -10 degrees (clockwise positive)
;		* In the SXT image, solar north points to the upper right of 
;		  the image for this roll value, so the SXT image needs to be 
;		  rotated 10 degrees counter clockwise to put solar north 
;		  straight up.  CAUTION: The IDL routine ROT takes values
;		  clockwise positive.
;		* In the SXT image, solar north is 10 degrees CLOCKWISE from
;		  straight up (CCD North) (this is the opposite since we are
;		  using the CCD as the reference)
;
;-------------- SXT ROLL OFFSET (previously called tilt) --------------------
;
;	The angle in degrees that the SXT CCD is rotated counter clockwise with 
;	respect to solar north (for the case where S/C north and solar north are 
;	aligned (S/C roll = zero)).  
;
;	* Solar N is ~1 deg to the RIGHT of CCD N (for zero S/C roll)
;	* The sun spots move lower on the CCD as the sun rotates west (but
;	  this effect is very difficult to see since the spots migrate).
;
;	Value of -1.0:  Date: Mid-92
;			Determined by Hara in mid-1992 by looking at the 
;			sun center position during the 8-May-92 S/C offpoint.
;			An apparent angle of 0.85 degrees was seen in the images
;			but the S/C also changed in roll by 0.15 degress between
;			images for a total difference of 1.0 degrees between
;			CCD north and Solar North for S/C roll of zero degrees.
;			The derived value was actually 1.01 +/- 0.02 degrees.
;	Value of +1.0:  Date: Sept-93
;			Determined that there was a sign error/misunderstanding
;			from Mid-92 value and work by LaBonte in Sep-93
;
;			LaBonte coaligned sun spots on SXT and ground based
;			full frame images from 25-Jun-92 and derived a that "sun
;			north is 1.1 degress west of SXT north".  This 1.1 degrees
;			includes a S/C roll of 0.04 degrees, so the offset between
;			S/C north and CCD north is 1.06 deg.
;HISTORY:
;	Written 11-Aug-93 by M.Morrison
;	17-Sep-93 (MDM) - Changed SXT roll offset from -1.0 to +1.0
;			- Added /PREDICT keyword option to calculate the predicted
;			  roll value due to seasonal changes.
;	 1-Oct-93 (MDM) - Modified not to print warning message when using /PREDICTED
;			  option
;	 7-Oct-93 (MDM) - Make the output scalar if it is one element
;	31-oct-93 (SLF) - Removed beeps and warnings, since they happen every time
;        5-oct-94 (SLF) - Update sxt_offset from 1.0 to .70 based on work by
;			  Jean-Pierre Wuelser using Mercury Transit Data and
;                         additonal work by Nishio-san
;       10-may-95 (SLF) - add STATUS output keyword
;			     1 -> predicted	; *** 
;			     0 -> from ADS	; ***
;       12-jan-96 (SLF) - Fix STATUS definition (header definition inverted) 
;-
;
if (keyword_set(notsxt)) then begin
    offset = 0.0
end else begin
;    offset = 1.0	;changed from -1.0 to +1.0 on 17-Sep-93
     offset = .70	;changed from +1.0 to +7.0 on  5-oct-94
end
;
if (keyword_set(sxt_offset)) then return, offset
;
if (keyword_set(times)) then begin
     times0 = anytim2ints(times)
     n = n_elements(times0)
end else begin
    n = n_elements(att)
    if (n eq 0) then begin
	message, 'You must pass in ATT if you do not pass in TIMES', /info
	return, -999
    end
    times0 = anytim2ints(att)
end
;
bad = bytarr(n)
out = fltarr(n)
status=lonarr(n)
;
if ( keyword_set(times) and (not keyword_set(predict)) ) then begin
    get_att, times, att, off=off
    ss = where(off eq -1e+6)
    if (ss(0) ne -1) then bad(ss) = 1b
end
;
siz = size(att)
typ = siz( siz(0)+1 )
if (typ ne 8) then begin	;ATT did not get read properly (?)
    bad(*) = 1
end else begin
    ss = where(att.ads eq 0)	;no ADS roll value written into ATT structure
    if (ss(0) ne -1) then bad(ss) = 1b
end
status(*)=bad
;
;------------------------- Grab the roll out of the ATT structure
;
ss = where(bad eq 0)
if (ss(0) ne -1) then out(ss) = att(ss).pnt(2)*.1 / 60. / 60.	;convert to degrees
;
;------------------------- Derive the predicted roll value based on season
;
ss = where(bad eq 1)
if (ss(0) ne -1) then begin
;    if (not keyword_set(predict)) then tbeep, 3
    n1 = n_elements(ss)
;    if (not keyword_set(predict)) then begin
;	print, 'GET_ROLL: Using predicted roll value for ' + strtrim(n1,2) + ' out of ' + strtrim(n,2) + ' input times'
;	print, 'GET_ROLL: Note that the predicted roll function is rather poor'
;    end
    ;
    tt = int2secarr(times0(ss), '1-sep-91')/86400.	;days since 1-sep-91
    coeff2 = [    -0.348920,      73.2662,    -0.207804,      78.0143,    0.0465753,      1.95533,    0.0690104,    0.0362150]
    roll_funct, tt, coeff2, vals
    out(ss) = vals
end
;
out = out + offset
if (n_elements(out) eq 1) then out = out(0)		;make it scalar if single element
return, out
end
