;+
; Project     :	STEREO - SSC
;
; Name        :	CONVERT_STEREO_COORD
;
; Purpose     :	Converts between coordinate systems
;
; Category    :	STEREO, Orbit
;
; Explanation :	This routine converts coordinate arrays, such as those returned
;               by GET_STEREO_COORD, from one coordinate system to another.
;
; Syntax      :	CONVERT_STEREO_COORD, DATE, COORD, FROM, TO
;
; Examples    :	CONVERT_STEREO_COORD, '2006-05-06T11:30', COORD, 'HCI', 'GSE'
;
; Inputs      :	DATE    = The date and time.  This can be input in any format
;                         accepted by ANYTIM2UTC, and can also be an array of
;                         values.
;
;               COORD   = Either the six-value state vector, containing the
;                         X,Y,Z coordinates, and VX,VY,VZ velocities, or the
;                         just the three-value coordinates.  Can also be a 6xN
;                         or 3xN array.  If DATE is a vector, then N must be
;                         the size of DATE.
;
;               FROM    = Character string, giving one of the following
;                         standard coordinate systems to convert from:
;
;                               GEI     Geocentric Equatorial Inertial
;                               GEO     Geographic
;                               GSE     Geocentric Solar Ecliptic
;                               GAE     Geocentric Aries Ecliptic
;                               MAG     Geomagnetic
;                               GSM     Geocentric Solar Magnetospheric
;                               SM      Solar Magnetic
;                               HCI     Heliocentric Inertial
;                               HAE     Heliocentric Aries Ecliptic
;                               HEE     Heliocentric Earth Ecliptic
;                               HEEQ    Heliocentric Earth Equatorial (or HEQ)
;                               Carrington (can be abbreviated)
;                               GRTN    Geocentric Radial-Tangential-Normal
;                               HGRTN   Heliocentric Radial-Tangential-Normal
;                               RTN     Radial-Tangential-Normal
;                               SCI     STEREO Science Pointing
;                               HERTN   Heliocentric Ecliptic RTN
;                               STPLN   Stereo Mission Plane
;
;                         Case is not important.  The last five require that
;                         the SPACECRAFT keyword be passed.
;
;                         HGRTN and RTN will also support the SOHO spacecraft
;                         and Earth-based observations.  Any unrecognized
;                         spacecraft identification will be assumed to be
;                         Earth-based.
;
;               TO      = Character string, as above, giving the coordinate
;                         system to convert to.
;
; Opt. Inputs :	None.
;
; Outputs     :	COORD   = Returned as the converted coordinates.
;
; Opt. Outputs:	None.
;
; Keywords    : PRECESS = If set, then ecliptic coordinates are precessed from
;                         the J2000 reference frame to the mean ecliptic of
;                         date.  Only used for HAE/GAE.  Default is PRECESS=0.
;                         GSE and HEE use the ecliptic of date by definition.
;
;               SPACECRAFT = Used when either the FROM or TO system is HGRTN,
;                         RTN, or SCI.  Can be one of the following forms:
;
;                               'A'             'B'
;                               'STA'           'STB'
;                               'Ahead'         'Behind'
;                               'STEREO Ahead'  'STEREO Behind'
;                               'STEREO-Ahead'  'STEREO-Behind'
;                               'STEREO_Ahead'  'STEREO_Behind'
;
;                         Case is not important.  The NAIF numeric codes of
;                         -234 and -235 respectively can also be used.
;
;               IGNORE_ORIGIN = If set, the origins of the FROM and TO
;                         coordinate systems are ignored.  This is used for
;                         vectors which only indicate pointing, such as the
;                         direction of a star.
;
;               METERS = If set, then the coordinates are in units of meters,
;                        instead of the default of kilometers.  Velocities are
;                        in meters/second.  This keyword is important if the
;                        coordinate conversion involves an origin shift.
;
;               AU     = If set, then the coordinates are in Astronomical
;                        Units, instead of the default of kilometers.
;                        Velocities are in AU/sec.
;
;               ERRMSG  = If defined and passed, then any error messages will
;                         be returned to the user in this parameter rather than
;                         depending on the MESSAGE routine in IDL.  If no
;                         errors are encountered, then a null string is
;                         returned.  In order to use this feature, ERRMSG must
;                         be defined first, e.g.
;
;                               ERRMSG = ''
;                               CONVERT_STEREO_COORD, ERRMSG=ERRMSG, ...
;                               IF ERRMSG NE '' THEN ...
;
;               Will also accept any LOAD_STEREO_SPICE or ANYTIM2UTC keywords.
;
; Calls       :	ANYTIM2UTC, CSPICE_STR2ET, CSPICE_SPKEZR, CSPICE_PXFORM,
;               CSPICE_SXFORM, LOAD_STEREO_SPICE, STEREO_GEO2MAG,
;               STEREO_GSE2GSM, STEREO_GSE2SM, PARSE_STEREO_NAME
;
; Common      :	None.
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
; Prev. Hist. :	None.
;
; History     :	Version 1, 23-Sep-2005, William Thompson, GSFC
;               Version 2, 29-Sep-2005, William Thompson, GSFC
;                       MAG, GSM, and SM returns both position and velocity
;               Version 3, 23-Nov-2005, William Thompson, GSFC
;                       Fixed confusion between BASE and FRAME
;               Version 4, 26-Jan-2006, William Thompson, GSFC
;                       Added keyword IGNORE_ORIGIN
;               Version 5, 03-Feb-2006, William Thompson, GSFC
;                       Added keywords METERS, AU
;               Version 6, 22-Mar-2006, William Thompson, GSFC
;                       Corrected typo causing crash for certain conversions
;               Version 7, 02-May-2006, William Thompson, GSFC
;                       Added Heliocentric Ecliptic RTN (HERTN)
;               Version 8, 23-Jun-2006, William Thompson, GSFC
;                       Fixed bug when N_DATE=1, N_COORD>1
;               Version 9, 01-Sep-2006, William Thompson, GFC
;                       Added call to PARSE_STEREO_NAME
;               Version 10, 08-Aug-2008, WTT, Added GRTN coordinate system.
;               Version 11, 08-Sep-2008, WTT, Assume GEORTN when SPACECRAFT
;                       is not recognized
;               Version 12, 15-Oct-2008, WTT, support STPLN
;               Version 13, 31-Oct-2008, WTT, fixed bug with short loop variable
;               Version 14, 13-Apr-2011, WTT, Added GAE coordinates for SDO
;
; Contact     :	WTHOMPSON
;-
;
pro convert_stereo_coord, date, coord, system_from, system_to, $
                          spacecraft=spacecraft, precess=precess, $
                          errmsg=errmsg, ignore_origin=ignore_origin, $
                          meters=meters, au=au, _extra=_extra
