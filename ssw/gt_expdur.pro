
function gt_expdur, index, shutdur=shutdur, header=header, string=string, $
		short=short, spaces=spaces, nocorr=nocorr, original=original
;
;+
;NAME:
;	gt_expdur
;PURPOSE:
;	Calculate the actual exposure duration of an image. The
;	returned value is in millisec.
;CALLING SEQUENCE:
;       x = gt_expdur(index)
;       x = gt_expdur(index, /string)
;INPUT:
;	index		- the SXT index structure
;OPTIONAL INPUT:
;	shutdur		- If this keyword is set, the SHUTTER duration is
;			  returned, not the effective exposure duration
;			  which takes into account the 8% mask.
;       string  - If present, return the string mnemonic (long notation)
;       short   - If present, return the short string mnemonic
;       spaces  - If present, place that many spaces before the output
;                 string.
;	nocorr	- If present, do not perform the exposure level correction
;	original- If set, return the original exposure commanded (from 
;			index.sxt rather than from history record)
;OUTPUT:
;	returns		- the measured exposure duration (in msec)
;OPTIONAL OUTPUT:
;       header  - A string that describes the item that was selected
;                 to be used in listing headers.
;HISTORY
;	Written 13-Nov-91 by M.Morrison
;	21-Apr-92 (MDM) Made output a scalar if only one element
;	28-Apr-92 (MDM) Adjusted the SXTE-U measured exposure duration by
;			a correction factor based on ground calibration
;			with the Kyoritsu.  Also added "nocorr" parameter
;			input.
;	25-Jun-92 (MDM) Added capability of extracting the exposure duration
;			from the GND portion of the index structure when
;			present (ground based pre-launch data)
;	 7-Jan-93 (MDM) Added capability to use the commanded exposure
;			duration when the measured duration is zero (bad
;			telemetry)
;	12-May-93 (MDM) Added capability to use the commanded exposure
;			duration when the measured duration is 32767 (bad
;			telemetry)
;       17-Jun-93 (MDM) Added capability to read from history index record
;			Added /ORIGINAL option
;	 1-Jul-93 (SLF) Kludge for 11-May SEU, return expected values
;	19-Aug-93 (MDM) Modification to not apply the shutter exposure 
;			correction factor to the dark images
;	27-Aug-93 (MDM) Allow roadmap to be passed in, just return expected
;			exposure duration and flag the error
;	23-Apr-99 (LWA) Corrected header description of keyword /original
;        5-May-1999 -   S.L.Freeland - return expected values if
;                       actual reported value is > 100% nominal
;                       [ only for narrow slit exposures, mbe ={0,1} ]
;	28-May-2009 (Aki Takeda) Modified to accept FITS header. 
;                       Returns header.exptime if not /original set.
;                       Replace index.sxt.expdur and index.gen.day with
;                       corresponding FITS tags.
;	29-Jul-2009 (Aki T) Corrected bad label position. 
;-
;
;---- Exposure resolution used by SXTE-U for different MBEs
;expres = 0 (0.0016 msec)	for MBE= 0 to  4	(.8 to 38 msec)
;expres = 1 (0.0512 msec)	for MBE= 5 to 13	(58 to 948 msec)
;exprec = 2 (1.638 msec)	for MBE=14 to 24	(1.338 to 42.718 sec)
;expres = 3 (52.429 msec)	for MBE=25 to 29	(60.418 to 241.668 sec)
;expres = 3 (52.429 msec)	for MBE=30		(Variable)
;exprec = 2 (1.638 msec)	for MBE=31 to 49	(0.25 to 4.75 sec)
;expres = 3 (52.429 msec)	for MBE=50 to 63	(5.00 to 8.25 sec)
expres_arr = [intarr(5)+0, intarr(9)+1, intarr(11)+2, $
		intarr(5)+3, 3, intarr(19)+2, intarr(14)+3]
