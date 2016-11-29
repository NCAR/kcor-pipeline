;+
; Project     :	STEREO - SSC
;
; Name        :	GET_STEREO_COORD
;
; Purpose     :	Returns the orbital position of STEREO A or B
;
; Category    :	STEREO, Orbit
;
; Explanation :	This routine returns the position of one of the two STEREO
;               spacecraft in a wide variety of coordinate systems.  It can
;               also be used to return planetary or lunar positions.
;
; Syntax      :	State = GET_STEREO_COORD( DATE, SPACECRAFT )
;
; Examples    :	State = GET_STEREO_COORD( '2006-05-06T11:30:00', 'A' )
;
; Inputs      :	DATE       = The date and time.  This can be input in any
;                            format accepted by ANYTIM2UTC, and can also be an
;                            array of values.
;
;               SPACECRAFT = Can be one of the following forms:
;
;                               'A'             'B'
;                               'STA'           'STB'
;                               'Ahead'         'Behind'
;                               'STEREO Ahead'  'STEREO Behind'
;                               'STEREO-Ahead'  'STEREO-Behind'
;                               'STEREO_Ahead'  'STEREO_Behind'
;
;                            Case is not important.  The NAIF numeric codes of
;                            -234 and -235 respectively can also be used.
;
;                            Also can be the name of a solar system body,
;                            e.g. "Earth", "Mars", "Moon", etc.  Can also be
;                            the name of another spacecraft (e.g. 'SOHO') if
;                            the appropriate ephemerides are loaded.
;                            
;
; Opt. Inputs :	None.
;
; Outputs     :	The result of the function is the six-value state vector,
;               containing the X,Y,Z coordinates in kilometers, and VX,VY,VZ in
;               km/sec.  If DATE is a vector, then the result will have
;               additional dimensions.
;
; Opt. Outputs:	None.
;
; Keywords    : SYSTEM = Character string, giving one of the following
;                        standard coordinate systems:
;
;                               GEI     Geocentric Equatorial Inertial
;                               GEO     Geographic
;                               GSE     Geocentric Solar Ecliptic
;                               GAE     Geocentric Aries Ecliptic
;                               MAG     Geomagnetic
;                               GSM     Geocentric Solar Magnetospheric
;                               SM      Solar Magnetic
;                               HCI     Heliocentric Inertial (default)
;                               HAE     Heliocentric Aries Ecliptic
;                               HEE     Heliocentric Earth Ecliptic
;                               HEEQ    Heliocentric Earth Equatorial (or HEQ)
;                               Carrington (can be abbreviated)
;                               HGRTN   Heliocentric Radial-Tangential-Normal
;                               RTN     Radial-Tangential-Normal
;                               SCI     STEREO Science Pointing
;                               HERTN   Heliocentric Ecliptic RTN
;
;                        Case is not important.  RTN and SCI are
;                        spacecraft-centered, and require that the TARGET
;                        keyword be passed, as do HGRTN/HERTN.
;
;               TARGET = Used with SYSTEM="RTN", SYSTEM="HGRTN", SYSTEM="SCI",
;                        or SYSTEM="HERTN" to specify the target, e.g.
;
;                        STATE = GET_STEREO_COORD('2007-01-01, 'A', $
;                                       SYSTEM='RTN',Target='Earth')
;
;               CORR = Aberration correction.  Default is 'None'.  Other
;                      possible values are:
;
;                       'LT'    Light travel time
;                       'LT+S'  Light travel time plus stellar aberration
;                       'XLT'   Light travel time, transmission case
;                       'XLT+S' Light travel plus aberration, transmission case
;
;               PRECESS = If set, then ecliptic coordinates are precessed from
;                         the J2000 reference frame to the mean ecliptic of
;                         date.  Only used for HAE/GAE.  Default is PRECESS=0.
;                         GSE and HEE use the ecliptic of date by definition.
;
;               NOVELOCITY = If set, then only the positions are returned, and
;                            not the velocities.  This is always the case for
;                            GSM and SM coordinates.
;
;               LTIME  = Returned as the light travel time, in seconds.
;
;               METERS = If set, then the coordinates are returned in units of
;                        meters, instead of the default of kilometers.
;                        Velocities are returned as meters/second.  Note
;                        that meters (and meters/second) are required for FITS
;                        header keywords.
;
;               AU     = If set, then the coordinates are returned in
;                        Astronomical Units, instead of the default of
;                        kilometers.  Velocities are returned as AU/sec.
;
;               FOUND  = Byte array containing whether or not the coordinates
;                        were found.  If zero, then the coordinates were
;                        extrapolated.
;
;               ERRMSG = If defined and passed, then any error messages will be
;                        returned to the user in this parameter rather than
;                        depending on the MESSAGE routine in IDL.  If no errors
;                        are encountered, then a null string is returned.  In
;                        order to use this feature, ERRMSG must be defined
;                        first, e.g.
;
;                               ERRMSG = ''
;                               State = GET_STEREO_COORD( ERRMSG=ERRMSG, ... )
;                               IF ERRMSG NE '' THEN ...
;
;               Will also accept any LOAD_STEREO_SPICE or ANYTIM2UTC keywords.
;
; Calls       :	ANYTIM2UTC, CONCAT_DIR, CSPICE_STR2ET, CSPICE_SPKEZR,
;               LOAD_STEREO_SPICE, STEREO_GEO2MAG, STEREO_GSE2GSM,
;               STEREO_GSE2SM, CSPICE_CONICS, PARSE_STEREO_NAME
;
; Common      :	STEREO_SPICE_CONIC contains data from LOAD_STEREO_SPICE used to
;               extrapolate the Ahead and Behind ephemerides beyond their end
;               date.  Not applicable to HGRTN, RTN, HERTN, or SCI coordinate
;               systems.
;
; Restrictions:	This procedure works in conjunction with the Icy/CSPICE
;               package, which is implemented as an IDL Dynamically Loadable
;               Module (DLM).  The Icy source code can be downloaded from
;
;                       ftp://naif.jpl.nasa.gov/pub/naif/toolkit/IDL
;
;               Because this uses dynamic frames, it requires Icy/CSPICE
;               version N0058 or higher.
;
; Side effects:	Will automatically load the SPICE ephemeris files, if not
;               already loaded.
;
; Prev. Hist. :	Based on STEREO_COORD_DEMO
;
; History     :	Version 1, 26-Aug-2005, William Thompson, GSFC
;               Version 2, 30-Aug-2005, William Thompson, GSFC
;                       Added units keywords METERS and AU.
;               Version 3, 12-Sep-2005, William Thompson, GSFC
;                       Accept ANYTIM2UTC keywords
;               Version 4, 21-Sep-2005, William Thompson, GSFC
;                       Added MAG, GSM, and SM coordinates
;               Version 5, 29-Sep-2005, William Thompson, GSFC
;                       GSM and SM returns both position and velocity
;               Version 6, 22-Mar-2006, William Thompson, GSFC
;                       Allow STEREO ephemerides to be extrapolated
;               Version 7, 28-Mar-2006, William Thompson, GSFC
;                       Fix bug when MAXDATE not defined.
;               Version 8, 02-May-2006, William Thompson, GSFC
;                       Added Heliocentric Ecliptic RTN (HERTN)
;               Version 9, 01-Sep-2006, William Thompson, GSFC
;                       Added call to PARSE_STEREO_NAME
;               Version 10, 13-Mar-2006, William Thompson, GSFC
;                       Added FOUND keyword
;               Version 11, 18-Jun-2010, WTT (GSFC), Lynn Simpson (NRL)
;                       Better error handling when date is out of range
;                       Include SOHO for HGRTN/RTN coordinates
;               Version 12, 13-Apr-2011, William Thompson, GSFC
;                       Added GAE coordinates for SDO
;               Version 13, 14-Feb-2013, WTT, Assume GEORTN when SPACECRAFT
;                       is not recognized
;
; Contact     :	WTHOMPSON
;-
;
function get_stereo_coord, date, spacecraft, system=k_system, ltime=ltime, $
                           corr=k_corr, precess=precess, target=target, $
                           novelocity=novelocity, meters=meters, au=au, $
                           found=found, errmsg=errmsg, _extra=_extra
