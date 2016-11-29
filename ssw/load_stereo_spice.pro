;+
; Project     :	STEREO - SSC
;
; Name        :	LOAD_STEREO_SPICE
;
; Purpose     :	Load the STEREO SPICE ephemeris and attitude kernels
;
; Category    :	STEREO, Orbit
;
; Explanation :	Loads the STEREO ephemeris and attitude history files in
;               SPICE format.  Also calls LOAD_STEREO_SPICE_GEN to load the
;               supporting kernels.
;
;               The kernel file names are read from the following text files in
;               the directory $STEREO_SPICE
;
;                       definitive_ephemerides_ahead.dat
;                       definitive_ephemerides_behind.dat
;                       ephemerides_ahead.dat
;                       ephemerides_behind.dat
;                       attitude_history_ahead.dat
;                       attitude_history_behind.dat
;
;               which will be regularly updated as new ephemeris or attitude
;               history files become available.
;
;               Attitude history files are not loaded by this routine.
;               Instead, the names of the kernel files are stored for "on
;               demand" loading by LOAD_STEREO_SPICE_ATT.
;
; Syntax      :	LOAD_STEREO_SPICE
;
; Inputs      :	None.
;
; Opt. Inputs :	None.
;
; Outputs     :	None.
;
; Opt. Outputs:	None.
;
; Keywords    :	RELOAD = If set, then unload the current ephemeris files, and
;                        redetermine which kernels to load.  The default is to
;                        not reload already loaded kernels.
;
;               KERNELS= A string array of SPICE kernels to load, instead of
;                        those listed in the text data files described above,
;                        e.g.
;
;                               LOAD_STEREO_SPICE, KERNELS='myfile.bsp'
;
;                        or
;
;                               LOAD_STEREO_SPICE, KERNELS=[file1,file2,...]
;
;                        Use of the KERNELS keyword implies /RELOAD.
;
;               VERBOSE= If set, then print a message for each file loaded.
;
;               SIM1   = If set, then load the ephemeris and attitude files
;                        from Mission Simulation #1.  The data are based on the
;                        earlier Feb 11th launch data, and are valid from
;                        2006-MAR-11 10:03 to 15:31 for the Ahead spacecraft
;                        only.  Use of /SIM1 implies /RELOAD.
;
;               SIM2   = If set, then load the ephemeris and attitude files
;                        from Mission Simulation #2.  The data are based on a
;                        launch date of April 11th, and are valid for the
;                        following dates:
;
;                               Ahead:  2006-APR-15 12:03 to 20:00
;                                       2006-APR-29 12:02 to 15:59
;                                       2006-JUL-24 12:02 to 23:25
;
;                               Behind: 2006-APR-15 12:02 to 22:51
;                                       2006-APR-29 12:06 to 18:40
;                                       2006-JUN-22 13:51 to 20:16
;
;                        Use of /SIM2 implies /RELOAD.
;
;               SIM3   = If set, then load the ephemeris and attitude history
;                        files from Mission Simulation #3.  The data are based
;                        on a launch date of May 26th, and are valid from
;                        2006-Oct-02 00:00 to 2007-02-13 00:00.  Use of /SIM3
;                        implies /RELOAD.
;
;               NOMINAL_CK = If set (default), and no attitude history files
;                        have been loaded, then load some nominal files to
;                        allow GET_STEREO_CMAT to calculate theoretical
;                        C-matrices based on orbital position.  The nominal CK
;                        files are taken from the April 15th data from Sim #2.
;
;               ERRMSG = If defined and passed, then any error messages will be
;                        returned to the user in this parameter rather than
;                        depending on the MESSAGE routine in IDL.  If no errors
;                        are encountered, then a null string is returned.  In
;                        order to use this feature, ERRMSG must be defined
;                        first, e.g.
;
;                               ERRMSG = ''
;                               LOAD_STEREO_SPICE, ERRMSG=ERRMSG
;                               IF ERRMSG NE '' THEN ...
;
; Calls       :	CONCAT_DIR, CSPICE_FURNSH, FILE_EXIST, UNLOAD_STEREO_SPICE,
;               LOAD_STEREO_SPICE_GEN, TEST_SPICE_ICY_DLM
;
; Common      :	STEREO_SPICE contains the names of the loaded files, for
;               use by UNLOAD_STEREO_SPICE.
;
;               STEREO_SPICE_CONIC contains data used to extrapolate the Ahead
;               and Behind ephemerides beyond their end date.
;
; Env. Vars.  : Uses the environment variables STEREO_SPICE,
;               STEREO_SPICE_EPHEM, STEREO_SPICE_DEF_EPHEM,
;               STEREO_SPICE_ATTITUDE, and STEREO_SPICE_ATTIT_SM
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
; Side effects:	None.
;
; Prev. Hist. :	None.
;
; History     :	Version 1, 25-Aug-2005, William Thompson, GSFC
;               Version 2, 29-Aug-2005, William Thompson, GSFC
;                       Added keyword /RELOAD.  Previously always reloaded.
;                       Added keyword KERNELS.
;               Version 3, 16-Sep-2005, William Thompson, GSFC
;                       Added call to TEST_SPICE_ICY_DLM
;               Version 4, 17-Sep-2005, William Thompson, GSFC
;                       Added keyword /SIM2
;               Version 5, 21-Feb-2006, William Thompson, GSFC
;                       Correct order of epm and depm files.
;                       Added keyword /SIM3
;               Version 6, 14-Mar-2006, William Thompson, GSFC
;                       Added keyword /NOMINAL_CK
;               Version 7, 22-Mar-2006, William Thompson, GSFC
;                       Store conic parameters in STEREO_SPICE_CONIC
;               Version 8, 25-Apr-2006, William Thompson, GSFC
;                       Make /NOMINAL_CK the default
;               Version 9, 05-Jul-2006, William Thompson, GSFC
;                       Look for both full and reduced-resolution attitude
;                       history files.
;               Version 10, 24-Jul-2007, William Thompson, GSFC
;                       Don't load Attitude History files
;               Version 11, 13-Sep-2011, WTT, better MU value
;
; Contact     :	WTHOMPSON
;-
;
pro load_stereo_spice, reload=k_reload, sim1=sim1, sim2=sim2, sim3=sim3, $
                       verbose=verbose, kernels=kernels, $
                       nominal_ck=k_nominal_ck, errmsg=errmsg
