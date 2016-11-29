;+
; NAME:
;        FIX_OLD_ATT
; PURPOSE:
;        Remove the wrong mission correction offset from old ATT data.
;
; CATEGORY:
; CALLING SEQUENCE:
;        fix_old_att,att
; INPUTS:
;        att = att structure 
;              The input is replaced by the corrected att structure.
; KEYWORDS (INPUT):
; OUTPUTS:
;        att = att structure with corrected att.pnt values.
; KEYWORDS (OUTPUT):
; COMMON BLOCKS:
;        None.
; SIDE EFFECTS:
;
; PROCEDURE:
;    The following corrections are made by this routine.
;    Algorithm = 0:
;     Old ATT data (created before 21-sep-94) used an erroneous
;     mission correction for data after 1-jan-93.  The offset is
;     in the N-S direction and grew from less than 1" to more than 15"
;     in September 1994.
;
; MODIFICATION HISTORY:
;        19-sep-94 (JPW)
;        22-sep-94 (SLF) - check ATT 'algorithm' (3 LSB in ATT.STATUS2)
;                          ATT algorithm check and set correction 'history' bit
;        24-mar-95 (SLF) - eliminate status message
;        13-jan-98 (JPW) - add updated mission correction
;        25-sep-98 (JPW) - apply updated (jan-98) mission correction
;                          to version le 3 (was "le 2")
;                    
;-

pro fix_old_att,att

; ---------- verify input is ATT structure ---------------
errmess="Input must be an ATT structure..."
if not data_chk(att,/struct) then mess=errmess else $
   if tag_index(att,'status2') eq -1 then mess=errmess
if n_elements(mess) eq 1 then begin
   tbeep
   message,mess,/info
   return
endif
; ----------------------------------------------------------

aday = gt_day(att)			; used for time dependent corrections


; -------- Mask status2 3LSB for ATT algorithm ----------------
; Bit Pattern for STATUS2
;    b7:4 (not checked by this routine)
;    b3   (Correction Applied - if set, NOP by this routine)
;    b2:0 (Correction Algorithm)
algorithm=att.status2 and 7b
applied=(att.status2 and 8b) ne 0	; only correct if bit not set
; -------------------------------------------------------------

; --------------------- Algorithm 0 fix ------------------------
alg0=where( (algorithm eq 0) and 		$  ; Algorithm 0
            (aday ge gt_day('1-jan-93')) and 	$  ; only data after...
	    (1-applied) ,a0cnt)			   ; dont re-apply correction

if a0cnt gt 0 then begin
   ;old (erroneous) mission correction parameters from old hxa_parms program.
   ;only remove the correction in y, the x-correction is ok.
   cmy = [-8.57,+1.889e-2,-1.024e-5]   ; as of Sept. 1992
   tmoff = 4000                        ; day offset for mission time corr. (days)

   ;new correction for dates after 1-jan-93 (constant with time)
   cy_n = -0.24

   ; calculate the old correction
   t_day = float(aday(alg0) - tmoff)     ; time for secular variations
   ycor = cmy(0) + cmy(1)*t_day + cmy(2)*t_day*t_day

   ; subtract the new correction
   ycor = ycor - cy_n

   ; apply correction (only in y, the x-correction is ok and should be kept)
   att(alg0).pnt(1) = att(alg0).pnt(1) - long(ycor*100.0)

   ; set correction applied bit to avoid re-applying
   ; don't set here, but only after 2nd correction (below)
   ;att(alg0).status2 = att(alg0).status2 or 8b
endif
; ------------------ end of Algorithm 0 fix --------------------------

; ------------------ All Algorithms : updated mission correction -------
;alg0=where( (algorithm le 3) and	$ ; Algorithm 0
;	    (1-applied) ,a0cnt)		  ; dont re-apply correction
alg0=where( (1-applied) ,a0cnt)		  ; Correction now applied
					  ;   to all algorithms 

if a0cnt gt 0 then begin
   ;add the 1998 mission correction update.
   ;correction only in y, the x value is ok.
   tmoff = 4000                     ; day offset for mission time corr. (days)
   tmcut = 6895                     ; use constant corr. after that day
   cmy = [+0.301, -0.335, +0.970, +0.088, +0.043, $
          +0.242, +0.046, -0.074, -0.253, +0.045, $
          -0.080, -0.114, +0.112, -0.225, +0.034]

   ; calculate the new correction
   ; for times after tmcut use the correction at tmcut:
   t_day = float((aday(alg0) < tmcut) - tmoff)   ; time for secular variations
   m2=fix(n_elements(cmy))/2
   c2=2.0*!pi/(365.2422*m2)
   ycor = fltarr(a0cnt) + cmy(0)
   for i=1,m2 do ycor = ycor + cmy(i*2-1) * sin(c2*i*t_day)
   for i=1,m2 do ycor = ycor + cmy(i*2) * cos(c2*i*t_day)

   ; apply correction (only in y, the x-value is ok)
   att(alg0).pnt(1) = att(alg0).pnt(1) + long(ycor*100.0)

   ; set correction applied bit to avoid re-applying
   att(alg0).status2 = att(alg0).status2 or 8b
endif
; ------------------ end of Algorithm le 3 update --------------------------

return
end
