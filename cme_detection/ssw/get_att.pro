pro get_att, tim_in, att, offset=offset, min_status=min_status, qdebug=qdebug
;
;+
;NAME:
;	get_att
;PURPOSE:
;	Given a set of input times, return the single ATT data record
;	closest to that time.
;CALLING SEQUENCE:
;	get_att, index, att
;	get_att, index, att, offset=offset, min_status=2
;INPUT:
;	tim_in	- The input time(s) in any of the 3 standard formats
;OPTIONAL KEYWORD INPUT:
;	min_status - The minimum acceptable ATT status
;			ATT.STATUS1 = 1: plain S/C commanded value used, no dejittering with IRU.
;				    = 2: S/C commanded value dejittered with IRU.
;				    = 4: HXA value dejittered with IRU.  Standard result, good.
;		     Most of the ATT data should be STATUS1 = 4.
;OUTPUT:
;	att	- The ATT data structure
;OPTIONAL KEYWORD OUTPUT:
;	offset	- The number of seconds that the matching ATT data is off
;		  from the input time(s)
;HISTORY:
;	Written 11-Aug-93 by M.Morrison (Using GET_PNT as starting point)
;	13-Sep-93 (MDM) - Modified slightly
;	19-Nov-93 (MDM) - Added MIN_STATUS option
;	18-May-95 (MDM) - Modified the logic to not loop through on a
;			  per orbit basis if the time span requested is
;			  4 days or less
;                       - Adjusted code to call TIM2DSET once per orbit
;                         not once per input time (TIM2DSET is called only
;			  once if the time span is less than 4 days)
;			- Both actions sped up the routine considerably
;	15-Aug-95 (MDM) - Corrected a bug where there the time span requested
;			  is less than 4 days,  but the times are not sent
;			  in in increasing time order.  The bug was introduced
;			  18-May-95 while trying to speed up the routine.
;-
tim = anytim2ints(tim_in)
n = n_elements(tim)
;
q1shot = (max(tim.day) - min(tim.day) ) le 4
if (keyword_set(qdebug)) then print, 'q1shot=', q1shot
;
offset = fltarr(n) - 1e+6
att = 0b
;
qfirst = 1
if (q1shot) then fid = strarr(n)+'same' $
	else tim2orbit, tim, fid=fid, tim2fms=tim2fms
ufid = fid(uniq(fid, sort(fid)))
nufid = n_elements(ufid)
for i=0,nufid-1 do begin
    ;read ATT file for each orbit
    ss = where(fid eq ufid(i), count)
    timarr_junk = int2secarr(tim(ss))
    junk = min(timarr_junk, imin)
    junk = max(timarr_junk, imax)
    rd_att, tim(ss(imin)), tim(ss(imax)), att0, /full_week, status=status
    ;;rd_att, tim(ss(0)), tim(ss(count-1)), att0, /full_week, status=status	;MDM removed 15-Aug-95
    if (keyword_set(qdebug)) then print, 'Fid ', i, ' of ', nufid-1, ' n match = ', count
    if (keyword_set(qdebug)) then help, att0
    if ((status eq 0) and (n_elements(min_status) ne 0)) then begin
	sss = where(att0.status1 ge min_status)	;select out to only get the good ATT data
	if (sss(0) eq -1) then status = 0 $
			else att0 = att0(sss)
    end

    if (qfirst and (status eq 0)) then begin		;MDM 13-Sep-93 check that status=0
	att = replicate(att0(0), n)
	qfirst = 0
    end

    if (status eq 0) then begin
	ii = tim2dset(att0, tim(ss), delta=off0)		;find closest time within orbit of data
	att(ss) = att0(ii)
	offset(ss) = off0
    end
end
;
end