common stereo_spice, def_ephem, ephem, attitude, att_sc, att_mjd, att_loaded
common stereo_spice_conic, mu, maxdate, conic
on_error, 2
;
;  Make sure that the SPICE/Icy DLM is available.
;
if not test_spice_icy_dlm() then begin
    message = 'SPICE/Icy DLM not available'
    goto, handle_error
endif
;
;  Using the KERNELS keyword implies /RELOAD.
;
reload = keyword_set(k_reload) or (n_elements(kernels) gt 0) or $
  keyword_set(sim1) or keyword_set(sim2) or keyword_set(sim3)
;
;  If the /RELOAD keyword wasn't passed, then check to see if the kernels have
;  already been loaded.
;
n_kernels = n_elements(def_ephem) + n_elements(ephem)
if (not keyword_set(reload)) and (n_kernels gt 0) then return
;
;  Start by unloading any ephemerides which were previously loaded, and then
;  loading the generic kernels.
;
unload_stereo_spice, verbose=verbose
message = ''
load_stereo_spice_gen, verbose=verbose
if message ne '' then goto, handle_error
;
;  If the KERNELS keyword was passed, then load those kernels and return.
;
if n_elements(kernels) gt 0 then begin
    for i=0,n_elements(kernels)-1 do begin
        file = kernels[i]
        if file_exist(file) then begin
            cspice_furnsh, file
            if keyword_set(verbose) then print, 'Loaded ' + file
            if n_elements(ephem) eq 0 then ephem = file else $
              ephem = [ephem, file]
        endif
    endfor
    return
