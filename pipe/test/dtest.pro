pro dtest, date_obs

   print, 'date_obs: ', date_obs

   oyear  = strmid (date_obs,  0, 4)
   omon   = strmid (date_obs,  5, 2)
   oday   = strmid (date_obs,  8, 2)
   ohour  = strmid (date_obs, 11, 2)
   omin   = strmid (date_obs, 14, 2)
   osec   = strmid (date_obs, 17, 2)

   print, 'oyear, omin, oday: ', oyear, omin, oday
   print, 'ohour, omin, osec: ', ohour, omin, osec

   iyear = fix (oyear)
   imon  = fix (omon)
   iday  = fix (oday)
   ihour = fix (ohour) - 10
   imin  = fix (omin)
   isec  = fix (osec)

   print, 'iyear, imon, iday: ', iyear, imon, iday
   print, 'ihour, imin, isec: ', ihour, imin, isec

   ;--- Determine DOY.

   mday      = [0,31,59,90,120,151,181,212,243,273,304,334]  
   mday_leap = [0,31,60,91,121,152,182,213,244,274,305,335] ;leap year

   IF ( (fix (iyear) mod 4) EQ 0 ) THEN $
      idoy = ( mday_leap (fix (imon) - 1) + fix (iday) ) $
   ELSE $
      idoy = (mday (fix (imon) - 1) + fix (iday))

   if (ihour LT 5) then $
   begin ;{
      ihour += 24
      idoy  -=  1
      ydn2md, iyear, idoy, imon, iday         ; convert DOY to month & day.

      if (idoy EQ 0) then $
      begin ;{
         iyear -= 1
         imon = 12
         iday   = 31
      end   ;}

   end   ;}

   print, 'iyear: ', iyear
   print, 'idoy:  ', idoy
   print, 'imon:  ', imon
   print, 'iday:  ', iday
   print, 'ihour: ', ihour
   print, 'imin:  ', imin
   print, 'isec:  ', isec

   hyear = strtrim (string (iyear), 2)
   hmon  = strtrim (string (imon,  format='(i02)'), 2)
   hday  = strtrim (string (iday,  format='(i02)'), 2)
   hhour = strtrim (string (ihour, format='(i02)'), 2)
   hmin  = strtrim (string (imin,  format='(i02)'), 2)
   hsec  = strtrim (string (isec,  format='(i02)'), 2)

   date_hst = hyear + '-' + hmon + '-' + hday + 'T' + $
              hhour + ':' + hmin + ':' + hsec

   print, 'date_hst: ', date_hst

END
