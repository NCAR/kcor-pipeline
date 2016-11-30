; docformat = 'rst'

;+
; :Params:
;   data
;   metadata
;   pixel
;   beam
;   parinfo : out, optional, type=array of structures
;     array of 17 structures with value, fixed, limited, and limits fields
;   functargs : out, optional, type=structure
;     structure with data, angles, pixel, and beam fields
;-
pro kcor_reduce_calibration_setup_lm, data, metadata, pixel, beam, parinfo, functargs
  common kcor_random, seed

  ; this procedure creates the parinfo and functargs structs for mpfit

  ; 17 parameters go into the model, but 8 are fixed, so there are 9 free parameters
  parinfo = replicate({value:0d, fixed:0, limited:[0, 0], limits:[0D, 0]}, 17)

  parinfo[0].value = metadata.idiff         ; I is normalized to metadata.idiff
  parinfo[1:4].value = [1, 1, 1, 1]         ; initial guess for I modulation
  parinfo[5:8].value = [1, 1, 1, 1] * 0.94  ; initial guess for Q&U modulation amplitude
  ;parinfo[9:12].value = randomu(seed,4)*2*!dpi ; random Q&U phase
  if beam eq 0 then $
      parinfo[9:12].value = [!pi, 3 * !pi / 2, !pi / 2, 0] ; this should be really close
  if beam eq 1 then $
      parinfo[9:12].value = [0, !pi / 2, 3 * !pi / 2, !pi] ; this should be really close
  parinfo[13].value = data.dark[pixel.x, pixel.y,beam]           ; dark current
  parinfo[14].value = data.gain[pixel.x, pixel.y,beam]           ; gain
  parinfo[15].value = [0.9]       ; initial guess for cal pol transmission
  parinfo[16].value = 0.999       ; +- 0.003 angle fudge factor, empirically established

  parinfo[0].fixed = 1                     ; I is fixed at the known diffuser intensity
  parinfo[1:4].fixed = 1                   ; fix the (0,*) elements
  parinfo[5:8].limited = [1, 1]            ; modulation matrix amplitude for Q&U is limited
  parinfo[5:8].limits = [0.5, 1.0]         ; between 0.5 and 1
  parinfo[9:12].limited = [1, 1]           ; modulation matrix angle for Q&U is limited
  parinfo[9:12].limits = [-1, 3] * !dpi    ; angle
  parinfo[13].fixed = 1                    ; dark current is deterministic
  parinfo[14].fixed = 1 ; gain is deterministic and degenerate with polarizer transmission
  parinfo[15].limited = [1, 1] ; polarizer transmission is between 0 and 1
  parinfo[15].limits = [0, 1.]
  parinfo[16].fixed = 1 ; angle fudge factor is empirically determined and fixed

  cal = reform(data.calibration[pixel.x, pixel.y, *, beam, *])

  functargs = {data:cal, angles:metadata.angles, pixel:pixel, beam:beam}
end