endif
;
;  Initialize the conic parameters.
;
if n_elements(mu) eq 0 then mu = 1.32712440018D11   ;G*Msun km^3/s^2
maxdate = replicate('', 2)
conic = dblarr(8,2)
;
;  Load the (predictive) ephemerides.
;
stereo_spice = getenv('STEREO_SPICE')
stereo_spice_ephem_ahead  = concat_dir('STEREO_SPICE_EPHEM','ahead')
stereo_spice_ephem_behind = concat_dir('STEREO_SPICE_EPHEM','behind')
;
;  Ahead.
;
file = concat_dir(stereo_spice, 'ephemerides_ahead.dat')
if keyword_set(sim1) then file = $
  concat_dir(stereo_spice, 'ephemerides_ahead_sim1.dat')
if keyword_set(sim2) then file = $
  concat_dir(stereo_spice, 'ephemerides_ahead_sim2.dat')
if keyword_set(sim3) then file = $
  concat_dir(stereo_spice, 'ephemerides_ahead_sim3.dat')
if file_exist(file) then begin
    openr, unit, file, /get_lun
    while not eof(unit) do begin
        line = 'String'
        readf, unit, line
        line = strtrim(line,2)
        if (line ne '') and (strmid(line,0,1) ne '#') then begin
            file = concat_dir(stereo_spice_ephem_ahead, line)
            if not file_exist(file) then begin
                message = 'Unable to open file ' + file
                goto, handle_error
            endif
            cspice_furnsh, file
            if keyword_set(verbose) then print, 'Loaded ' + file
            if n_elements(ephem) eq 0 then ephem = file else $
              ephem = [ephem, file]
;
;  Extract the orbital parameters, and store in the file.
;
            get_stereo_spice_range, file , date0, date1, /ccsds
            if date1 gt maxdate[0] then begin
                maxdate[0] = date1
                state = get_stereo_coord(date1, 'Ahead', system='HAE')
                cspice_utc2et, date1, et
                cspice_oscelt, state, et, mu, elts
                conic[*,0] = elts
            endif
        endif
    endwhile
    free_lun, unit
endif
;
;  Behind.
;
file = concat_dir(stereo_spice, 'ephemerides_behind.dat')
if keyword_set(sim1) then file = $
  concat_dir(stereo_spice, 'ephemerides_behind_sim1.dat')
if keyword_set(sim2) then file = $
  concat_dir(stereo_spice, 'ephemerides_behind_sim2.dat')
if keyword_set(sim3) then file = $
  concat_dir(stereo_spice, 'ephemerides_behind_sim3.dat')
if file_exist(file) then begin
    openr, unit, file, /get_lun
    while not eof(unit) do begin
        line = 'String'
        readf, unit, line
        line = strtrim(line,2)
        if (line ne '') and (strmid(line,0,1) ne '#') then begin
            file = concat_dir(stereo_spice_ephem_behind, line)
            if not file_exist(file) then begin
                message = 'Unable to open file ' + file
                goto, handle_error
            endif
            cspice_furnsh, file
            if keyword_set(verbose) then print, 'Loaded ' + file
            if n_elements(ephem) eq 0 then ephem = file else $
              ephem = [ephem, file]
;
;  Extract the orbital parameters, and store in the file.
;
            get_stereo_spice_range, file , date0, date1, /ccsds
            if date1 gt maxdate[1] then begin
                maxdate[1] = date1
                state = get_stereo_coord(date1, 'Behind', system='HAE')
                cspice_utc2et, date1, et
                cspice_oscelt, state, et, mu, elts
                conic[*,1] = elts
            endif
        endif
    endwhile
    free_lun, unit
endif
;
;  Next, load the definitive ephemerides.
;
stereo_spice_def_ephem_ahead  = concat_dir('STEREO_SPICE_DEF_EPHEM','ahead')
stereo_spice_def_ephem_behind = concat_dir('STEREO_SPICE_DEF_EPHEM','behind')
;
;  Ahead.
;
file = concat_dir(stereo_spice, 'definitive_ephemerides_ahead.dat')
if keyword_set(sim1) then file = $
  concat_dir(stereo_spice, 'definitive_ephemerides_ahead_sim1.dat')
if keyword_set(sim2) then file = $
  concat_dir(stereo_spice, 'definitive_ephemerides_ahead_sim2.dat')
if keyword_set(sim3) then file = $
  concat_dir(stereo_spice, 'definitive_ephemerides_ahead_sim3.dat')
