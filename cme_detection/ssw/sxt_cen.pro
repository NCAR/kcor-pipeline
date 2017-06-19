function sxt_cen, times, hxa=hxa, cmd=cmd, delta=delta, roll=roll, $
   off_from_cmd=del_mat, oride_pnt_chk=oride_pnt_chk, rawcmd=rawcmd
;
;+
;NAME:
;	sxt_cen
;PURPOSE:
;	To return the pixel coordinates of the center of the SXT image using
;	either GET_SUNCENTER, HXA_SUNCENTER or S/C commanded values.
;SAMPLE CALLING SEQUENCE:
;	out = sxt_cen(index)
;	out = sxt_cen(index, /hxa)
;	out = sxt_cen(index, /cmd)
;	out = sxt_cen(index, roll=roll)
;	out = sxt_cen(index, roll=roll, /cmd)
;       out = sxt_cen(index, /rawcmd)		; dont apply seasonal correct.
;INPUT:
;	times	- The list of times for which the coordinates are required
;OPTIONAL KEYWORD INPUT:
;	hxa	- If set, use HXA_SUNCENTER.  Default is to use GET_SUNCENTER
;	cmd	- If set, use the S/C commanded pointing data file.  The true
;		  suncenter can be up to 4-5 pixels different because of the
;		  "slop" in the attitude control.  Default is to use 
;		  GET_SUNCENTER
;	oride_pnt_chk - If set, then do not compare the ATT/GET_SUNCENTER
;		  results to the commanded values to see that they are
;		  truly valid points.  This is useful for times when the
;		  commanded pointing history file is not updated properly
;		  or for real time applications when the commanded pointing
;		  history is not updated yet.
;       rawcmd -  if set, use commanded and do not apply seasonal correction
;OPTIONAL KEYWORD OUTPUT:
;	delta	- Time difference (in s) between index time and pnt
;                 time for each sun center position.  A value larger than a few
;                 seconds indicates that the suncenter position may not be
;                 reliable.  It is only valid when not using /HXA or /CMD
;		  options.
;	roll	- The SXT roll in degrees.  The CCD-north is "roll" degrees
;		  counter clock wise from solar-N.
;METHOD:
;	This routine is intended as a front end to return the pointing 
;	information.  It does a check to see that the PNT files exist 
;	when using GET_SUNCENTER or HXA_SUNCENTER.
;
;       The seasonal/mission long drift correction can be disabled
;       the the IDL command: setenv,'ys_no_attcmd_corr=1'
;HISTORY:
;	Written 10-Jun-93 by M.Morrison
;	10-Jul-93 (MDM) - Check that the value to be returned is believable
;			  and if not, use the /CMD option for the bad values.
;	14-Jul-93 (MDM) - Replaced some code with a call to PNT_EXIST
;	18-Aug-93 (MDM) - Replaced PNT_EXIST call with YDB_EXIST
;			- Replaced call to GET_SUNCENTER with a call to
;			  GET_ATT if the ATT files exist
;	19-Aug-93 (MDM) - Added DELTA variable
;	17-Sep-93 (MDM) - Added ROLL keyword output
;			  Introduced code to call GET_ROLL
;	 2-Oct-93 (MDM) - Corrected error where a problem arises when some
;			  of the ATT files exist, but not the one needed.
;	16-Oct-93 (MDM) - Make sure that the roll variable is defined 
;	19-Nov-93 (MDM) - Added "min_status=2" call to GET_ATT so that the
;			  results returned are at least acceptably good
;	11-Jan-94 (MDM) - Modified not to display "values returned are
;			  unreasonable" message if /CMD is set.
;	10-Feb-94 (MDM) - Modified the criteria that is used to recognize bad
;			  results in the ATT database to use the relative
;			  offset from commanded IN ADDITION to the absolute value
;			  of "lt 100 or gt 900".  If x or y is more than 50
;			  pixels from expected, and outside the above range, then 
;			  it is flagged as bad and the expected (commanded value) 
;			  is used.
;	21-Feb-94 (MDM) - Added /ORIDE_PNT_CHK to optionally not compare the 
;			  ATT/GET_SUNCENTER results to the commanded values to see 
;			  that they are truly valid points
;	21-Feb-94 (MDM) - Added capability of setting /ORIDE_PNT_CHK by setting
;			  and environment variable "YS_ORIDE_PNT_CHK" to non-null
;	29-Nov-94 (MDM) - Print warning statement if the ATT record that it selects
;			  is over 5 minutes from the requested time.
;	14-Feb-95 (MDM) - Changed warning message to say ATR instead of PNT
;        9-Mar-95 (MDM) - Modified SXT_CMD_PNT to apply the correction required for
;                         the seasonal/mission long drift between the
;                         commanded and actual.
;       25-mar-95 (SLF) - add RAWCMD keyword and function
;-
;
roll = 0
code = 0
rawcmd=keyword_set(rawcmd)
cmd=keyword_set(cmd) or rawcmd
if (keyword_set(hxa)) then code = 1
if cmd then code = 2
;
if (code ne 2) then begin	;check that PNT file exists
    if ( (not ydb_exist(times, 'pnt')) and (not ydb_exist(times, 'att')) ) then begin
	print, 'SXT_CEN: No ATR and ATT files available.  Going to use S/C commanded value', string(7b)
	code = 2
    end
end
;
case code of
    0: begin
	qgot_it = 0
	if (ydb_exist(times, 'att')) then begin		;this is the best and most accurate case - ATT database exists...
	    get_att, times, att, offset=delta, min_status=2
	    if (get_nbytes(att) gt 10) then begin	;got something
		out = att.pnt(0:1)/100.
		roll = get_roll(att=att)
		qgot_it = 1
		if (max(delta) gt 600) then begin
		    print, 'SXT_CEN: Warning. ATT record mismatch by over 5 minutes'
		    tbeep, 3
		end
	    end
	end
	if (not qgot_it) then begin
	    out = get_suncenter2(times, delta=delta)
	    out = out(0:1, *)
	    roll = get_roll(times)		;it will end up using CMD since ATT does not exist
	end
       end
    1: begin
	out = hxa_suncenter(index=times, /nofilt)
	out = out(0:1, *)
       end
    2: begin
	out = sxt_cmd_pnt(times,rawcmd=rawcmd)
	roll = get_roll(times, /predict)
       end
endcase
;
if (n_elements(delta) eq 0) then delta = intarr(n_elements(out(0,*)))
;
if ( (not keyword_set(oride_pnt_chk)) and (get_logenv('YS_ORIDE_PNT_CHK') eq "")) then begin
    cmd_pnt = sxt_cmd_pnt(times, rawcmd=rawcmd)
    del_mat = out - cmd_pnt
    ;ss = where( (out(0:1,*) lt 100) or (out(0:1,*) gt 900) )	;check for unreasonable center positions
    ;if (ss(0) ne -1) then begin
    ;ss = where(abs(del_mat(*)) gt 50)
    ss = where( (abs(del_mat(*)) gt 50) and ( (out(0:1,*) lt 100) or (out(0:1,*) gt 900) ) )
    if ((ss(0) ne -1) and (not keyword_set(cmd))) then begin
	message, 'Values returned are unreasonable. ', /info
	message, 'Going to selectively use commanded values', /info
	ii = ss/2				;/2 because del_mat is 2xN
	ii = ii(uniq(ii))
	out2 = sxt_cmd_pnt(times(ii),rawcmd=rawcmd)
	out(0:1, ii) = out2(0:1,*)
    end
end
;
return, out
end
