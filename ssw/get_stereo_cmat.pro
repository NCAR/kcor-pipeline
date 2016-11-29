;+
; Project     :	STEREO - SSC
;
; Name        :	GET_STEREO_CMAT
;
; Purpose     :	Returns the pointing C-matrix of STEREO A or B
;
; Category    :	STEREO, Orbit
;
; Explanation :	This routine returns the orientation C-matrix of one of the two
;               STEREO spacecraft in a wide variety of coordinate systems.
;
; Syntax      :	Cmat = GET_STEREO_CMAT( DATE, SPACECRAFT )
;
; Examples    :	Cmat = GET_STEREO_CMAT( '2006-05-06T11:30:00', 'A' )
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
; Opt. Inputs :	None.
;
; Outputs     : The result of the function is the 3x3 transformation matrix,
;               which converts a vector from the specified reference frame to
;               the spacecraft/instrument reference frame.  This can be applied
;               to coordinate 3-vectors via one of the following commands:
;
;                     vec_inst = cmat ## vec_ref              ;; column vector
;                        or
;                     vec_inst = transpose(cmat) # vec_ref    ;; row vector
;                        or
;                     cspice_mxv, cmat, vec_ref, vec_inst     ;; row vector
;
;               Alternatively, to convert from the spacecraft/instrument
;               reference frame to the specified reference frame, use one of
;               the following commands:
;
;                     vec_ref = transpose(cmat) ## vec_inst   ;; column vector
;                        or
;                     vec_ref = cmat # vec_inst               ;; row vector
;                        or
;                     cspice_mxv, transpose(cmat), vec_inst, vec_ref
;                                                             ;; row vector
;
;               If DATE is a vector, then the result will have additional
;               dimensions.
;
; Opt. Outputs:	None.
;
; Keywords    : SIX_VECTOR = If set, then CMAT is returned as a 6x6 matrix,
;                            which can be applied to 6-vectors with both
;                            position and velocity information.
;
;               INSTRUMENT = The name of a STEREO instrument or sub-instrument
;                            with a defined reference frame.  This capability
;                            is not yet implemented--this keyword is included
;                            as a placeholder for when it is.
;
;                            The default is to return the C-matrix for the
;                            spacecraft as a whole, rather than for any
;                            specific instrument.
;
;               SYSTEM = Character string, giving one of the following
;                        standard coordinate systems:
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
;                               HGRTN   Heliocentric Radial-Tangential-Normal
;                               RTN     Radial-Tangential-Normal (default)
;                               HPC     Helioprojective-Cartesian
;                               SCI     STEREO Science Pointing
;                               HERTN   Heliocentric Ecliptic RTN
;                               STPLN   STEREO Mission Plane
;
;                        Case is not important.
;
;               PRECESS = If set, then ecliptic coordinates are precessed from
;                         the J2000 reference frame to the mean ecliptic of
;                         date.  Only used for HAE/GAE.  Default is PRECESS=0.
;                         GSE and HEE use the ecliptic of date by definition.
;
;               TOLERANCE = The tolerance to be used when looking for pointing
;                            information, in seconds.  The default is 1000.
;
;               FOUND  = Byte array containing whether or not the pointings
;                        were found.
;
;               NOMINAL= If this keyword is set, the attitude history files are
;                        bypassed, and a nominal pointing is calculated from
;                        the ephemerides.
;
;               ERRMSG = If defined and passed, then any error messages will be
;                        returned to the user in this parameter rather than
;                        depending on the MESSAGE routine in IDL.  If no errors
;                        are encountered, then a null string is returned.  In
;                        order to use this feature, ERRMSG must be defined
;                        first, e.g.
;
;                               ERRMSG = ''
;                               Cmat = GET_STEREO_CMAT( ERRMSG=ERRMSG, ... )
;                               IF ERRMSG NE '' THEN ...
;
;               Will also accept any LOAD_STEREO_SPICE or ANYTIM2UTC keywords.
;
; Calls       :	ANYTIM2UTC, CONCAT_DIR, CSPICE_STR2ET, CSPICE_SCE2C,
;               CSPICE_CKGP, LOAD_STEREO_SPICE, PARSE_STEREO_NAME
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
; Prev. Hist. :	Based on STEREO_POINTING_DEMO
;
; History     :	Version 1, 29-Aug-2005, William Thompson, GSFC
;               Version 2, 30-Aug-2005, William Thompson, GSFC
;                       Changed default from HCI to RTN
;               Version 3, 12-Sep-2005, William Thompson, GSFC
;                       Accept ANYTIM2UTC keywords
;               Version 4, 22-Sep-2005, William Thompson, GSFC
;                       Added MAG, GSM, and SM coordinates
;               Version 5, 18-Oct-2005, William Thompson, GSFC
;                       Added keyword SIX_VECTOR, SYSTEM='HPC'
;               Version 6, 14-Mar-2006, William Thompson, GSFC
;                       Return predicted pointing when not found.
;               Version 7, 02-May-2006, William Thompson, GSFC
;                       Added Heliocentric Ecliptic RTN (HERTN)
;                       and STEREO Mission Plane (STPLN)
;               Version 8, 01-Sep-2006, William Thompson, GSFC
;                       Added call to PARSE_STEREO_NAME
;               Version 9, 01-Nov-2006, William Thompson, GSFC
;                       Increased tolerance to 1000 seconds.
;               Version 10, 12-Jan-2007, WTT, added keyword nominal
;               Version 11, 24-Jul-2007, WTT, call LOAD_STEREO_SPICE_ATT
;               Version 12, 13-Apr-2011, WTT, Added GAE coordinates for SDO
;
; Contact     :	WTHOMPSON
;-
;
function get_stereo_cmat, date, spacecraft, system=k_system, found=found, $
                          precess=precess, instrument=instrument, $
                          tolerance=tolerance, six_vector=six_vector, $
                          nominal=nominal, errmsg=errmsg, _extra=_extra