if file_exist(file) then begin
    openr, unit, file, /get_lun
    while not eof(unit) do begin
        line = 'String'
        readf, unit, line
        line = strtrim(line,2)
        if (line ne '') and (strmid(line,0,1) ne '#') then begin
            file = concat_dir(stereo_spice_def_ephem_ahead, line)
            if not file_exist(file) then begin
                message = 'Unable to open file ' + file
                goto, handle_error
            endif
            cspice_furnsh, file
            if keyword_set(verbose) then print, 'Loaded ' + file
            if n_elements(def_ephem) eq 0 then def_ephem = file else $
              def_ephem = [def_ephem, file]
;
;  Extract the orbital parameters, and store in the file.
;
            get_stereo_spice_range, file , date0, date1, /ccsds
            if date1 gt maxdate[0] then begin
                maxdate[0] = date1
                state = get_stereo_coord(date1, 'Ahead', system='HAE')
                cspice_utc2et, date1, et
                cspice_oscelt, state, et, mu, elts
                conic[*,0] = elts
            endif
        endif
    endwhile
    free_lun, unit
endif
;
;  Behind.
;
file = concat_dir(stereo_spice, 'definitive_ephemerides_behind.dat')
if keyword_set(sim1) then file = $
  concat_dir(stereo_spice, 'definitive_ephemerides_behind_sim1.dat')
if keyword_set(sim2) then file = $
  concat_dir(stereo_spice, 'definitive_ephemerides_behind_sim2.dat')
if keyword_set(sim3) then file = $
  concat_dir(stereo_spice, 'definitive_ephemerides_behind_sim3.dat')
if file_exist(file) then begin
    openr, unit, file, /get_lun
    while not eof(unit) do begin
        line = 'String'
        readf, unit, line
        line = strtrim(line,2)
        if (line ne '') and (strmid(line,0,1) ne '#') then begin
            file = concat_dir(stereo_spice_def_ephem_behind, line)
            if not file_exist(file) then begin
                message = 'Unable to open file ' + file
                goto, handle_error
            endif
            cspice_furnsh, file
            if keyword_set(verbose) then print, 'Loaded ' + file
            if n_elements(def_ephem) eq 0 then def_ephem = file else $
              def_ephem = [def_ephem, file]
;
;  Extract the orbital parameters, and store in the file.
;
            get_stereo_spice_range, file , date0, date1, /ccsds
            if date1 gt maxdate[1] then begin
                maxdate[1] = date1
                state = get_stereo_coord(date1, 'Behind', system='HAE')
                cspice_utc2et, date1, et
                cspice_oscelt, state, et, mu, elts
                conic[*,1] = elts
            endif
        endif
    endwhile
    free_lun, unit
endif
;
;  Finally, load the attitude histories.  The _SM directories contain reduced
;  resolution files.
;
stereo_spice_attitude_ahead  = concat_dir('STEREO_SPICE_ATTITUDE','ahead')
stereo_spice_attitude_behind = concat_dir('STEREO_SPICE_ATTITUDE','behind')
stereo_spice_attit_sm_ahead  = concat_dir('STEREO_SPICE_ATTIT_SM','ahead')
stereo_spice_attit_sm_behind = concat_dir('STEREO_SPICE_ATTIT_SM','behind')
;
;  Ahead.
;
file = concat_dir(stereo_spice, 'attitude_history_ahead.dat')
if keyword_set(sim1) then file = $
  concat_dir(stereo_spice, 'attitude_history_ahead_sim1.dat')
if keyword_set(sim2) then file = $
  concat_dir(stereo_spice, 'attitude_history_ahead_sim2.dat')
if keyword_set(sim3) then file = $
  concat_dir(stereo_spice, 'attitude_history_ahead_sim3.dat')
if file_exist(file) then begin
    openr, unit, file, /get_lun
    while not eof(unit) do begin
        line = 'String'
        readf, unit, line
        line = strtrim(line,2)
        if (line ne '') and (strmid(line,0,1) ne '#') then begin
            file = concat_dir(stereo_spice_attitude_ahead, line)
