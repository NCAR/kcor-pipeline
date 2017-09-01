;+
; Project     :	STEREO
;
; Name        :	WCS_FIND_POSITION
;
; Purpose     :	Find position information in FITS header
;
; Category    :	FITS, Coordinates, WCS
;
; Explanation :	This procedure extracts observer's position information from a
;               FITS index structure, and adds it to a World Coordinate System
;               structure in a separate POSITION substructure.
;
;               This routine is normally called from FITSHEAD2WCS.
;
; Syntax      :	WCS_FIND_POSITION, INDEX, TAGS, SYSTEM, WCS
;
; Examples    :	See fitshead2wcs.pro
;
; Inputs      :	INDEX  = Index structure from FITSHEAD2STRUCT.
;               TAGS   = The tag names of INDEX
;               SYSTEM = A one letter code "A" to "Z", or the null string
;                        (see wcs_find_system.pro).
;               WCS    = A WCS structure, from FITSHEAD2WCS.
;
; Opt. Inputs :	None.
;
; Outputs     :	The output is the structure POSITION, which at the minimum
;               should contain the following parameters:
;
;                       SOHO        True if TELESCOP contains "SOHO"
;                       POS_ASSUMED True if the position was assumed to be
;                                   Earth's, based on the date.  IF SOHO=1,
;                                   then DIST_OBS is multiplyed by 0.99.
;                                   If no positional information at all is
;                                   found, then this is set to -1.
;                       DSUN_OBS    Distance to Sun center (meters)
;                       SOLAR_B0    Solar B0 angle
;                       CARR_EARTH  Carrington heliographic longitude of Earth
;
;               Depending on the contents of the FITS header, one or more of
;               the following parameters may also be included:
;
;                       HGLN_OBS    Stonyhurst heliographic longitude
;                       HGLT_OBS         "           "      latitude
;                       CRLN_OBS    Carrington heliographic longitude
;                       CRLT_OBS         "           "      latitude
;
;               The following are X,Y,Z triplets, in meters:
;
;                       GEI_OBS     Geocentric Equatorial Inertial
;                       GEO_OBS     Geographic
;                       GSE_OBS     Geocentric Solar Ecliptic
;                       GAE_OBS     Geocentric Aries Ecliptic
;                       GSM_OBS     Geocentric Solar Magnetic
;                       SM_OBS      Solar Magnetic
;                       MAG_OBS     Geomagnetic
;                       HAE_OBS     Heliocentric Aries Ecliptic
;                       HEE_OBS     Heliocentric Earth Ecliptic
;                       HEQ_OBS     Heliocentric Earth Equatorial
;                       HCI_OBS     Heliocentric Intertial
;
;               If POS_ASSUMED is true, the only parameters which are
;               (potentially) affected are DSUN_OBS, SOLAR_B0, HGLN_OBS,
;               HGLT_OBS, CRLN_OBS, and CRLT_OBS.
;
;               Note that SOLAR_B0, HGLT_OBS, and CRLT_OBS are all synonyms.
;
;               The POSITION structure is added to the WCS structure.
;
; Opt. Outputs:	None.
;
; Keywords    :	LUNFXB    = The logical unit number returned by FXBOPEN,
;                           pointing to the binary table that the header
;                           refers to.  Usage of this keyword allows
;                           implementation of the "Greenbank Convention",
;                           where keywords can be replaced with columns of
;                           the same name.
;
;               ROWFXB    = Used in conjunction with LUNFXB, to give the
;                           row number in the table.  Default is 1.
;
;               KEYWORD_NULL_VALUE = A value representing null data within the
;                           FITS header.  This keyword is intended to support
;                           incomplete FITS headers which have placeholders for
;                           keywords, but where the values of these keywords
;                           have not been properly established yet, e.g. as an
;                           intermediary step within the pipeline processing
;                           for an instrument.
;
;                           In general, it's not recommended to put keywords
;                           with incorrect values in a FITS header.  If the
;                           value of a keyword is not known, then it should be
;                           left out of the header.
;
; Calls       :	ANYTIM2UTC, UTC2STR, TAG_EXIST, REM_TAG, ADD_TAG, WCS_RSUN
;
; Common      :	None.
;
; Restrictions:	Currently, only one FITS header, and one WCS, can be examined
;               at a time.
;
;               Because this routine is intended to be called only from
;               FITSHEAD2WCS, no error checking is performed.
;
; Side effects:	None.
;
; Prev. Hist. :	None.
;
; History     :	Version 1, 15-Apr-2005, William Thompson, GSFC
;               Version 2, 02-Mar-2006, William Thompson, GSFC
;                       Changed test for get_orbit.pro
;               Version 3, 31-Jan-2008, WTT, change EXECUTE for pre-IDL 6.1
;               Version 4, 06-Jun-2008, WTT, additional SOHO parameters
;               Version 5, 26-Nov-2008, WTT, Add assumptions for Stonyhurst and
;                       Carrington heliographic coordinates.
;               Version 6, 10-Dec-2008, WTT, call WCS_RSUN
;               Version 7, 18-Aug-2010, NBR/WTT, check against null value
;               Version 8, 13-Apr-2011, WTT, add GAE for SDO
;
; Contact     :	WTHOMPSON
;-
;
pro wcs_find_position, index, tags, system, wcs, lunfxb=lunfxb, rowfxb=rowfxb, $
                       keyword_null_value=keyword_null_value