;
common stereo_spice_conic, mu, maxdate, conic
on_error, 2
;
if n_params() ne 2 then begin
    message = 'Syntax:  State = GET_STEREO_COORD( DATE, SPACECRAFT )'
    goto, handle_error
endif
;
;  Determine which spacecraft (or planetary body) was requested, and translate
;  it into the proper input for SPICE.
;
sc = parse_stereo_name(spacecraft, ['-234', '-235'])
if strupcase(spacecraft) eq 'SOHO' then sc = '-21'
;
;  Convert the date/time to UTC.
;
message = ''
utc = anytim2utc(date, /ccsds, errmsg=message, _extra=_extra)
if message ne '' then goto, handle_error
;
;  Parse the keywords.
;
if n_elements(k_corr) eq 1 then corr = k_corr else corr = 'None'
;
;  Make sure that the ephemeris files are loaded.
;
message = ''
load_stereo_spice, errmsg=message, _extra=_extra
if message ne '' then goto, handle_error
;
;  Convert the date/time to ephemeris time.
;
cspice_str2et, utc, et
;
;  Determine which coordinate system was specified.
;
if n_elements(k_system) eq 1 then system=strupcase(k_system) else system='HCI'
if system eq 'HEQ' then system = 'HEEQ'
if system eq strmid('CARRINGTON',0,strlen(system)) then system = 'CARRINGTON'
;
if (system eq 'HGRTN') or (system eq 'RTN') then begin
    if sc eq '-234' then begin
        frame = 'STAHGRTN'
    end else if sc eq '-235' then begin
        frame = 'STBHGRTN'
    end else if sc eq '-21' then begin
        frame = 'SOHOHGRTN'
    end else begin
        if not !quiet then print, 'Assuming Earth observation'
        frame = 'GEORTN'
    endelse
    if n_elements(target) eq 0 then begin
        message = 'TARGET not specified'
        goto, handle_error
    endif
