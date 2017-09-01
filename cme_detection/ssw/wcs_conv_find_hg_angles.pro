;+
; Project     :	STEREO
;
; Name        :	WCS_CONV_FIND_HG_ANGLES
;
; Purpose     :	Find heliographic angles for converting coordinates.
;
; Category    :	Coordinates, WCS
;
; Explanation : This routine is part of the WCS coordinate conversion software.
;               It is used to find the B0 and L0 parameters.
;
; Syntax      :	WCS_CONV_FIND_HG_ANGLES, B0, L0, WCS=WCS
;
; Examples    :	See WCS_CONV_HCC_HG
;
; Inputs      :	None.
;
; Opt. Inputs :	None.
;
; Outputs     :	B0      = Solar B0, in degrees.
;               L0      = Solar L0, in degrees.
;
;               If these parameters cannot be determined, then they are both
;               set to zero.
;
; Opt. Outputs:	None.
;
; Keywords    :	WCS     = World Coordinate System structure.  Used to determine
;                         B0 and L0.
;
;               B0_ANGLE= Solar B0 angle, in degrees.  Overrides WCS structure.
;
;               L0_ANGLE= Solar L0 angle, in degrees.  Overrides WCS structure.
;
;               DATE_OBS= Observation date.  Used to determine the default
;                         B0 and L0 angles, assuming an Earth-based
;                         observation.
;
;               CARRINGTON = If set, then L0 is returned as the Carrington
;                         longitude of Sun center.  The default is to return
;                         the Stonyhurst longitude.
;
; Calls       :	VALID_WCS, TAG_EXIST, PB0R, DELVARX
;
; Common      :	None.
;
; Restrictions:	None.
;
; Side effects: None.
;
; Prev. Hist. :	None.
;
; History     :	Version 1, 10-Dec-2008, William Thompson, GSFC
;               Version 2, 07-Oct-2010, WTT, improved B0 determination
;
; Contact     :	WTHOMPSON
;-
;
pro wcs_conv_find_hg_angles, b0, l0, wcs=wcs, b0_angle=b0_angle, $
                             l0_angle=l0_angle, date_obs=date, $
                             carrington=carrington
on_error, 2
;
;  Undefine any parameters not yet known.
;
if n_elements(b0_angle) eq 1 then b0 = b0_angle else delvarx, b0
if n_elements(l0_angle) eq 1 then l0 = l0_angle else delvarx, l0
if (n_elements(b0) eq 1) and (n_elements(l0) eq 1) then return
;
;  If a valid WCS structure is present, then use it to determine B0 and L0.
;
if valid_wcs(wcs) then begin
    if (n_elements(b0) eq 0) and tag_exist(wcs.position, 'hglt_obs') then $
      b0 = wcs.position.hglt_obs
    if (n_elements(b0) eq 0) and tag_exist(wcs.position, 'crlt_obs') then $
      b0 = wcs.position.crlt_obs
    if (n_elements(b0) eq 0) and tag_exist(wcs.position, 'solar_b0') then $
      b0 = wcs.position.solar_b0
    if keyword_set(carrington) then begin
        if (n_elements(l0) eq 0) and tag_exist(wcs.position, 'crln_obs') then $
          l0 = wcs.position.crln_obs
    end else begin
        if (n_elements(l0) eq 0) and tag_exist(wcs.position, 'hgln_obs') then $
          l0 = wcs.position.hgln_obs
    endelse
    if (n_elements(b0) eq 1) and (n_elements(l0) eq 1) then return
;
;  Extract the observation date, if present, and if not passed by keyword.
;
    if (n_elements(date) eq 0) and tag_exist(wcs, 'time') then $
      if tag_exist(wcs.time, 'observ_date') then date = wcs.time.observ_date
endif
;
;  Try using the date to get B0
;
if (n_elements(b0) eq 0) and (n_elements(date) ne 0) then begin
    test = pb0r(date, /earth, error=error)
    if error eq '' then b0 = test[1]
endif
;
;  If /CARRINGTON is set, then try using the date to get L0.
;
if (n_elements(l0) eq 0) and (n_elements(date) ne 0) and $
  keyword_set(carrington) then l0 = (tim2carr(date))[0]
;
;  If either B0 or L0 are not yet established, then set them to zero.
;
if n_elements(b0) eq 0 then b0 = 0
if n_elements(l0) eq 0 then l0 = 0
;
return
end