on_error, 2
;
;  Check to see if KEYWORD_NULL_VALUE was passed.
;
null_okay = n_elements(keyword_null_value) eq 0
if not null_okay then null = keyword_null_value[0] else null = 0
;
;  Start off by assuming that the position will be successfully extracted.
;
pos_assumed = 0
;
;  Is this a SOHO observation?
;
w = where(tags eq 'TELESCOP', count)
if count gt 0 then soho = (strpos(strupcase(index.(w[0])),'SOHO') gt -1) else $
  soho = 0
;
;  Look for the observer distance from Sun center.
;
val = wcs_find_keyword(index, tags, '', '', count, 'DSUN_OBS', $
                       lunfxb=lunfxb, rowfxb=rowfxb)
if (count gt 0) and (null_okay or (val[0] ne null)) then dsun_obs = val[0]
;
;  Look for observer position in heliographic coordinates.
;
val = wcs_find_keyword(index, tags, '', '', count, 'HGLN_OBS', $
                       lunfxb=lunfxb, rowfxb=rowfxb)
if (count gt 0) and (null_okay or (val[0] ne null)) then hgln_obs = val[0]
val = wcs_find_keyword(index, tags, '', '', count, 'HGLT_OBS', $
                       lunfxb=lunfxb, rowfxb=rowfxb)
if (count gt 0) and (null_okay or (val[0] ne null)) then hglt_obs = val[0]
val = wcs_find_keyword(index, tags, '', '', count, 'CRLN_OBS', $
                       lunfxb=lunfxb, rowfxb=rowfxb)
if (count gt 0) and (null_okay or (val[0] ne null)) then crln_obs = val[0]
val = wcs_find_keyword(index, tags, '', '', count, 'CRLT_OBS', $
                       lunfxb=lunfxb, rowfxb=rowfxb)
if (count gt 0) and (null_okay or (val[0] ne null)) then crlt_obs = val[0]
;
;  Look for observer position in the various standard coordinate systems.
;
codes = ['GEI','GEO','GSE','GAE','GSM','SM','MAG','HAE','HEE','HEQ','HCI']
for i=0,n_elements(codes)-1 do begin
    code = codes[i]
    val = wcs_find_keyword(index, tags, '', '', count, code+'X_OBS', $
                           lunfxb=lunfxb, rowfxb=rowfxb)
    if (count gt 0) and (null_okay or (val[0] ne null)) then begin
        x = val[0]
        val = wcs_find_keyword(index, tags, '', '', count, code+'Y_OBS', $
                               lunfxb=lunfxb, rowfxb=rowfxb)
        if (count gt 0) and (null_okay or (val[0] ne null)) then begin
            y = val[0]
            val = wcs_find_keyword(index, tags, '', '', count, code+'Z_OBS', $
                                   lunfxb=lunfxb, rowfxb=rowfxb)
            if (count gt 0) and (null_okay or (val[0] ne null)) then begin
                z = val[0]
                test = execute(code + '_OBS = [x,y,z]')
            endif
        endif
    endif
