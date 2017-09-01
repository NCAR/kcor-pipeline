;+
; Project     :	MLSO - KCOR
;
; Name        :	KCOR_CME_DET_FIND
;
; Purpose     :	Check whether position angles persist with time
;
; Category    :	KCOR, CME, Detection
;
; Explanation :	The second step in the CME detection process, this routine
;               checks whether or not the position angles found in
;               KCOR_CME_DET_THRESH persist in time.
;
; Syntax      :	KCOR_CME_DET_FIND, TAI_AVG, DATE_DIFF, ITHETA0, NLON, DETECTED
;
; Examples    :	See KCOR_CME_DET_EVENT
;
; Inputs      :	TAI_AVG = TAI midpoint value for current image
;               DATE_DIFF= Structure containing date/time information for the
;                          running difference images collected so far.
;               ITHETA0 = Position angle range for current image
;               ITHETA  = Collected position angle ranges
;               NLON    = Size of position angle dimension in maps
;               DETECTED= Array of detection flags
;
; Opt. Inputs :	None
;
; Outputs     :	DETECTED array is updated if persistence is satisfied
;
; Opt. Outputs:	None
;
; Keywords    :	None
;
; Calls       :	BOOST_ARRAY, AVERAGE
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
pro kcor_cme_det_find, tai_avg, date_diff, itheta0, itheta, nlon, detected
  compile_opt strictarr

  ; calculate the time differences from the current image
  tai = date_diff.tai_avg
  tdelta = tai_avg - tai

  ; If the previous image was a detection, then define the persistence parameter
  ; to be five minutes (plus some margin). Otherwise, set the persistence to
  ; two minutes.
  idet = n_elements(detected) - 1
  if (detected[idet - 1]) then tmax = 303 else tmax = 123

  ; Find all images within the persistence period.
  wdate = where((tdelta gt 0) and (tdelta le tmax), ntai)

  ; Look within the persistence period for regions overlapping with the current
  ; region.
  if (ntai gt 1) then begin
    found = bytarr(ntai)
    for itai = 0,ntai-1 do begin
      jdate = wdate[itai]
      i0 = itheta0[0]
      i1 = itheta0[1]
      if i1 lt i0 then i1 = i1 + nlon
      j0 = itheta[0,jdate]
      j1 = itheta[1,jdate]
      if j1 lt j0 then j1 = j1 + nlon

      ; Mark any images which overlap.  Use the value 2 to mark cases which are more
      ; than 30 seconds earlier, since these images are completely independent from
      ; the current image.
      if (i1 ge j0) and (i0 le j1) then begin
        boost_array, joverlap, jdate
        if tdelta[jdate] gt 30 then found[itai] = 2 else found[itai] = 1
      endif
    endfor

    ; Check that at least one of the overlapping regions is at least 30 seconds
    ; old, and that most of the images within the persistence period overlap.
    w = where(found eq 2, count)
    if (average(found < 1) gt 0.5) and (count gt 0) then begin
      detected[idet] = 1

      ; Mark earlier images within the persistence period as detections, so long
      ; as they overlap.
      for i = n_elements(joverlap)-1,0,-1 do begin
        j = joverlap[i]
        if (detected[j + 1]) then detected[j] = 1 else break
      endfor
    endif
  endif
end
