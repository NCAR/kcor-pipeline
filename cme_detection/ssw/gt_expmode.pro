function gt_expmode, item, header=header, string=string, short=short, spaces=spaces
;
;+
;NAME:
;	gt_expmode
;PURPOSE:
;	To extract the bits corresponding to exposure mode and optionally
;	return a string mnemonic.
;CALLING SEQUENCE:
;	print, gt_expmode()			;to list the nemonics
;	x = gt_expmode(index)
;	x = gt_expmode(roadmap)
;	x = gt_expmode(index.sxt, /string)
;	x = gt_expmode(indgen(4)+1)		;used with menu selection
;	x = gt_expmode(index, /space)		;put single space before string
;	x = gt_expmode(index, space=3)		;put 3 spaces
;METHOD:
;	The input can be a structure or a scalar.  The structure can
;	be the index, or roadmap, or observing log.  If the input
;	is non-byte type, it assumes that the bit extraction had
;	already occurred and the "mask" is not performed on the input.
;INPUT:
;	item	- A structure or scalar.  It can be an array.  If this
;		  value is not present, a help summary is printed on the
;		  exposure mode names used.
;OPTIONAL INPUT:
;	string	- If present, return the string mnemonic (long notation)
;	short	- If present, return the short string mnemonic
;	spaces	- If present, place that many spaces before the output
;		  string.
;OUTPUT:
;	returns	- The shutter mode, a integer value or a string
;		  value depending on the switches used.  It is a vector
;		  if the input is a vector
;OPTIONAL OUTPUT:
;       header  - A string that describes the item that was selected
;                 to be used in listing headers.
;HISTORY:
;	Written 7-Nov-91 by M.Morrison
;       13-Nov-91 MDM - Added "header" and "spaces"  option
;       1-Feb-2007 (Aki Takeda) - Modification to accept YLA FITS headers.
;-
;
header_array = ['ExpM', 'M']
conv2str = ['Norm', 'Dark', 'Calb', '????']	;4 characters
conv2short = ['N', 'D', 'C', '?']		;2 characters
;
if (n_params(0) eq 0) then begin
    print, 'String Output for GET_EXPMODE'
    for i=0,2 do print, i, conv2str(i), conv2short(i), format='(i3, 2x, a6, 2x, a6)'
    return, ''
end
;
siz = size(item)
typ = siz( siz(0)+1 )
if (typ eq 8) then begin
    ;Check to see if an index was passed (which has the "periph" tag
    ;nested under "sxt", or a roadmap or observing log entry was passed
    tags = tag_names(item)
    case 1 of
      (tags(0) eq 'GEN') : out = item.sxt.explevmode 
      (tags(0) eq 'SIMPLE') : out= mask(item.explevmo, 6,2) ; for FITS headers (1-Feb-2007)
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
if (typ eq 1) then out = mask(out, 6, 2)
out = out>0<3	;check the range
;
out = gt_conv2str(out, conv2str, conv2short, header_array, header=header, $
	string=string, short=short, spaces=spaces)
;
return, out
end
