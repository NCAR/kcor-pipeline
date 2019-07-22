; docformat = 'rst'

;+
; Parse a DATE-OBS FITS keyword value in UT. Optionally, convert to HST.
;
; :Returns:
;   structure with doy, year, month, day, hour, minute, second, ehour, and
;    month_name fields
;
; :Params:
;   date_obs : in, required, type=string
;     UT date in the form "2018-04-24T00:22:02"
;
; :Keywords:
;   hst_date : out, optional, type=structure
;     set to a named variable to retrieve a structure corresponding to the date
;     converted to HST; the structure has fields doy, year, month, day, hour,
;     minute, and second
;-
function kcor_parse_dateobs, date_obs, hst_date=hst_date
  compile_opt strictarr
  
  ; create string data for annotating image
  
  ; extract fields from DATE_OBS
  year   = long(strmid(date_obs,  0, 4))
  month  = long(strmid(date_obs,  5, 2))
  day    = long(strmid(date_obs,  8, 2))
  hour   = long(strmid(date_obs, 11, 2))
  minute = long(strmid(date_obs, 14, 2))
  second = long(strmid(date_obs, 17, 2))
    
  ; convert month from integer to name of month
  month_name = (['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', $
                 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'])[month - 1L]

  ; compute DOY [day-of-year]
  mday      = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]

  is_leapyear = (year mod 4 eq 0) and (year mod 100 ne 0) or (year mod 400 eq 0)
  mday[2:*] += is_leapyear 
  doy = mday[month - 1L] + day

  ehour = float(hour) + minute / 60.0 + second / 3600.0

  if (arg_present(hst_date)) then begin
    ; determine observing time at MLSO [HST time zone]
    hst_doy    = doy
    hst_year   = year
    hst_month  = month
    hst_day    = day
    hst_hour   = hour - 10L
    hst_minute = minute
    hst_second = second

    if (hour lt 5) then begin   ; previous HST day if UTC hour < 5
      hst_hour += 24
      hst_doy  -=  1

      ydn2md, hst_year, hst_doy, hst_month, hst_day   ; convert DOY to month & day

      if (hst_doy eq 0) then begin   ; 31 Dec of previous year if DOY = 0
        hst_year -=  1
        hst_month = 12
        hst_day   = 31
      endif
    endif

    hst_ehour = float(hst_hour) + hst_minute / 60.0 + hst_second / 3600.0

    hst_date = {doy:    hst_doy, $
                year:   hst_year, $
                month:  hst_month, $
                day:    hst_day, $
                hour:   hst_hour, $
                minute: hst_minute, $
                second: hst_second, $
                ehour:  hst_ehour}
  endif

  return, {doy:        doy, $
           year:       year, $
           month:      month, $
           day:        day, $
           hour:       hour, $
           minute:     minute, $
           second:     second, $
           ehour:      ehour, $
           month_name: month_name}
end
