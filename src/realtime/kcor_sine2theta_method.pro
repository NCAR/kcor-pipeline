; docformat = 'rst'

pro kcor_sine2theta_method, corona_plus_sky, sky_polarization, intensity, $
                            radsun, theta1, rr1, $
                            q_new=q_new, u_new=u_new, run=run
  compile_opt strictarr

  xsize = 1024L
  ysize = 1024L

  r_init = 1.8
  rnum   = 11

  radscan    = fltarr(rnum)
  amplitude1 = fltarr(rnum)
  phase1     = fltarr(rnum)

  numdeg  = 90
  stepdeg = 360 / numdeg
  degrees = findgen(numdeg) * stepdeg + 0.5 * stepdeg
  degrees = double(degrees) / !radeg

  case run->config('realtime/sine2theta_nparams') of
    2: begin
        a = dblarr(2)
        a[0] = 0.0033
        a[1] = 0.14

        fit_routine = 'kcor_sine2theta_2param'
      end
    8: begin
        a = dblarr(8)
        a[0] = 0.0033   ; amplitude of sine 2 theta
        a[1] = 1.       ; distance of sun from center of occulter
        a[2] = 250.     ; radius to observer
        a[3] = 90.      ; delta angle from angle of occulter to observer
        a[4] = 0.14     ; sine 2theta phase
        a[5] = -0.1     ; offset from zero
        a[6] = 0.001    ; amplitude of sine theta term
        a[7] = 0.       ; phase angle of sine theta term

        fit_routine = 'kcor_sine2theta_8param'
      end
    else: begin
        mg_log, 'invalid number of parameters for sine2theta fit: %d', $
                run->config('realtime/sine2theta_nparams'), name='kcor/rt', /error
      end
  endcase

  weights     = fltarr(numdeg) + 1.0
  angle_ave_u = dblarr(numdeg)
  angle_ave_q = dblarr(numdeg)

  ; radius loop
  
  ; debugging plots
  skyplot = 0
  doplot = 0

  for ii = 0, rnum - 1 do begin
    angle_ave_u[*] = 0.0D
    angle_ave_q[*] = 0.0D

    ; use solar radius: radsun = radius in arcsec
    radstep = 0.10
    r_in    = r_init + ii * radstep
    r_out   = r_init + ii * radstep + radstep
    radius_beg = r_in
    radius_end = r_out

    r_in  *= radsun / run->epoch('plate_scale')
    r_out *= radsun / run->epoch('plate_scale')
    radscan[ii] = (r_in + r_out) / 2.0

    ; extract annulus and average all heights at 'stepdeg' increments around
    ; the sun

    ; make new theta arrays in degrees
    theta1_deg = theta1 * !radeg

    ; define U/I and Q/I
    corona_plus_sky_int = corona_plus_sky / intensity
    sky_polarization_int = sky_polarization / intensity

    j = 0
    for i = 0, 360 - stepdeg, stepdeg do begin
      angle = float(i)
      pick1 = where(rr1 ge r_in and rr1 le r_out $
                      and theta1_deg ge angle $
                      and theta1_deg lt angle + stepdeg, nnl1)
      if (nnl1 gt 0) then begin
        angle_ave_u[j] = mean(corona_plus_sky_int[pick1])
        angle_ave_q[j] = mean(sky_polarization_int[pick1])
      endif
      j += 1
    endfor

    sky_polar_cam1 = curvefit(degrees, double(angle_ave_u), weights, a, $
                              function_name=fit_routine)

    amplitude1[ii] = a[0]
    phase1[ii]     = a[1]
    mini = -0.15
    maxi =  0.15

    if (skyplot eq 1) then begin
      !p.multi    = [0, 2, 2]

      loadct, 39

      plot,  degrees  *!radeg,  angle_ave_u, thick=2, title='U', $
             ystyle=1, charsize=1.5
      oplot, degrees * !radeg, sky_polar_cam1, color=100, thick=5
      oplot, degrees * !radeg, $
             a[0] * run->epoch('skypol_factor') * sin(2.0 * degrees + a[1]), $
             lines=2,thick=5, color=50

      wait, 1

      plot,  degrees * !radeg, angle_ave_q, thick=2, title='Q', $
             ystyle=1, charsize=1.5
      oplot, degrees * !radeg, $
             a[0] * sin(2.0 * degrees + 90.0 / !radeg + a[1]), $
             color=100, thick=5
      oplot, degrees * !radeg, $
             a[0] * run->epoch('skypol_factor') * sin(2.0 * degrees + 90.0 / !radeg + a[1]) + run->epoch('skypol_bias'), $
             linestyle=2, color=50, thick=5

      wait, 0.4
      loadct, 0
      !p.multi = 0
      pause
    endif
  endfor

  mean_phase1 = mean(phase1)

  ; force the fit to be a straight line
  afit_amplitude    = poly_fit(radscan, amplitude1, 1, afit)
  radial_amplitude1 = interpol(afit, radscan, rr1, /quadratic)

  if (doplot eq 1) then begin
    plot, rr1[*, 500] * run->epoch('plate_scale') / radsun, radial_amplitude1[*, 500], $
          xtitle='distance (solar radii)', $
          ytitle='amplitude', title='CAMERA 1'
    oplot, radscan * epoch->epoch('platescale') / (radsun), amplitude1, psym=2
    wait, 1
  endif

  radial_amplitude1 = reform(radial_amplitude1, xsize, ysize)

  if (doplot eq 1) then begin
    tvscl, radial_amplitude1
    wait, 1
  endif

  sky_polar_u1 = radial_amplitude1 * sin(2.0 * theta1 + mean_phase1)
  sky_polar_q1 = radial_amplitude1 * sin(2.0 * theta1 + 90.0 / !radeg $
                                           + mean_phase1) + run->epoch('skypol_bias')

  q_new = sky_polarization - run->epoch('skypol_factor') * sky_polar_q1 * intensity
  u_new = corona_plus_sky - run->epoch('skypol_factor') * sky_polar_u1 * intensity

  ;cfts_file = strmid(l0_file, 0, 20) + '_sky_polarization_skypolcor.fts'
  ;writefits, cfts_file, q_new
  ;cfts_file = strmid(l0_file, 0, 20) + '_corona_plus_sky_skypolcor.fts'
  ;writefits, cfts_file, u_new

  if (doplot eq 1) then begin
    tv, bytscl(sky_polarization_new, -1, 1)
    draw_circle, xcc1, ycc1, radius_1, thick=4, color=0,  /dev

    for i  = 0, rnum - 1 do draw_circle, xcc1, ycc1, radscan[i], /device
    for ii = 0, numdeg - 1 do begin
      plots, [xcc1, xcc1 + 500 * cos(degrees[ii])], $
             [ycc1, ycc1 + 500 * sin(degrees[ii])], $
             /device
      pause
      wait, 1
    endfor
  endif
end