endif
;
if (system eq 'SCI') then begin
    if sc eq '-234' then begin
        frame = 'STASCPNT'
    end else if sc eq '-235' then begin
        frame = 'STBSCPNT'
    end else begin
        message = 'Unable to recognize spacecraft specification'
        goto, handle_error
    endelse
    if n_elements(target) eq 0 then begin
        message = 'TARGET not specified'
        goto, handle_error
    endif
endif
;
if (system eq 'HERTN') then begin
    if sc eq '-234' then begin
        frame = 'STAHERTN'
    end else if sc eq '-235' then begin
        frame = 'STBHERTN'
    end else begin
        message = 'Unable to recognize spacecraft specification'
        goto, handle_error
    endelse
    if n_elements(target) eq 0 then begin
        message = 'TARGET not specified'
        goto, handle_error
    endif
endif
;
;  If one of the two spacecraft was selected, then separate the times into
;  those before and after the last ephemeris date.
;
n0 = 0
n1 = n_elements(et)
if n_elements(maxdate) eq 2 then begin
    if sc eq '-234' then begin
        w1 = where(utc le maxdate[0], n1, complement=w0, ncomplement=n0)
        if n0 gt 0 then begin
            cspice_str2et, maxdate[0], et0
            et[w0] = et0
        endif
        elts = conic[*,0]
    end else if sc eq '-235' then begin
        w1 = where(utc le maxdate[1], n1, complement=w0, ncomplement=n0)
        if n0 gt 0 then begin
            cspice_str2et, maxdate[1], et0
            et[w0] = et0
        endif
        elts = conic[*,1]
    endif
endif
;
;  Based on the coordinate system requested, get the state and light travel
;  time.
;
catch, error_status
if error_status ne 0 then begin
    message = !error_state.msg
    catch, /cancel
    goto, handle_error
endif
case strupcase(system) of
    'GEI': cspice_spkezr, sc, et, 'J2000', corr, 'Earth', state, ltime
    'GEO': cspice_spkezr, sc, et, 'IAU_EARTH', corr, 'Earth', state, ltime
    'MAG': begin
        cspice_spkezr, sc, et, 'IAU_EARTH', corr, 'Earth', state, ltime
        stereo_geo2mag, utc, state
        end
    'GSE': cspice_spkezr, sc, et, 'GSE', corr, 'Earth', state, ltime
    'GSM': begin
        cspice_spkezr, sc, et, 'GSE', corr, 'Earth', state, ltime
        stereo_gse2gsm, utc, state
        end
    'SM': begin
        cspice_spkezr, sc, et, 'GSE', corr, 'Earth', state, ltime
        stereo_gse2sm, utc, state
        end
    'GAE': begin
        if keyword_set(precess) then frame='ECLIPDATE' else frame='ECLIPJ2000'
        cspice_spkezr, sc, et, frame, corr, 'Earth', state, ltime
        end
    'HCI': cspice_spkezr, sc, et, 'HCI', corr, 'Sun', state, ltime
    'HAE': begin
        if keyword_set(precess) then frame='ECLIPDATE' else frame='ECLIPJ2000'
        cspice_spkezr, sc, et, frame, corr, 'Sun', state, ltime
        end
    'HEE': cspice_spkezr, sc, et, 'HEE', corr, 'Sun', state, ltime
    'HEEQ': cspice_spkezr, sc, et, 'HEEQ', corr, 'Sun', state, ltime
    'CARRINGTON': cspice_spkezr, sc, et, 'IAU_SUN', corr, 'Sun', state, ltime
    'HGRTN': cspice_spkezr, target, et, frame, corr, 'Sun', state, ltime
    'RTN': cspice_spkezr, target, et, frame, corr, sc, state, ltime
    'SCI': cspice_spkezr, target, et, frame, corr, sc, state, ltime
    'HERTN': cspice_spkezr, target, et, frame, corr, 'Sun', state, ltime
    else: begin
        message = 'Unrecognized coordinate system'
        goto, handle_error
    endelse
endcase
catch, /cancel
;
;  If there are times beyond the end of the valid range, use cspice_conic to
;  fill in the times.
;
sz = size(et)
if sz[0] eq 0 then found = 1b else found = replicate(1b, sz[1:sz[0]])
if n0 gt 0 then begin
    found[w0] = 0b
    for i=0L,n0-1 do begin
        utc0 = utc[w0[i]]
        cspice_str2et, utc0, et
        cspice_conics, elts, et, temp
        state[*,w0[i]] = temp
        ltime[w0[i]] = -1
    endfor
    temp = state[*,w0]
    convert_stereo_coord, utc[w0], temp, 'HAE', system
    state[*,w0] = temp
endif
;
;  If requested, strip off the velocity vector.
;
if keyword_set(novelocity) then state = state[0:2,*,*,*,*,*,*,*]
;
;  Define the proper units, and return.
;
if keyword_set(meters) then state = state*1000 else $
  if keyword_set(au) then state = state / 1.4959787D8
;
return, state
;
;  Error handling point.
;
handle_error:
if n_elements(errmsg) eq 0 then message, message else $
  errmsg = 'get_stereo_coord: ' + message
;
end