;
;  Check the input parameters.
;
on_error, 2
if n_params() ne 4 then begin
    message = 'Syntax:  CONVERT_STEREO_COORD, DATE, COORD, FROM, TO'
    goto, handle_error
endif
;
n_date = n_elements(date)
if n_date eq 0 then begin
    message = 'DATE not defined'
    goto, handle_error
endif
;
sz = size(coord)
if sz[0] eq 0 then begin
    message = 'COORD must be an array'
    goto, handle_error
endif
;
n_vec = sz[1]
if (n_vec ne 3) and (n_vec ne 6) then begin
    message = 'First dimension of COORD must be either 3 or 6'
    goto, handle_error
endif
;
if sz[0] gt 1 then n_coord = product(sz[2:sz[0]]) else n_coord = 1
if (n_date gt 1) and (n_date ne n_coord) then begin
    message = 'Incompatible DATE and COORD arrays'
    goto, handle_error
endif
;
;  If necessary, reform the coordinate array to be two-dimensional.
;
if sz[0] gt 2 then coord = reform(coord, n_vec, n_coord, /overwrite)
;
;  Determine which spacecraft was requested, and translate it into the proper
;  input for SPICE.
;
if n_elements(spacecraft) eq 0 then sc = 'None' else $
  sc = parse_stereo_name(spacecraft, ['STEREO AHEAD', 'STEREO BEHIND'])
;
;  Convert the date/time to UTC.
;
message = ''
utc = anytim2utc(date, /ccsds, errmsg=message, _extra=_extra)
if message ne '' then goto, handle_error
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
;  Determine which coordinate systems were specified.
;
from = strupcase(system_from)
if from eq 'HEQ' then from = 'HEEQ'
if from eq strmid('CARRINGTON',0,strlen(from)) then from = 'CARRINGTON'
;
to = strupcase(system_to)
if to eq 'HEQ' then to = 'HEEQ'
if to eq strmid('CARRINGTON',0,strlen(to)) then to = 'CARRINGTON'
;
;  Determine the base systems.  If necessary, convert to BASE_FROM.
;
base_from = from
if from eq 'MAG' then begin
    message = ''
    stereo_geo2mag, utc, coord, /inverse, errmsg=message
    if message ne '' then goto, handle_error
    base_from = 'GEO'