;
;  If we can't find the full-resolution attitude history file, try looking for
;  the reduced resolution file.
;
            if not file_exist(file) then begin
                file = concat_dir(stereo_spice_attit_sm_ahead, line)
                if not file_exist(file) then begin
                    file = strmid(line,0,strlen(line)-6) + '_sm.ah.bc'
                    file = concat_dir(stereo_spice_attit_sm_ahead, file)
                    if not file_exist(file) then begin
                        print, 'Unable to open file ' + line
                        file = ''
                    endif
                endif
            endif
            if file ne '' then begin
                u0 = strpos(line, '_')
                date = strmid(line, u0+1, 8)
                strput, date, '-', 4
                date = str2utc(date)
                if n_elements(attitude) eq 0 then begin
                    attitude = file
                    att_sc   = '-234'
                    att_mjd  = date.mjd
                end else begin
                    attitude = [attitude, file]
                    att_sc   = [att_sc,   '-234']
                    att_mjd  = [att_mjd,  date.mjd]
                endelse
            endif
        endif
    endwhile
    free_lun, unit
endif
;
;  Behind.
;
file = concat_dir(stereo_spice, 'attitude_history_behind.dat')
if keyword_set(sim1) then file = $
  concat_dir(stereo_spice, 'attitude_history_behind_sim1.dat')
if keyword_set(sim2) then file = $
  concat_dir(stereo_spice, 'attitude_history_behind_sim2.dat')
if keyword_set(sim3) then file = $
  concat_dir(stereo_spice, 'attitude_history_behind_sim3.dat')
if file_exist(file) then begin
    openr, unit, file, /get_lun
    while not eof(unit) do begin
        line = 'String'
        readf, unit, line
        line = strtrim(line,2)
        if (line ne '') and (strmid(line,0,1) ne '#') then begin
            file = concat_dir(stereo_spice_attitude_behind, line)
;
;  If we can't find the full-resolution attitude history file, try looking for
;  the reduced resolution file.
;
            if not file_exist(file) then begin
                file = concat_dir(stereo_spice_attit_sm_behind, line)
                if not file_exist(file) then begin
                    file = strmid(line,0,strlen(line)-6) + '_sm.ah.bc'
                    file = concat_dir(stereo_spice_attit_sm_behind, file)
                    if not file_exist(file) then begin
                        print, 'Unable to open file ' + line
                        file = ''
                    endif
                endif
            endif
            if file ne '' then begin
                u0 = strpos(line, '_')
                date = strmid(line, u0+1, 8)
                strput, date, '-', 4
                date = str2utc(date)
                if n_elements(attitude) eq 0 then begin
                    attitude = file
                    att_sc   = '-235'
                    att_mjd  = date.mjd
                end else begin
                    attitude = [attitude, file]
                    att_sc   = [att_sc,   '-235']
                    att_mjd  = [att_mjd,  date.mjd]
                endelse
            endif
        endif
    endwhile
    free_lun, unit
endif
;
;  If requested, then load the nominal attitude history files.
;
if n_elements(nominal_ck) eq 0 then nominal_ck = 1
if keyword_set(nominal_ck) and n_elements(attitude) eq 0 then begin
    file = concat_dir(stereo_spice_attitude_ahead,'ahead_nominal.ah.bc')
    if not file_exist(file) then file = $
      concat_dir(stereo_spice_attit_sm_ahead,'ahead_nominal.ah.bc')
    attitude = file
    att_sc   = '-234'
    att_mjd  = 0
    file = concat_dir(stereo_spice_attitude_behind,'behind_nominal.ah.bc')
    if not file_exist(file) then file = $
      concat_dir(stereo_spice_attit_sm_behind,'behind_nominal.ah.bc')
    attitude = [attitude, file]
    att_sc   = [att_sc,   '-235']
    att_mjd  = [att_mjd,  0]
endif
;
;  Initialize the ATT_LOADED array.
;
att_loaded = bytarr(n_elements(attitude)) 
;
return
;
;  Error handling point.
;
handle_error:
if n_elements(errmsg) eq 0 then message, message else $
  errmsg = 'load_stereo_spice: ' + message
;
end
