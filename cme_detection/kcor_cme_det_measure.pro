;+
; Project     :	MLSO - KCOR
;
; Name        :	KCOR_CME_DET_MEASURE
;
; Purpose     :	Measure the CME velocity
;
; Category    :	KCOR, CME, Detection
;
; Explanation :	The fourth step in the CME detection process, this routine
;               looks for evidence of upward motion in the most recent leading
;               edge measurements.  If the criteria is met, then a CME alert is
;               generated.
;
; Syntax      :	KCOR_CME_DET_MEASURE, RSUN
;
; Examples    :	See KCOR_CME_DET_EVENT
;
; Inputs      :	RSUN    = Solar radii in arcminutes
;
; Opt. Inputs :	None
;
; Outputs     :	None
;
; Opt. Outputs:	None
;
; Keywords    :	None
;
; Calls       :	GOOD_PIXELS, POLY_FIT_MOST, WCS_RSUN, KCOR_CME_DET_ALERT
;
; Common      :	KCOR_CME_DETECTION defined in kcor_cme_detection.pro
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
pro kcor_cme_det_measure, rsun
;
common kcor_cme_detection
;
;  Find all the detections within the last five minutes.
;
itime = n_elements(leadingedge) - 1
tai0 = date_diff[itime].tai_avg
w = where(((tai0-date_diff.tai_avg) le 303) and (leadingedge ge 0), count)
;
;  Step backwards in time, and confirm that the position angles overlap,
;  allowing the detection region to grow.
;
i0 = itheta[0,itime]
i1 = itheta[1,itime]
if i1 lt i0 then i1 = i1 + nlon
w = reverse(w)
for i=0,n_elements(w)-1 do begin
    j0 = itheta[0,w[i]]
    j1 = itheta[1,w[i]]
    if j1 lt j0 then j1 = j1 + nlon
    if (i1 ge j0) and (i0 le j1) then begin
        i0 = i0 < j0
        i1 = i1 > j1
    end else w[i] = -1
endfor
;
;  Filter out the non-overlapping regions.
;
w = good_pixels(w, missing=-1)
;
;  Perform a linear fit to the data.
;
if n_elements(w) ge 5 then begin
    x = date_diff[w].tai_avg - tai0
    y = 60 * (lat[leadingedge[w]] + 90) / rsun
    param0 = poly_fit_most(x, y, 1, yfit, used=used)
    speed0 = param0[1] * wcs_rsun(unit='km')
;
;  Determine the size of the largest gap in the used data, and the standard
;  deviation.
;
    xused = x[used]
    nused = n_elements(used)
    dxmax = max(abs(xused[1:*]-xused))
    xrange = max(xused, min=xmin) - xmin
    ysig = stddev((y-yfit)[used])
    nthresh = ((n_elements(w)/2) + 1) > 5
;
;  If most of the points (at least five) were used in the fit, the slope is
;  sufficiently positive, the time range covers at least two minutes, there are
;  no gaps larger than two minutes, and the standard deviation is small enough,
;  then calculate the output parameters.
;
    if (n_elements(used) ge nthresh) and (speed0 gt 20) and (dxmax le 120) and $
      (xrange ge 120) and (ysig lt 0.05) then begin
        iavg = (i0 + i1) / 2.
        if iavg ge nlon then iavg = iavg - nlon
        alert = 0
        angle0 = interpol(lon, indgen(n_elements(lon)), iavg)
        if n_elements(angle) eq 0 then alert = 1 else begin
            delta = abs(angle - angle0)
            if (delta gt 180) then delta = 360 - delta
            if delta gt 20 then alert = 1
        endelse
        angle = angle0
;
        param = param0
        speed = speed0
;
        if n_elements(tairef) eq 0 then alert = 1 else $
          if (tai0-tairef) gt 3600 then alert = 1
        tairef = tai0
;
;  If this is a new CME, then generate an alert.
;
        if alert then kcor_cme_det_alert, itime, rsun
    endif
endif
;
end