endfor
;
;  If DSUN_OBS wasn't found, then try to determine it from one of the
;  heliocentric coordinate systems.
;
if n_elements(dsun_obs) eq 0 then begin
    case 3 of
        n_elements(hae_obs):  dsun_obs = sqrt(total(hae_obs^2))
        n_elements(hee_obs):  dsun_obs = sqrt(total(hee_obs^2))
        n_elements(heq_obs):  dsun_obs = sqrt(total(heq_obs^2))
        n_elements(hci_obs):  dsun_obs = sqrt(total(hci_obs^2))
    else: dummy=0
    endcase
endif
;
;  Stonyhurst-Heliographic coordinates can be derived from HEEQ coordinates.
;
if n_elements(heq_obs) eq 3 then begin
    long = (180.d0 / !dpi) * atan(heq_obs[1], heq_obs[0])
    lat  = (180.d0 / !dpi) * asin(heq_obs[2] / sqrt(total(heq_obs^2)))
    if n_elements(hgln_obs) eq 0 then hgln_obs = long
    if n_elements(hglt_obs) eq 0 then hglt_obs = lat
endif
;
;  Conversely, HEEQ coordinates can be derived from Stonyhurst-Heliographic
;  coordinates.
;
if (n_elements(dsun_obs) eq 1) and (n_elements(hgln_obs) eq 1) and $
  (n_elements(hglt_obs) eq 1) and (n_elements(heq_obs) eq 0) then begin
    long = (!dpi / 180.d0) * hgln_obs
    lat  = (!dpi / 180.d0) * hglt_obs
    heq_obs = dsun_obs * [cos(long)*cos(lat), sin(long)*cos(lat), sin(lat)]
endif
;
;  The solar B0 angle can be derived from the heliographic latitude.
;
case 1 of
    n_elements(hglt_obs): solar_b0 = hglt_obs
    n_elements(crlt_obs): solar_b0 = crlt_obs
;
;  Or from HCI coordinates.
;
    (n_elements(hci_obs) eq 3): solar_b0 = $
      (180.d0/!dpi) * asin(hci_obs[2] / sqrt(total(hci_obs^2)))
;
;  Otherwise, look for the keyword SOLAR_B0 in the FITS header.
;
    else: begin
        val = wcs_find_keyword(index, tags, '', '', count, 'SOLAR_B0', $
                               lunfxb=lunfxb, rowfxb=rowfxb)
        if (count gt 0) and (null_okay or (val[0] ne null)) then solar_b0 = val[0]
    endcase
endcase
;
;  From the observation date, get Earth's position during the observation.
;
if tag_exist(wcs, 'TIME', /top_level) then begin
    if tag_exist(wcs.time, 'observ_date') then begin
        date_obs = wcs.time.observ_date
        earth_data = pb0r(date_obs, /earth)
        hglt_earth = earth_data[1]
        hgln_earth = 0.d0                                   ;by definition
        dsun_earth = wcs_rsun() * (10800.d0 / !dpi) / earth_data[2]
        carr_earth = (tim2carr(date_obs))[0]
    endif
