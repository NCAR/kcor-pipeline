;+
; Project     :	STEREO
;
; Name        :	WCS_CONV_FIND_DSUN
;
; Purpose     :	Find DSUN parameter for converting coordinates.
;
; Category    :	Coordinates, WCS
;
; Explanation : This routine is part of the WCS coordinate conversion software.
;               It is used to find the DSUN parameter.  The units could be
;               based on an examination of the WCS structure, or explicitly set
;               through the LENGTH_UNITS keyword.
;
; Syntax      :	WCS_CONV_FIND_DSUN, DSUN, RSUN, WCS=WCS
;
; Examples    :	See WCS_CONV_HCC_HPC
;
; Inputs      :	None.
;
; Opt. Inputs :	None.
;
; Outputs     :	DSUN    = Distance to Sun.  See keywords below for information
;                         about the units.  If the program is unable to
;                         determine DSUN, then 1 A.U. is assumed.
;
; Opt. Outputs:	RSUN    = Solar radius, in same units as DSUN
;
;               FACTOR  = The conversion factor relative to meters.
;
; Keywords    :	WCS     = World Coordinate System structure.  Used to determine
;                         DSUN and the units of the data.
;
;               LENGTH_UNITS = String describing the units to be applied to
;                              DSUN.  Can be any string recognized by
;                              wcs_parse_units, e.g. "m", "km", "AU", "solRad",
;                              etc.  Overrides WCS.  The default is meters.
;
;               DSUN_OBS= Solar distance, in meters.
;
;               DATE_OBS= Observation date.  Used to determine the default
;                         solar distance, assuming an Earth-based observation.
;
; Calls       :	WCS_RSUN, WCS_PARSE_UNITS, VALID_WCS, PB0R, WCS_AU
;
; Common      :	None.
;
; Restrictions:	None.
;
; Side effects: None.
;
; Prev. Hist. :	None.
;
; History     :	Version 1, 12-Dec-2008, William Thompson, GSFC
;               Version 2, 13-Aug-2009, WTT, Fixed bug assuming length units
;
; Contact     :	WTHOMPSON
;-
;
pro wcs_conv_find_dsun, dsun, rsun, factor, wcs=wcs, length_units=length_units, $
                        dsun_obs=k_dsun, date_obs=date
on_error, 2
;
;  Define RSUN in meters.
;
rsun = wcs_rsun()
;
;  Set any parameters not yet known to zero.
;
if n_elements(k_dsun) eq 1 then dsun = k_dsun else dsun = 0
factor = 0
;
;  If the LENGTH_UNITS keyword was passed, then use this to determine the
;  units.
;
if datatype(length_units) eq 'STR' then begin
    wcs_parse_units, length_units, base_units, factor
    if base_units ne 'm' then message, $
      'Length units ' + length_units + ' not recognized'
endif
;
;  If a valid WCS structure is present, then use it to determine both DSUN and
;  the units.
;
if valid_wcs(wcs) then begin
    if (dsun eq 0) and tag_exist(wcs.position, 'dsun_obs') then $
      dsun = wcs.position.dsun_obs
;
;  Extract the observation date, if present, and if not passed by keyword.
;
    if (n_elements(date) eq 0) and tag_exist(wcs, 'time') then $
      if tag_exist(wcs.time, 'observ_date') then date = wcs.time.observ_date
;
;  First, try the X and Y dimensions.
;
    if factor eq 0 then begin
        wcs_parse_units, wcs.cunit[wcs.ix], base_units, factor, /quiet
        if base_units eq 'm' then goto, check_dsun else factor = 0
;
        wcs_parse_units, wcs.cunit[wcs.iy], base_units, factor, /quiet
        if base_units eq 'm' then goto, check_dsun else factor = 0
;
;  Otherwise, step through the rest of the dimensions, and look for a length
;  dimension that isn't a wavelength.
;
        for i=0,n_elements(wcs.cunit)-1 do begin
            type = strlowcase(strmid(wcs.ctype[i],0,4))
            if (type ne 'wave') and (type ne 'awav') and (i ne wcs.ix) and $
              (i ne wcs.iy) then begin
                wcs_parse_units, wcs.cunit[i], base_units, factor, /quiet
                if base_units eq 'm' then goto, check_dsun else factor = 0
            endif
        endfor
    endif
endif
;
;  If the units are still not determined, then assume meters.
;
if factor eq 0 then factor = 1
;
;  If DSUN is not yet established, then try using the date.
;
check_dsun:
;
if (dsun eq 0) and (n_elements(date) ne 0) then begin
    test = pb0r( date, /earth, error=error)
    if error eq '' then dsun = rsun * (60.d0*180.d0/!dpi)  / test[2]
endif
;
;  If still not established, then assume 1 A.U.
;
if dsun eq 0 then dsun = wcs_au()
;
;  Apply the coordinate conversion factor.
;
dsun = dsun / factor
rsun = rsun / factor
;
return
end
