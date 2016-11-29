function tim2carr, time, offset=offset, dc=dc

;+
;NAME
;    TIM2CARR
;PURPOSE
;    Determine the decimal Carrington rotation number or the Carrington
;    longitude of the central meridian of the sun for a given time or
;    set of times
;INPUT
;    TIME - Scalar or vector of times in any standard format
;OPTIONAL KEYWORD INPUT:
;    OFFSET - Reference heliographic longitude(s).  The default is 0
;             (central meridian).  For example, if offset = 90, then
;             the Carrington rotation number which coincides with
;	      90 deg heliographic longitude at the supplied time is
;	      returned.
;    DC  - If set, return the decimal Carrington rotation number of the
;	   central meridian rather than the Carrington longitude
;OUTPUT
;    Carrington longitude or, optionally, decimal Carrington rotation
;    number, if keyword DC is set
;CALLING SEQUENCE
;    CARR = TIM2CARR('16-Feb-1994 10:46:27')
;HISTORY
;    Feb 15, 1994 - GLS - Written using CARR2EX as starting point
;
; Modified    : Version 2, November 4, 1997 Giulio Del Zanna, UCLAN, UK
;		  Corrected the error that not any standard time 
;		  format was accepted. Different time formats were 
;		  producing different results.
;
;    23-Feb-1998 - S.L.Freeland - handle absolutely ANY SSW time
;                  4-nov-97 change was problem for external, etc.
;
;       Version 4, 05-Nov-2009, WTT, corrected use of OFFSET when longitude in
;               degrees is returned.
;
; Version     : Version 4
;-

max_diff = 12/360.


;get the proper format to be used by GET_SUN (e.g. '16-Feb-1994 10:46:27'):
;-----------------------------------------------------------------------

;proper_time=utc2str(tai2utc( utc2tai(str2utc(time))),/STIME)
proper_time=anytim(time,out='ints')   ; anything in , internal format out

sun_data = get_sun(proper_time,carr=carr,he_lon=he_lon)
if n_elements(offset) eq 0 then offset = intarr(n_elements(carr))

if keyword_set(dc) then begin
  int_carr = fix(carr)
  frac_carr = carr - fix(carr)
  frac_lon = (360. - he_lon)/360.
  cross_for = where((abs(frac_carr-frac_lon) gt max_diff) and $
		    (frac_carr gt frac_lon),count_for)
  cross_rev = where((abs(frac_carr-frac_lon) gt max_diff) and $
		    (frac_carr lt frac_lon),count_rev)
  if count_for gt 0 then int_carr(cross_for) = int_carr(cross_for) + 1
  if count_rev gt 0 then int_carr(cross_rev) = int_carr(cross_rev) - 1
  out = int_carr + frac_lon - offset/360.
endif else begin
  out = (he_lon + offset) mod 360.
end

return, out

end

