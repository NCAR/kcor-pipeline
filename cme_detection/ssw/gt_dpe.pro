function gt_dpe, item, dummy, header=header, string=string, short=short, spaces=spaces, $
		conv=conv, shutdur=shutdur
;
;+
;NAME:
;	gt_dpe
;PURPOSE:
;	To extract the bits corresponding to MBE (Mailbox Exposure Level) and
;	filter-A to calculate the DPE.  Optionally return a string mnemonic
;CALLING SEQUENCE:
;	x = gt_dpe(index)
;	x = gt_dpe(roadmap)
;	x = gt_dpe(roadmap, /conv)
;	x = gt_dpe(index.sxt, /string)
;	x = gt_dpe(index.sxt, /space)		;put single space before string
;	x = gt_dpe(index.sxt, space=3)		;put 3 spaces
;METHOD:
;	The input can be a structure or a scalar.  The structure can
;	be the index, or roadmap, or observing log.  If the input
;	is non-byte type, it assumes that the bit extraction had
;	already occurred and the "mask" is not performed on the input.
;INPUT:
;	item	- A structure or scalar.  It can be an array.
;		  If it is a scalar, it is the DPEs for the exposure(s)
;		  already taking into account if the 8% mask was used.
;OPTIONAL INPUT:
;	string	- If present, return the string mnemonic (long notation)
;	short	- If present, return the short string mnemonic
;	spaces	- If present, place that many spaces before the output
;		  string.
;	conv	- If present, convert the DPE level to milliseconds.
;       shutdur         - If this keyword is set, the SHUTTER duration is
;                         returned, not the effective exposure duration
;                         which takes into account the 8% mask.
;OUTPUT:
;	returns	- The MBE, a integer value or a string
;		  value depending on the switches used.  It is a vector
;		  if the input is a vector
;OPTIONAL OUTPUT:
;       header  - A string that describes the item that was selected
;                 to be used in listing headers.
;HISTORY:
;	Written 13-Nov-91 by M.Morrison
;	17-Apr-92 (MDM) - Changed string format for /CONV option
;			  from f10.1 to f8.1 (saved two spaces)
;	25-Apr-92 (MDM) - Called GT_MBE for the exposure duration for
;			  each MBE instead of having the table in the
;			  code (only want the table in one place)
;			- Changed code so that if an integer is passed
;			  as the input, it is assumed to be the DPE
;			  value (not the MBE value). - REMOVED the
;			  "filta" second parameter.
;	19-Aug-93 (MDM) - Corrected for special case since true adjustments 
;			  of the DPE because of mask use only happens for
;			  MBE 0 thru 7.  There are cases where the ND mask 
;			  is used in longer exposures typically in full frame.
;	 6-Jun-95 (MDM) - Modified to work properly for MBE=3 and ND filter
;			  manually specified.  It will be assigned DPE =4
;			  even though it is not really DPE=4 (it is the 
;			  closest valid value).
;-
;
if (n_params(0) gt 1) then begin
    message, 'Routine was changed not to accept FILTA', /info
    message, 'Please call without that parameter', /info
    return, -1
end
;
expdur_arr = gt_mbe(indgen(64), /conv)		;Exposure duration for each MBE
;
header_array = 'DPE'
fmt = '(i3)'
;
;----- Conversion between MBE and DPE
;DPE = MBE + 7 for DPE greater than 9 (when the mask is not used)
;      Look at the table below to see the relation ship for DPE < 9
;
dpe_nomask = [2, 4, indgen(62)+2+7]     ; Using the MBE as the indicy
;dpe_mask  = [0, 1, 3, -1, 5, 6, 7, 8]  ;7 DPE levels use a mask
dpe_mask   = [0, 1, 3,  4, 5, 6, 7, 8]  ;7 DPE levels use a mask - MDM 6-Jun-95 changed -1 to 4
					;When the mask is used, MBE should be 0,1,2,x,4,5,6,7
dpe2mbe      = [0,1,0,2,1,4,5,6,7,indgen(28)+2]
dpe_use_mask = [1,1,0,1,0,1,1,1,1,intarr(28)+0]		;1=yes, 0=no
;
siz = size(item)
typ = siz( siz(0)+1 )
if (typ eq 8) then begin
    mbe = gt_mbe(item)
    filta = gt_filta(item)

    ;ss_mask  = where(filta eq 6)
    ss_mask  = where((filta eq 6) and (mbe le 7))	;True adjustments of the DPE because of mask use only happens for
							;MBE 0 thru 7.  There are cases where the ND mask is used in longer
							;exposures typically in full frame.
    out = dpe_nomask(mbe)
    if (ss_mask(0) ne -1) then out(ss_mask) = dpe_mask(mbe(ss_mask))
end else begin
    out = item
    mbe = dpe2mbe(out)
    ss_mask = where( dpe_use_mask(out) )
end
;
if (keyword_set(conv)) then begin
    out = expdur_arr(mbe)
    ;
    fmt = '(f8.1)'
    header_array = 'DPE (ms)'
    ;
    if (not keyword_set(shutdur)) then begin        ;if not want shutter duration (want actual effective duration)
	mask8 = fltarr(n_elements(mbe)) + 1
	if (ss_mask(0) ne -1) then mask8(ss_mask) = 0.0805
	out = out * mask8
    end
    if (n_elements(out) eq 1) then out = out(0)		;turn into scalar
end
;
out = gt_conv2str(out, conv2str, conv2short, header_array, header=header, $
	string=string, short=short, spaces=spaces, fmt=fmt)
;
return, out
end