endif
;
;  If a SOHO observation, see if one can access the orbit files.
;
if soho and (n_elements(date_obs) ne 0) then begin
    errmsg = ''
    type = ''
    test = execute('orbit = get_orbit(date_obs, type, errmsg=errmsg)', 1)
    if test and (errmsg eq '') and (type ne '') then begin
        if n_elements(gei_obs) eq 0 then gei_obs = 1000.d0 * $
          [orbit.gci_x, orbit.gci_y, orbit.gci_z]
        if n_elements(gse_obs) eq 0 then gse_obs = 1000.d0 * $
          [orbit.gse_x, orbit.gse_y, orbit.gse_z]
        if n_elements(gsm_obs) eq 0 then gsm_obs = 1000.d0 * $
          [orbit.gsm_x, orbit.gsm_y, orbit.gsm_z]
        if n_elements(hae_obs) eq 0 then hae_obs = 1000.d0 * $
          [orbit.hec_x, orbit.hec_y, orbit.hec_z]
        if n_elements(dsun_obs) eq 0 then dsun_obs = sqrt(total(hae_obs^2))
        if n_elements(solar_b0) eq 0 then solar_b0 = !radeg * $
          orbit.hel_lat_soho
        if n_elements(crln_obs) eq 0 then crln_obs = !radeg * $
          orbit.hel_lon_soho
        if n_elements(crlt_obs) eq 0 then crlt_obs = solar_b0
        if n_elements(hgln_obs) eq 0 then hgln_obs = !radeg * $
          (orbit.hel_lon_soho - orbit.hel_lon_earth)
        if n_elements(hglt_obs) eq 0 then hglt_obs = solar_b0
    endif
endif
;
;  If DSUN_OBS is not yet defined, then try using GSE coordinates.
;
if (n_elements(dsun_obs) eq 0) and (n_elements(gse_obs) eq 3) and $
  (n_elements(dsun_earth) ne 0) then $
  dsun_obs = sqrt(total((gse_obs - [dsun_earth,0,0])^2))
;
;  If DSUN_OBS and/or SOLAR_B0 are not yet defined, then assume the
;  observation was made from Earth.  If SOHO, then modify DSUN_OBS by 1%.
;
if ((n_elements(dsun_obs) eq 0) or (n_elements(solar_b0) eq 0)) and $
  (n_elements(earth_data) eq 3) then begin
    if n_elements(dsun_obs) eq 0 then begin
        dsun_obs = dsun_earth
        if soho then dsun_obs = 0.99 * dsun_obs
        pos_assumed = 1
    endif
    if n_elements(solar_b0) eq 0 then begin
        solar_b0 = hglt_earth
        pos_assumed = 1
    endif
endif
;
;  If POS_ASSUMED is set, then fill in the Stonyhurst and Carrington
;  heliographic coordinates.
;
if pos_assumed then begin
    if n_elements(hgln_obs) eq 0 then hgln_obs = 0.0
    if n_elements(hglt_obs) eq 0 then hglt_obs = solar_b0
    if n_elements(crln_obs) eq 0 then crln_obs = carr_earth
    if n_elements(crlt_obs) eq 0 then crlt_obs = solar_b0
endif
;
;  Start creating the POSITION structure.
;
command = 'position = {soho: soho, pos_assumed: pos_assumed'
if n_elements(dsun_obs) eq 1 then command = command + ', dsun_obs: dsun_obs'
if n_elements(solar_b0) eq 1 then command = command + ', solar_b0: solar_b0'
if n_elements(carr_earth) eq 1 then command = command + $
  ', carr_earth: carr_earth'
if n_elements(hgln_obs) eq 1 then command = command + ', hgln_obs: hgln_obs'
if n_elements(hglt_obs) eq 1 then command = command + ', hglt_obs: hglt_obs'
if n_elements(crln_obs) eq 1 then command = command + ', crln_obs: crln_obs'
if n_elements(crlt_obs) eq 1 then command = command + ', crlt_obs: crlt_obs'
;
for i=0,n_elements(codes)-1 do begin
    name = codes[i] + '_obs'
    test = execute('nn = n_elements(' + name + ')')
    if nn gt 0 then command = command + ', ' + name + ': ' + name
endfor
;
;  Create the POSITION structure.
;
command = command + '}'
test = execute(command)
;
;  If no positional information was found, then set POS_ASSUMED to -1.
;
if n_tags(position) eq 2 then position.pos_assumed = -1
;
;  Add the POSITION tag to the WCS structure.
;
if tag_exist(wcs, 'POSITION', /top_level) then wcs = rem_tag(wcs, 'POSITION')
wcs = add_tag(wcs, position, 'POSITION', /top_level)
;
return
end
