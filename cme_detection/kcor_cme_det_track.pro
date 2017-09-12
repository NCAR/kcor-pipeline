;+
; Project     :	MLSO - KCOR
;
; Name        :	KCOR_CME_DET_TRACK
;
; Purpose     :	Look for CME leading edge
;
; Category    :	KCOR, CME, Detection
;
; Explanation :	The third step in the CME detection process, this routine looks
;               for the CME leading edge.  Will also fill in earlier time steps
;               once a tentative detection is made in KCOR_CME_DET_FIND.
;
; Syntax      :	KCOR_CME_DET_TRACK, MDIFFS, ITHETA, DETECTED, LEADINGEDGE
;
; Examples    :	See KCOR_CME_DET_EVENT
;
; Inputs      :	MDIFFS  = Array of difference maps collected so far
;               ITHETA  = Collected position angle ranges
;               DETECTED= Array of detection flags
;               LEADINGEDGE = Array of leading edge heights in pixels
;
; Opt. Inputs :	None
;
; Outputs     :	LEADINGEDGE is updated with the added heights
;
; Opt. Outputs:	None
;
; Keywords    :	None
;
; Calls       :	BOOST_ARRAY, AVERAGE, ASMOOTH
;
; Common      :	None
;
; Restrictions:	None
;
; Side effects:	None
;
; Prev. Hist. :	None
;
; History     :	Version 1, 05-Jan-2017, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;
pro kcor_cme_det_track, mdiffs, itheta, detected, leadingedge
  compile_opt strictarr

  ; initialize parameters
  thresh = 2.0
  npix = 3

  ; Step through the elements in DETECTED which do not yet appear in
  ; LEADINGEDGE. Increment LEADINGEDGE to catch up with DETECTED.
  for itime = n_elements(leadingedge), n_elements(detected) - 1 do begin
    boost_array, leadingedge, -1.0

    ; If a detection was made, and the ITHETA values are valid, then look for
    ; the leading edge.  Average over longitude between the ITHETA values,
    ; taking into account that the region may wrap around.
    if (detected[itime] gt 0) and (itheta[0, itime] ge 0) then begin
      map = mdiffs[*, *, itime] > 0
      i0 = itheta[0, itime]
      i1 = itheta[1, itime]
      if (i1 ge i0) then begin
        y = average(map[i0:i1, *], 1)
      endif else begin
        y = average(map[0:i1, *], 1) + average(map[i0:*, *], 1)
      endelse

      ; Smooth the trace by five pixels, and calculate the derivative over six
      ; pixels, which is also smoothed.
      ys = asmooth(y, 5)
      yd = asmooth(ys[2*npix:*] - ys, 5)

      ; Look for the outermost point which satisfies the threshold in the upward
      ; direction. This is interpreted as the trailing edge.
      ydthresh = average(yd) + thresh * stddev(yd)
      itrail = max(where(yd ge ydthresh, count))

      ; Recalculate the threshold from the trailing edge onward to look for the
      ; leading edge as a downward slope.  The actual position is offset by NPIX
      ; pixels, because of the way the derivative was calculated.
      if (count gt 0) then begin
        yyd = yd[itrail:*]
        ydthresh = average(yyd) - thresh * stddev(yyd)
        ilead = min(where(yyd le ydthresh, count))
        if (count gt 0) then begin
          leadingedge[itime] = npix + itrail + ilead
          sz = size(mdiffs)
        endif
      endif
    endif
  endfor
end