endif
if from eq 'GSM' then begin
    message = ''
    stereo_gse2gsm, utc, coord, /inverse, errmsg=message
    if message ne '' then goto, handle_error
    base_from = 'GSE'
endif
if from eq 'SM' then begin
    message = ''
    stereo_gse2sm,  utc, coord, /inverse, errmsg=message
    if message ne '' then goto, handle_error
    base_from = 'GSE'
endif
;
;  For HGRTN, RTN, or SCI coordinates, define frame_from based on the
;  spacecraft.
;
if (from eq 'HGRTN') or (from eq 'RTN') then begin
    if (sc eq 'STEREO AHEAD') or (sc eq '-234') then begin
        frame_from = 'STAHGRTN'
    end else if (sc eq 'STEREO BEHIND') or (sc eq '-235') then begin
        frame_from = 'STBHGRTN'
    end else if (strupcase(sc) eq 'SOHO') or (sc eq '-21') then begin
        frame_from = 'SOHOHGRTN'
    end else begin
        if not !quiet then print, 'Assuming Earth observation'
        frame_from = 'GEORTN'
    endelse
endif
;
if (from eq 'SCI') then begin
    if (sc eq 'STEREO AHEAD') or (sc eq '-234') then begin
        frame_from = 'STASCPNT'
    end else if (sc eq 'STEREO BEHIND') or (sc eq '-235') then begin
        frame_from = 'STBSCPNT'
    end else begin
        message = 'Unable to recognize spacecraft specification'
        goto, handle_error
    endelse
endif
;
if (from eq 'HERTN') then begin
    if (sc eq 'STEREO AHEAD') or (sc eq '-234') then begin
        frame_from = 'STAHERTN'
    end else if (sc eq 'STEREO BEHIND') or (sc eq '-235') then begin
        frame_from = 'STBHERTN'
    end else begin
        message = 'Unable to recognize spacecraft specification'
        goto, handle_error
    endelse
endif
;
if (from eq 'STPLN') then begin
    if (sc eq 'STEREO AHEAD') or (sc eq '-234') then begin
        frame_from = 'STAPLANE'
    end else if (sc eq 'STEREO BEHIND') or (sc eq '-235') then begin
        frame_from = 'STBPLANE'
    end else begin
        message = 'Unable to recognize spacecraft specification'
        goto, handle_error
    endelse
endif
;
;  Do the same thing for the TO system.
;
base_to = to
if to eq 'MAG' then base_to = 'GEO'
if (to eq 'GSM') or (to eq 'SM') then base_to = 'GSE'
;
if (to eq 'HGRTN') or (to eq 'RTN') then begin
    if (sc eq 'STEREO AHEAD') or (sc eq '-234') then begin
        frame_to = 'STAHGRTN'
    end else if (sc eq 'STEREO BEHIND') or (sc eq '-235') then begin
        frame_to = 'STBHGRTN'
    end else if (strupcase(sc) eq 'SOHO') or (sc eq '-21') then begin
        frame_to = 'SOHOHGRTN'
    end else begin
        if not !quiet then print, 'Assuming Earth observation'
        frame_to = 'GEORTN'
    endelse
endif
;
if (to eq 'SCI') then begin
    if (sc eq 'STEREO AHEAD') or (sc eq '-234') then begin
        frame_to = 'STASCPNT'
    end else if (sc eq 'STEREO BEHIND') or (sc eq '-235') then begin
        frame_to = 'STBSCPNT'
    end else begin
        message = 'Unable to recognize spacecraft specification'
        goto, handle_error
    endelse
endif
;
if (to eq 'HERTN') then begin
    if (sc eq 'STEREO AHEAD') or (sc eq '-234') then begin
        frame_to = 'STAHERTN'
    end else if (sc eq 'STEREO BEHIND') or (sc eq '-235') then begin
        frame_to = 'STBHERTN'
    end else begin
        message = 'Unable to recognize spacecraft specification'
        goto, handle_error
    endelse
endif
;
if (to eq 'STPLN') then begin
    if (sc eq 'STEREO AHEAD') or (sc eq '-234') then begin
        frame_to = 'STAPLANE'
    end else if (sc eq 'STEREO BEHIND') or (sc eq '-235') then begin
        frame_to = 'STBPLANE'
    end else begin
        message = 'Unable to recognize spacecraft specification'
        goto, handle_error
    endelse
