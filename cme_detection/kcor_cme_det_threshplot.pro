; docformat = 'rst'

;+
; Make a plot for finding t1 and t2 thresholds.
;-
pro kcor_cme_det_threshplot, mdiff, itheta0
  compile_opt strictarr
  @kcor_cme_det_common

  y = average(abs(mdiff), 2)
  found = 0 * y
  ntheta = n_elements(y)

  ; Define the threshold values.
  thresh1 = 3.5
  thresh2 = 2.0

  ; Apply the first threshold to find the candidate CME.
  yavg1 = average(y)
  ysig1 = stddev(y)
  t1 = yavg1 + thresh1 * ysig1
  w1 = where(y ge t1, count)

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
  endif

  mg_psbegin, filename='20170327.alertthreshplot.ps', $
              xsize=6, ysize=3, /inches, bits_per_pixel=8, /color

  device, get_decomposed=odec
  device, decomposed=1

  plot, lon, y, $
        title='Collapse HPR diff map along radial direction', $
        xstyle=1, xtitle='Position angle (degrees)', $
        ytitle='Difference in pB', $
        yticks=4, $
        color='000000'x, background='ffffff'x, $
        font=1

  plots, !x.crange, fltarr(2) + t1, color='a0a0a0'x, linestyle=2
  plots, !x.crange, fltarr(2) + t2, color='a0a0a0'x, linestyle=2

  plots, fltarr(2) + itheta0[0], !y.crange, color='0000ff'x
  plots, fltarr(2) + itheta0[1], !y.crange, color='0000ff'x

  device, decomposed=odec

  mg_psend
end
