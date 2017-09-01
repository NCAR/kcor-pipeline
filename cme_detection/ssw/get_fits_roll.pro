;+
; Project     : SOHO, YOHKOH
;
; Name        : GET_FITS_ROLL
;
; Purpose     : Get image roll
;
; Category    : imaging, FITS
;
; Syntax      : roll=get_fits_roll(stc)
;
; Inputs      : struct - FITS-like structure
;
; Outputs     : ROLL = roll (degrees clockwise positive)
;
; Keywords    : NON_STANDARD_FITS = set to use non-standard roll
;               keywords if FITS keyword-values are missing.
;
; History     : 29 Sept 2008, Zarro (ADNET) - written
;               19 Feb 2009, Zarro (ADNET) - added check for SOLAR_P0 
;               26 March 2009, Zarro (ADNET) - changed to function
;               9 July 2009, Zarro (ADNET) 
;                 - added /NON_STANDARD_FITS to search for cases when 
;                  standard FITS keyword/values are missing or zero.
;               24 May 2010, Zarro (ADNET)
;                 - removed /NON_STANDARD_FITS check as it prematurely
;                   stopped searching for non-zero roll values. 
;                 - changed search order to check standard roll 
;                   keywords (CROTA1, CROTA2) first. If people
;                   just complied with standards, we wouldn't have to
;                   jump thru such hoops.
;               07-Jul-2010, William Thompson, GSFC (ADNET)
;                 - Don't reject roll values if zero.
;               08-Jul-2010, WTT, only use SOLAR_P0 for Kanzelhoehe files
;               15-May-2014, Zarro (ADNET), undid previous mod.
;
; Contact     : dzarro@solar.stanford.edu
;-

function get_fits_roll,stc,verbose=verbose,$
                  non_standard_fits=non_standard_fits,_extra=extra

if ~is_struct(stc) then return,0.
nimg=n_elements(stc)
roll=0.
standard_fits=~keyword_set(non_standard_fits)

if nimg gt 1 then roll=replicate(roll,nimg)

;-- Next check all the possible CROTx possibilities.

choices=['crota1','crota2','crot','crota']
nchoices=n_elements(choices)                                                        
for i=0,nchoices-1 do begin
 if have_tag(stc,choices[i],pindex,/exact) then begin
   if keyword_set(verbose) then message,'using '+choices[i]+' for roll value',/cont
   roll=stc.(pindex)                  
   return,roll
 endif
endfor

;-- Next check the non-standard ones. If a roll value was not found in
;   the previous CROTx locations, use the first roll found here.

choices=['sc_roll','p_angle','angle']
nchoices=n_elements(choices)                                                        
for i=0,nchoices-1 do begin
 if have_tag(stc,choices[i],pindex,/exact) then begin
  stcp=stc.(pindex)
   if keyword_set(verbose) then message,'using '+choices[i]+' for roll value',/cont
   roll=-stc.(pindex)                  
   return,roll
 endif
endfor

;--- DMZ commented out since code below is never reached and because
;    special case observatories shouldn't be hard-wired into a GEN routine

;-- Also check for SOLAR_P0, but only for specific observatories.  A number of
;   observatories include this keyword in their header without it representing
;   the image roll value.
;
;if have_tag(stc, 'origin', pindex, /exact) then begin
;    if strmid(strupcase(stc.origin),0,11) eq 'KANZELHOEHE' then begin
;        if have_tag(stc,'solar_p0',pindex,/exact) then begin
;            roll = -stc.(pindex)
;            return, roll
;        endif
;    endif
;endif
                       
return,roll & end
