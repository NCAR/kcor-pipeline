;+
;-------------------------------------------------------------------------------
; :AUTHOR: Alfred de Wijn
;
; :PURPOSE: Compute kcor calibration files: dark, gain, mmat, dmat.
;
; syntax: kcor_calgen, fits_list, ncdf_file
;
;   fits_list: file containing a list of kcor calibration files [FITS format].
;   ncdf_file: name of output ncdf file.
;-------------------------------------------------------------------------------
; High Altitude Observatory / National Center for Atmospheric Research
;
; This is the same procedure as "kcor_reduce_calibration.pro".
;
; 27 May 2015 [ALS] Cosmetic changes only: spaces, blank lines, comments.
;-------------------------------------------------------------------------------
;-

PRO kcor_calgen, fits_list, outfile

common kcor_random, seed

writeu, -1, 'Reading data... '		; Writes to stdout.

;---------------
; Read the data.
;---------------

nlines = FILE_LINES (fits_list)
file_list = strarr (nlines)
openr, FLUN, fits_list, /GET_LUN
readf, FLUN, file_list
free_lun, FLUN

kcor_reduce_calibration_read_data, file_list, data, metadata
sz = size (data.gain, /dimensions)
print, 'done.'

;-------------------
; Modulation matrix.
;-------------------

mmat = fltarr (sz [0], sz [1], 2, 3, 4)
dmat = fltarr (sz [0], sz [1], 2, 4, 3)

;-------------------------------
; Number of points in the field.
;-------------------------------

npick = 10000

;--------------------------
; Fit the calibration data.
;--------------------------

for beam = 0, 1 do $
begin ;{
  print, strcompress (string ('Processing beam ', beam, '.'))
  writeu, -1, '  Fitting model to data... '

  ;--------------------------------
  ; Pick a pixels with good signal.
  ;--------------------------------

  w = where (data.gain[*, *, beam] ge median (data.gain[*, *, beam]) / sqrt(2),$
             nw)
  if (nw lt npick) then $
    message, "Didn't find enough pixels with signal. Something's wrong."
  npicked = 0
  pick = [0l]

  repeat begin
    pick = [pick, long (randomu (seed, npick-npicked+1)*nw)]
    pick = (pick[uniq (pick, sort(pick))])
    npicked = n_elements (pick)
  endrep until npicked gt npick

  pixels = array_indices (data.gain [*, *, beam], w [pick [1:npick]])

  fits = dblarr (18, npick)
  fiterrors = dblarr (18, npick)

  for i = 0, npick - 1 do $
  begin ;{

    ;--------------
    ; Setup the LM.
    ;--------------

    pixel = { x : pixels [0, i], y : pixels [1, i] }
    kcor_reduce_calibration_setup_lm, data, metadata, pixel, beam, parinfo, $
                                      functargs

    ;----------------------
    ; Run the minimization.
    ;----------------------

    fits [*, i] = mpfit ('kcor_reduce_calibration_model', parinfo=parinfo, $
                         functargs=functargs, status=status, errmsg=errmsg, $
                         niter=niter, npegged=npegged, perror=fiterror, /quiet)
                         fiterrors [*, i] = fiterror

    if (status le 0) then $
    begin
      message, 'MPFit exited with an error: ' + errmsg
    endif

    if (i ne 0 and i mod (npick / 10) eq 0) then $
      writeu, -1, strcompress (string (100l * i / npick) + '%', /remove_all), $
                  ' '

  endfor ;}

  ;-------------------------------------------------------------------------
  ; Parameters 8-12 may have gone to equivalent solutions due to periodicity
  ; of the parameter space. We have to remove the ambiguity.
  ;-------------------------------------------------------------------------

  for i = 9, 12 do $
  begin ;{

    ;--------------------------------------------------------
    ; Guarantee the values are between -2*pi and +2*pi first.
    ;--------------------------------------------------------

    fits [i, *] = fits [i, *] mod 2 * !pi

    ;------------------------------------------
    ; Find approximately the most likely value.
    ;------------------------------------------

    h = histogram (fits[i, *], locations=l, binsize=0.1*!pi)
    mlv = l [ ( where (h eq max (h)) ) [0]]

    ;------------------------------------
    ; Center the interval around the mlv.
    ;------------------------------------

    fits [i, *] = fits [i, *] + (fix (fits [i, *] lt (mlv - !pi)) $
                              -  fix (fits [i, *] gt (mlv + !pi))) * 2 * !pi
  endfor ;}
  print, 'done: parameters 8-12 .'

  writeu, -1, '  Fitting 4th order polynomials... '

  ;----------------------------------------------------------------------
  ; 4th order polynomial fits for all parameters.
  ; Set up some things.
  ; Center the pixel values in the image for better numerical stability.
  ;----------------------------------------------------------------------

  cpixels = pixels - rebin([sz[0], sz[1]]/2., 2, npick)
  x = (findgen(sz[0]) - sz[0]/2.) # replicate(1., sz[1]) ;X values at each point
  y = replicate(1., sz[1]) # (findgen(sz[1]) - sz[1]/2.) ;Y values at each point

  ;----------------------------------
  ; Pre-compute the x^i y^j matrices.
  ;----------------------------------

  degree = 4
  n2 = (degree + 1) * ((degree + 2) / 2)
  m = sz [0] * sz [1]
  ut = dblarr (n2, m, /nozero)
  j0 = 0L

  for i = 0, degree do $
  begin ;{
    for j = 0, degree - i do $
      ut [j0 + j, 0] = reform (x^i * y^j, 1, m)
    j0 += degree - i + 1
  endfor ;}

  ;-----------------------
  ; Create the fit images.
  ;-----------------------

  fitimgs = fltarr (sz [0], sz [1], 12)

  for i = 1, 12 do $
  begin ;{
    tmp = sfit ([cpixels, fits [i, *]], degree, kx=kx, /irregular, /max_degree)
    fitimgs [*, *, i-1] = reform (reform (kx, n2) # ut, sz [0], sz [1])
  endfor ;}
  print, 'done: sfit.'

  writeu, -1, '  Calculating modulation and demodulation matrices... '

  ;-------------------------------
  ; Populate the modulation matrix.
  ;-------------------------------

  mmat [*, *, beam, 0, *] = fitimgs [*, *, 0:3]
  mmat [*, *, beam, 1, *] = fitimgs [*, *, 0:3] $
                          * fitimgs [*, *, 4:7] * sin (fitimgs [*, *, 8:11])
  mmat [*, *, beam, 2, *] = fitimgs [*, *, 0:3] $
                          * fitimgs [*, *, 4:7] * cos (fitimgs [*, *, 8:11])

  ;----------------------------------
  ; Populate the demodulation matrix.
  ;----------------------------------

  for x = 0, sz [0] - 1 do for y = 0, sz [1] - 1 do $
  begin ;{
    xymmat = reform (mmat [x, y, beam, *, *])
    txymmat = transpose (xymmat)
    dmat [x, y, beam, *, *] = la_invert (txymmat ## xymmat) ## txymmat
  endfor ;}
  print, 'done: populate demod matrix.'

endfor ;}  End beam loop.

writeu, -1, 'Writing output... '

;----------------------------
; Write the calibration data.
;----------------------------

kcor_reduce_calibration_write_data, data, metadata, pixels, fits, $
                                    fiterrors, mmat, dmat, outfile
print, 'done: write data.'
END
