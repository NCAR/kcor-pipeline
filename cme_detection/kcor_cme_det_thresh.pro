;+
; Project     :	MLSO - KCOR
;
; Name        :	KCOR_CME_DET_THRESH
;
; Purpose     :	Find position angles which exceed threshold
;
; Category    :	KCOR, CME, Detection
;
; Explanation :	The first step in the CME detection process, this routine looks
;               for longitude ranges which may contain a CME.  The absolute
;               value of the map is first collapsed in radius.  A threshold
;               process is used to find a candidate CME, and then a second
;               threshold process is used to grow the angular range.
;
; Syntax      :	KCOR_CME_DET_THRESH, MDIFF, ITHETA
;
; Examples    :	See KCOR_CME_DET_EVENT
;
; Inputs      :	MDIFF   = Running difference polar map
;
; Opt. Inputs :	None
;
; Outputs     :	ITHETA  = Two element array containing the angular range.
;
; Opt. Outputs:	None
;
; Keywords    :	None
;
; Calls       :	AVERAGE, STDDEV
;
; Common      :	None
;
; Restrictions:	None
;
; Side effects:	None
;
; Prev. Hist. :	Partially based on SEEDS algorithm, Olmedo et al., 2008, Solar
;               Physics 248, 485-499.
;
; History     :	Version 1, 05-Jan-2017, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;
pro kcor_cme_det_thresh, mdiff, itheta
  ; Initialize parameters.  Collapse the map along the radial direction.
  y = average(abs(mdiff), 2)
  found = 0 * y
  ntheta = n_elements(y)
  itheta = replicate(-1, 2)

  ; Define the threshold values.
  thresh1 = 3.5
  thresh2 = 2.0

  ; Apply the first threshold to find the candidate CME.
  yavg1 = average(y)
  ysig1 = stddev(y)
  t1 = yavg1 + thresh1 * ysig1
  w1 = where(y ge t1, count)

  ; If a candidate CME has been found, then find the limits within the first
  ; threshold.
  if (count gt 0) then begin
    w0 = (where(y eq max(y)))[0]
    ii = w0
    repeat begin
      found[ii] = 1
      i0 = ii
      ii = i0 - 1
      if (ii lt 0) then ii = ntheta - 1
    endrep until (y[ii] lt t1)
    ii = w0
    repeat begin
      found[ii] = 1
      i1 = ii
      ii = i1 + 1
      if (ii eq ntheta) then ii = 0
    endrep until (y[ii] lt t1)

    ; Apply the second threshold to grow the CME range.
    w = where(found eq 0)
    yavg2 = average(y[w])
    ysig2 = stddev(y[w])
    t2 = yavg2 + thresh2 * ysig2
    ii = i0
    repeat begin
        found[ii] >= 0.5
        i0 = ii
        ii = i0 - 1
        if (ii lt 0) then ii = ntheta - 1
      endrep until (y[ii] lt t2)
    ii = i1
    repeat begin
      found[ii] >= 0.5
      i1 = ii
      ii = i1 + 1
      if (ii eq ntheta) then ii = 0
    endrep until (y[ii] lt t2)

    itheta = [i0, i1]
  endif
end