expres_msec_arr = [0.0016, 0.0512, 1.638, 52.429]	;number of millisec
				;per "tick" in expdur
;
siz = size(index)
typ = siz( siz(0)+1 )
tags = tag_names(index)

if ((tags(0) eq 'SIMPLE') and not keyword_set(original)) then return, index.exptime else goto, NEXT  ; 28-May-2009
if ((typ ne 8) or (tags(1) ne 'SXT')) then begin
    tbeep, 3
    print, 'GT_EXPDUR: Only SXT index can be used with this routine.
    print, 'GT_EXPDUR: Returning expected duration'
    return, gt_dpe(index, /conv)
end
;
NEXT:
;
if (his_exist(index) and (not keyword_set(original))) then return, index.his.expdur
;
explev0		= gt_mbe(index, corr_fact=corr_fact_arr)
if (keyword_set(nocorr)) then begin
    corr_fact = 1.0			;do no correction
end else begin
    corr_fact = corr_fact_arr(explev0)
    ss = where(gt_expmode(index) eq 1)
    if (ss(0) ne -1) then corr_fact(ss) = 1.0		;do not apply the shutter exposure correction factor to the dark images
end
;
if (tags(0) eq 'SIMPLE') then expdur0=index.expdur else $                          ; 28-May-2009
expdur0		= index.sxt.expdur
filta		= gt_filta(index)
ss		= where(filta eq 6)
;

expres	= expres_arr(explev0)
act_expos = expdur0 * expres_msec_arr(expres) * corr_fact
;
ssss 		= where(expdur0 eq 0)
if (ssss(0) ne -1) then begin		;added 7-Jan-93
    print, 'GT_EXPDUR: Measure duration(s) is zero - Using expected duration value'
    act_expos(ssss) = gt_mbe(index(ssss), /conv)
end
;
ssss 		= where(expdur0 eq 32767)
if (ssss(0) ne -1) then begin		;added 12-May-93
    print, 'GT_EXPDUR: Measure duration(s) is 32767 - Using expected duration value'
    act_expos(ssss) = gt_mbe(index(ssss), /conv)
end
;
; SLF - SEU Kludge, May 11 
; window= '10-may 0:0' - 13-may 0:0'
;seuexp=where( (abs(index.gen.day - 5245) le 1) and $
;       (explev0 ge 5 and explev0 le 13),count)

if (tags(0) eq 'SIMPLE') then daynum=index.day else daynum=index.gen.day               ; 28-May-2009
seuexp=where( (abs(daynum - 5245) le 1) and (explev0 ge 5 and explev0 le 13),count)
if count gt 0 then begin
   tbeep
   print,'GT_EXPDUR: SEU Corrupted Exposure Duration, using expected duration'
   act_expos(seuexp)  = gt_mbe(index(seuexp), /conv)
endif

mbeconv=gt_mbe(index,/conv)
ssss=where( gt_mbe(index) le 1 and $
	     (act_expos gt (1.5*mbeconv)) , badcnt)
if badcnt gt 0 then begin
   print,'GT_EXPDUR: Returning expected duration for '+strtrim(badcnt,2) + ' corrupt short exposures'
   act_expos(ssss)=mbeconv(ssss)
endif

if (n_elements(tags) ge 3) then if (tags(2) eq 'GND') then act_expos = index.gnd.aexp/1000.		;added 25-Jun-92
;
if (not keyword_set(shutdur)) then begin	;if not want shutter duration (want actual effective duration)
    mask8 = fltarr(n_elements(act_expos)) + 1
    if (ss(0) ne -1) then mask8(ss) = 0.0805
    act_expos = act_expos * mask8
end
;
out = act_expos
fmt = '(f12.2)'
header_array = 'ExpDur(msec)'
out = gt_conv2str(out, conv2str, conv2short, header_array, header=header, $
        string=string, short=short, spaces=spaces, fmt=fmt)
;
if (n_elements(out) eq 1) then out = out(0)	;turn it into a scalar
return, out
end