endif
;
;  From the base systems, determine the reference frames, and origins.
;
case strupcase(base_from) of
    'GEI': begin & frame_from = 'J2000'     & origin_from = 'Earth' & end
    'GEO': begin & frame_from = 'IAU_EARTH' & origin_from = 'Earth' & end
    'GSE': begin & frame_from = 'GSE'       & origin_from = 'Earth' & end
    'GAE': begin
        if keyword_set(precess) then frame_from = 'ECLIPDATE' else $
          frame_from = 'ECLIPJ2000'
        origin_from = 'Earth'
        end
    'HCI': begin & frame_from = 'HCI'       & origin_from = 'Sun'   & end
    'HAE': begin
        if keyword_set(precess) then frame_from = 'ECLIPDATE' else $
          frame_from = 'ECLIPJ2000'
        origin_from = 'Sun'
        end
    'HEE': begin & frame_from = 'HEE'       & origin_from = 'Sun'   & end
    'HEEQ': begin& frame_from = 'HEEQ'      & origin_from = 'Sun'   & end
    'CARRINGTON': begin & frame_from = 'IAU_SUN' & origin_from = 'Sun' & end
    'HGRTN': origin_from = 'Sun'
    'RTN': origin_from = sc
    'GRTN': begin & frame_from = 'GEORTN'   & origin_from = 'Earth' & end
    'SCI': origin_from = sc
    'HERTN': origin_from = 'Sun'
    'STPLN': origin_from = 'Sun'
    else: begin
        message = 'Unrecognized coordinate system'
        goto, handle_error
    endelse
endcase
;
case strupcase(base_to) of
    'GEI': begin & frame_to = 'J2000'     & origin_to = 'Earth' & end
    'GEO': begin & frame_to = 'IAU_EARTH' & origin_to = 'Earth' & end
    'GSE': begin & frame_to = 'GSE'       & origin_to = 'Earth' & end
    'GAE': begin
        if keyword_set(precess) then frame_to = 'ECLIPDATE' else $
          frame_to = 'ECLIPJ2000'
        origin_to = 'Earth'
        end
    'HCI': begin & frame_to = 'HCI'       & origin_to = 'Sun'   & end
    'HAE': begin
        if keyword_set(precess) then frame_to = 'ECLIPDATE' else $
          frame_to = 'ECLIPJ2000'
        origin_to = 'Sun'
        end
    'HEE': begin & frame_to = 'HEE'       & origin_to = 'Sun'   & end
    'HEEQ': begin& frame_to = 'HEEQ'      & origin_to = 'Sun'   & end
    'CARRINGTON': begin & frame_to = 'IAU_SUN' & origin_to = 'Sun' & end
    'HGRTN': origin_to = 'Sun'
    'RTN': origin_to = sc
    'GRTN': begin & frame_to = 'GEORTN'   & origin_to = 'Earth' & end
    'SCI': origin_to = sc
    'HERTN': origin_to = 'Sun'
    'STPLN': origin_to = 'Sun'
    else: begin
        message = 'Unrecognized coordinate system'
        goto, handle_error
    endelse
endcase
;
;  If the FROM and TO origins are different, first do an origin conversion.
;
if (origin_from ne origin_to) and (not keyword_set(ignore_origin)) then begin
    cspice_spkezr, origin_to, et, frame_from, 'None', origin_from, origin, $
      ltime
    if n_vec eq 3 then origin = origin[0:2,*,*,*,*,*,*,*]
    if (n_date eq 1) and (n_coord gt 1) then $
      origin = origin # replicate(1, n_coord)
    if keyword_set(meters) then origin = origin*1000 else $
      if keyword_set(au) then origin = origin / 1.4959787D8
    coord = coord - origin
endif
;
;  Calculate the transformation matrix, and apply it to the data.
;
case n_vec of
    3: cspice_pxform, frame_from, frame_to, et, xform
    6: cspice_sxform, frame_from, frame_to, et, xform
endcase
if n_date eq 1 then coord = transpose(xform) # coord else $
  for i = 0L,n_coord-1 do coord[*,i] = transpose(xform[*,*,i]) # coord[*,i]
;
;  If necessary, convert from BASE_TO to TO.
;
message = ''
if to eq 'MAG' then stereo_geo2mag, utc, coord, errmsg=message
if to eq 'GSM' then stereo_gse2gsm, utc, coord, errmsg=message
if to eq 'SM'  then stereo_gse2sm,  utc, coord, errmsg=message
if message ne '' then goto, handle_error
;
;  If necessary, restore COORD to its original dimensions.
;
if sz[0] gt 2 then coord = reform(coord, [n_vec,sz[2:sz[0]]], /overwrite)
return
;
;  Error handling point.
;
handle_error:
if n_elements(errmsg) eq 0 then message, message else $
  errmsg = 'convert_stereo_coord: ' + message
;
end
