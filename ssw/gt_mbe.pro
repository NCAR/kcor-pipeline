function gt_mbe, item, header=header, string=string, short=short, spaces=spaces, $
		conv=conv, corr_fact=corr_fact
;
;+
;NAME:
;	gt_mbe
;PURPOSE:
;	To extract the bits corresponding to MBE (Mailbox Exposure Level) and
;	optionally return a string mnemonic
;CALLING SEQUENCE:
;	x = gt_mbe(index)
;	x = gt_mbe(roadmap)
;	x = gt_mbe(index.sxt, /string)
;	x = gt_mbe(index.sxt, /space)		;put single space before string
;	x = gt_mbe(index.sxt, space=3)		;put 3 spaces
;METHOD:
;	The input can be a structure or a scalar.  The structure can
;	be the index, or roadmap, or observing log.  If the input
;	is non-byte type, it assumes that the bit extraction had
;	already occurred and the "mask" is not performed on the input.
;INPUT:
;	item	- A structure or scalar.  It can be an array.
;OPTIONAL KEYWORD INPUT:
;	string	- If present, return the string mnemonic (long notation)
;	short	- If present, return the short string mnemonic
;	spaces	- If present, place that many spaces before the output
;		  string.
;	conv	- If present, convert the MBE level to milliseconds.
;OUTPUT:
;	returns	- The MBE, a integer value or a string
;		  value depending on the switches used.  It is a vector
;		  if the input is a vector
;OPTIONAL KEYWORD OUTPUT:
;       header  - A string that describes the item that was selected
;                 to be used in listing headers.
;	corr_fact- The correction factor to go from SXTE-U measured 
;		   duration to actual duration (as derived by Kyoritsu
;		   calibration).  Actual = measured * corr_fact
;HISTORY:
;	Written 13-Nov-91 by M.Morrison
;	28-Apr-92 (MDM) - Added the correction factor lookup table
;			  and the parameter "corr_fact"
;			- Changed expdur_arr values
;				MBE = 0 to 0.00096 (was 0.0008)
;				MBE = 1 to 0.00288 (was 0.0024)
;				MBE = 2 to 0.017   (was 0.018)
;        3-Feb-2000 S.L.Freeland - special case for
;                   (Dark or Cal) + ( MBE={0,1} ) + /CONV + index input
;                   Return CCD integration time not shutter time  
;        1-Feb-2007 (Aki Takeda) - Modification to accept YLA FITS headers.
;                              
;-
;
;---- Exposure duration for each MBE
expdur_arr = [0.00096, 0.00288, 0.017, 0.028, 0.038, $
                                0.058, 0.078, 0.118, 0.168, 0.238, $
                                0.338, 0.468, 0.668, 0.948, 1.338, $
                                1.888, 2.668, 3.778, 5.338, 7.548, $
                                10.678, 15.108, 21.358, 30.208, 42.718, $
                                60.418, 85.438, 120.828, 170.878,  $
                                241.668, -1]    ;in seconds
corr_fact = [1.378, 1.365, 1.014, 1.011, 1.008, $
		1.006, 1.005, fltarr(57)+1.003]
;
expdur_arr = [expdur_arr, (findgen(33)+1)*.25]
expdur_arr = expdur_arr*1000    ;convert to millisec
;
header_array = ['MBE', 'MBE']
fmt = '(i3)'
;
siz = size(item)
typ = siz( siz(0)+1 )
if (typ eq 8) then begin
    ;Check to see if an index was passed (which has the "periph" tag
    ;nested under "sxt", or a roadmap or observing log entry was
    ;passed
    tags = tag_names(item)
    case 1 of
      (tags(0) eq 'GEN') : out = item.sxt.explevmode 
      (tags(0) eq 'SIMPLE') : out= mask(item.explevmo, 0,6) ; for FITS headers (1-Feb-2007)
      else : out = item.explevmode
    endcase
end else begin
    out = item
end
;
;---- If the item passed is byte type, then assume that it is a
;     raw telemetered value and the item's bits need to be extracted
siz = size(out)
typ = siz( siz(0)+1 )
if (typ eq 1) then out = mask(out, 0, 6)
out = out>0<63	;check the range
;
if (keyword_set(conv)) then begin
    out = expdur_arr(out)
;   S.L.Freeland, 3-Feb-2000 - reflect minimum integration for dark/FT images
    if data_chk(item,/struct) then begin
       sss=where(gt_mbe(item) lt 2 and gt_expmode(item) gt 0,ssscnt)
       if ssscnt gt 0 then out(sss)=7.91
    endif
    fmt = '(f10.1)'
    header_array = 'MBE (msec)'
end
;
out = gt_conv2str(out, conv2str, conv2short, header_array, header=header, $
	string=string, short=short, spaces=spaces, fmt=fmt)
;
return, out
end
