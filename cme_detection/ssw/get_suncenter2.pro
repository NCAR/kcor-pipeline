function get_suncenter2, times, relative, code=code, fem=fem, delta=delta, $
	qdebug=qdebug, pieces=pieces
;
;+
;NAME:
;	get_suncenter2
;PURPOSE:
;	Given a set of input times, call GET_SUNCENTER and return the
;	SXT center pixel location.  It does the most efficient reading of
;	the PNT database as possible.
;CALLING SEQUENCE:
;	cen = get_suncenter2(times)
;	cen = get_suncenter2(index, code=hxacode, fem=fem)
;INPUT:
;	times	- The input time(s) in any of the 3 standard formats
;OPTIONAL INPUT:
;	relative- An input time can be passed, and the output will be
;		  an offset in FR pixels relative to the input time.
;OPTIONAL KEYWORD INPUT:
;	qdebug	- If set, print some debugging statements.
;	pieces	- If set, force the extraction on a piece by piece basis
;		  (normally if it is less than 3 days, it will do one read
;		  to the PNT file)
;OUTPUT:
;	cen	- The center of the SXT image in FR pixels
;OPTIONAL KEYWORD OUTPUT:
;	code	- GET_SUNCENTER code
;			= 0: error, no result
;			= 1: result may be poor, no IRU correction,
;			= 2: IRU jitter correction done (= normal result).
;	fem	- The FEM records for the time period covered
;	delta	- The offset in seconds between the input time and the PNT
;		  data record used for the pointing derivation
;HISTORY:
;	Written 20-Jun-93 by M.Morrison
;	15-Jul-93 (MDM) - Removed expanding of the time span being read when
;			  doing GET_SUNCENTER in chunks
;-
tim = anytim2ints(times)
n = n_elements(tim)
out = fltarr(2,n)
code = intarr(n)
delta = lonarr(n)
;
tim2orbit, tim, fid=fid, fem=fem
ufid = fid( uniq(fid) )
;
x = int2secarr(tim)		;handles case where times are not passed in increasing order
dt = (max(x) - min(x))/86400.	;time spanned by input times (in days)
if ((dt lt 3) and (not keyword_set(pieces))) then begin
    fid = strarr(n) + 'xxx'	;have it read everything in one read
    ufid = 'xxx'
end
;
for i=0,n_elements(ufid)-1 do begin
	ss = where(fid eq ufid(i), count)
	x = int2secarr(tim(ss))		;handles case where times are not passed in increasing order
	dummy = min(x, imin)
	dummy = max(x, imax)
	;st_tim = anytim2ints(tim(ss(imin)), off=-60*60)	;back up one hour because IRU interpolation needs sufficient data
	;en_tim = anytim2ints(tim(ss(imax)), off= 60*60)	;one hour past end time
								;could have some overlap in time, but it's a pain otherwise
	st_tim = anytim2ints(tim(ss(imin)))
	en_tim = anytim2ints(tim(ss(imax)))

	rd_pnt, st_tim, en_tim, pdata
	if (keyword_set(qdebug)) then print, fmt_tim(st_tim), ' to ', fmt_tim(en_tim)

	sc = get_suncenter(pdata, index=tim(ss), code=hxacode0, fem=fem, delta=delta0, /nofilt)
	if (keyword_set(qdebug)) then begin
	    dummy = where(hxacode0 le 1, count0)
	    print, count0, ' values out of ', n_elements(hxacode0), ' are bad'
	end
	out(0,ss) = reform(sc(0,*))
	out(1,ss) = reform(sc(1,*))
	code(ss) = hxacode0
	delta(ss) = delta0
end
;
if (keyword_set(relative)) then begin
    ii = tim2dset(times, relative, delta=delta0)
    if (delta0(0) eq 0) then begin
	out0 = out(*, ii)
    end else begin
	out0 = get_suncenter(index=relative, nofilt)
	out0 = out0(0:1,0)
    end
    for i=0,n-1 do out(*,i) = out(*,i) - out0
end
;
return, out
end
