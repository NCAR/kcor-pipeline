;+
; Project     :	MLSO - KCOR
;
; Name        :	KCOR_CME_DET_RDIFF
;
; Purpose     :	Generate running difference images
;
; Category    :	KCOR, CME, Detection
;
; Explanation :	This routine takes the polar maps generated from the original
;               FITS files and generates running difference images.  Images
;               over the last 30 seconds are averaged together, and compared
;               against the same from five minutes earlier.
;
; Syntax      :	KCOR_CME_DET_RDIFF, HMAP, MAPS, DATE_ORIG, OUTFILE, HDIFF, MDIFF
;
; Examples    :	See KCOR_CME_DET_EVENT
;
; Inputs      :	HMAP    = FITS header pertaining to the current map.
;               MAPS    = Array containing all the maps read in so far
;               DATE_ORIG = Structure containing date/time information for MAPS
;               OUTFILE = Output filename.  The file is only written if the
;                         keyword STORE is set.
;
; Opt. Inputs :	None
;
; Outputs     :	HDIFF   = FITS header for difference map
;               MDIFF   = Difference map
;
; Opt. Outputs:	None
;
; Keywords    :	STORE   = If set, then the difference map is written to disk.
;
; Calls       :	FILE_EXIST, FXREAD, FXPAR, AVERAGE, FXHMAKE, FXADDPAR, TAI2UTC,
;               FXWRITE
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
pro kcor_cme_det_rdiff, hmap, maps, date_orig, outfile, hdiff, mdiff, $
                        store=store

  ; If the output file already exists, then simply read it in.
  if (file_exist(outfile)) then fxread, outfile, mdiff, hdiff else begin
    ; Convert the times into TAI seconds.
    tai_obs = date_orig.tai_obs
    tai_end = date_orig.tai_end
    tai0 = utc2tai(fxpar(hmap, 'date-obs'))

    ; Find the images within 30 seconds of the target time, plus some margin. Do
    ; the same for a background image five minutes earlier.
    dtime = tai0 - tai_obs
    w1 = where((dtime ge 0) and (dtime le 33), count1)
    w2 = where((dtime ge 297) and (dtime le 333), count2)

    ; If one of the other wasn't found, then simply return -1 for the
    ; difference map.
    if ((count1 eq 0) or (count2 eq 0)) then mdiff = -1.0D else begin
      ; Otherwise, form the running difference image.
      if (count1 eq 1) then map1 = maps[*, *, w1] else begin
        map1 = average(maps[*,*,w1], 3)
      endelse
      if (count2 eq 1) then map2 = maps[*, *, w2] else begin
        map2 = average(maps[*,*,w2], 3)
      endelse
      mdiff = map1 - map2

      ; Update the header information.
      hdiff = hmap
      fxhmake, hdiff, mdiff
      fxaddpar, hdiff, 'date-obs', min(date_orig[w1].date_obs)
      fxaddpar, hdiff, 'date-end', max(date_orig[w1].date_end)
      tai_avg = average((tai_obs[w1] + tai_end[w1]) / 2)
      utc_avg = tai2utc(tai_avg, /ccsds)
      fxaddpar, hdiff, 'date-avg', utc_avg, $
                'UTC observation average date/time'

      ; Write the output file.
      if keyword_set(store) then fxwrite, outfile, hdiff, mdiff
    endelse
  endelse
end