;
on_error, 2
if n_params() ne 2 then begin
    message = 'Syntax:  Cmat = GET_STEREO_CMAT( DATE, SPACECRAFT )'
    goto, handle_error
endif
;
;  Determine which spacecraft was requested, and translate it into the proper
;  input for SPICE.
;
inst = 0L
if datatype(spacecraft,1) eq 'String' then $
  sc = parse_stereo_name(spacecraft, ['-234', '-235']) else $
  sc = spacecraft
;
if (sc ne -234) and (sc ne -235) then begin
    message = 'Unable to recognize spacecraft ' + strtrim(sc,2)
    goto, handle_error
endif
;
;  From the spacecraft code, determine the default instrument code.
;
sc = long(sc)
inst = sc*1000L
;
;  Modify the instrument code based on the specific sub-instrument.
;
if n_elements(instrument) ne 0 then print, $
  'INSTRUMENT keyword not yet implemented'
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
load_stereo_spice_att, sc, utc, _extra=_extra
;
;  Determine which coordinate system was specified.
;
if n_elements(k_system) eq 1 then system=strupcase(k_system) else system='RTN'
if system eq 'HEQ' then system = 'HEEQ'
if system eq strmid('CARRINGTON',0,strlen(system)) then system = 'CARRINGTON'
;
if (system eq 'HGRTN') or (system eq 'RTN') or (system eq 'HPC') then begin
    if sc eq -234 then frame = 'STAHGRTN' else frame = 'STBHGRTN'
endif
;
if (system eq 'SCI') then begin
    if sc eq -234 then frame = 'STASCPNT' else frame = 'STBSCPNT'
endif
;
if (system eq 'HERTN') then begin
    if sc eq -234 then frame = 'STAHERTN' else frame = 'STBHERTN'
endif
;
if (system eq 'STPLN') then begin
    if sc eq -234 then frame = 'STAPLANE' else frame = 'STBPLANE'
endif
;
;  Determine the tolerance to be used when looking for the pointing
;  information.
;
if n_elements(tolerance) eq 1 then tol = tolerance else tol = 1000
;
;  Convert the date/time to ephemeris time, and then to spacecraft clock double
;  precision time.
;
cspice_str2et, utc, et
n = n_elements(et)
sz = size(et)
if keyword_set(six_vector) then n_vec=6 else n_vec=3
if sz[0] eq 0 then dim=[n_vec,n_vec] else dim=[n_vec,n_vec,sz[1:sz[0]]]
cmat = make_array(dimension=[n_vec,n_vec,n],/double)
found = bytarr(n)
for i=0L,n-1L do begin
    cspice_sce2c, sc, et[i], sclkdp
;
;  Based on the coordinate system requested, get the transformation matrix.
;
    case system of
        'GEI': frame = 'J2000'
        'GEO': frame = 'IAU_EARTH'
        'MAG': frame = 'IAU_EARTH'
        'GSE': frame = 'GSE'
        'GSM': frame = 'GSE'
        'SM':  frame = 'GSE'
        'GAE': if keyword_set(precess) then frame='ECLIPDATE' else $
          frame='ECLIPJ2000'
        'HCI': frame = 'HCI'
        'HAE': if keyword_set(precess) then frame='ECLIPDATE' else $
          frame='ECLIPJ2000'
        'HEE': frame = 'HEE'
        'HEEQ': frame = 'HEEQ'
        'CARRINGTON': frame = 'IAU_SUN'
        'HGRTN': frame = frame
        'RTN': frame = frame
        'HPC': frame = frame
        'SCI': frame = frame
        'HERTN': frame = frame
        'STPLN': frame = frame
        else: begin
            message = 'Unrecognized coordinate system'
            goto, handle_error
        endelse
    endcase
    if keyword_set(nominal) then ffound=0 else $
      cspice_ckgp,inst,sclkdp,tol,frame,ccmat,clkout,ffound
;
;  If the C-matrix was not found, then calculate a predicted C-matrix.
;
    if not ffound then begin
        ccmat = [[1.d0, 0, 0], [0, 1.d0, 0], [0, 0, 1.d0]]
        if system ne 'SCI' then begin
            if sc eq -234 then frame_from = 'STASCPNT' else $
              frame_from = 'STBSCPNT'
            cspice_pxform, frame_from, frame, et[i], xform
            ccmat = transpose(xform) # ccmat
        endif
    endif
;
;  Apply any additional processing.
;
    case system of
        'MAG': stereo_geo2mag, utc[i], ccmat, /cmat
        'GSM': stereo_gse2gsm, utc[i], ccmat, /cmat
        'SM': stereo_gse2sm, utc[i], ccmat, /cmat
        'HPC': ccmat = ccmat ## [[0, 0, 1d0], [1.d0, 0, 0], [0, 1.d0, 0]]
        else:
    endcase
;
;  Store the C-matrix and the found state in the output arrays.
;
    cmat[0:2,0:2,i] = ccmat
    if keyword_set(six_vector) then cmat[3:5,3:5,i] = ccmat
    found[i] = ffound
endfor
;
;  Reformat the output arrays to match the input date/time array.
;
if n eq 1 then begin
    cmat = reform(cmat, /overwrite)
    found = found[0]
end else begin
    cmat = reform(cmat, dim, /overwrite)
    found = reform(found, dim[2:*], /overwrite)
endelse
;
return, cmat
;
;  Error handling point.
;
handle_error:
if n_elements(errmsg) eq 0 then message, message else $
  errmsg = 'get_stereo_cmat: ' + message
;
end
