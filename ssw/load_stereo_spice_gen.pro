;+
; Project     :	STEREO - SSC
;
; Name        :	LOAD_STEREO_SPICE_GEN
;
; Purpose     :	Load the general STEREO SPICE kernels
;
; Category    :	STEREO, Orbit
;
; Explanation :	Loads the general SPICE kernels needed to process STEREO
;               ephemerides and attitude history files.  This procedure seeks
;               out and loads the following files from the SolarSoft tree:
;
;                   * A leapseconds file                (e.g. naif0007.tls)
;                   * A solar system ephemeris          (e.g. de405.bsp)
;                   * A planetary constants file        (e.g. pck00008.tpc)
;                   * The frame files heliospheric.tf and stereo_rtn.tf
;                   * The spacecraft clock files
;
; Syntax      :	LOAD_STEREO_SPICE_GEN
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
;               VERBOSE= If set, then print a message for each file loaded.
;
;               ERRMSG = If defined and passed, then any error messages will be
;                        returned to the user in this parameter rather than
;                        depending on the MESSAGE routine in IDL.  If no errors
;                        are encountered, then a null string is returned.  In
;                        order to use this feature, ERRMSG must be defined
;                        first, e.g.
;
;                               ERRMSG = ''
;                               LOAD_STEREO_SPICE_GEN, ERRMSG=ERRMSG
;                               IF ERRMSG NE '' THEN ...
;
; Calls       :	CONCAT_DIR, CSPICE_FURNSH, UNLOAD_STEREO_SPICE_GEN,
;               TEST_SPICE_ICY_DLM
;
; Common      :	STEREO_SPICE_GEN contains the names of the loaded files, for
;               use by UNLOAD_STEREO_SPICE_GEN.
;
; Env. Vars.  : Uses the environment variables STEREO_SPICE_SCLK for the
;               spacecraft clock kernels, and STEREO_SPICE_GEN for the other
;               general kernels.
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
; History     :	Version 1, 17-Jun-2005, William Thompson, GSFC
;               Version 2, 24-Aug-2005, William Thompson, GSFC
;                       Use FILE_SEARCH instead of FINDFILE, fix bug with COUNT
;               Version 3, 25-Aug-2005, William Thompson, GSFC
;                       Start by calling unload_stereo_spice_gen
;               Version 4, 29-Aug-2005, William Thompson, GSFC
;                       Added keyword /RELOAD.  Previously always reloaded.
;               Version 5, 16-Sep-2005, William Thompson, GSFC
;                       Added call to TEST_SPICE_ICY_DLM
;               Version 6, 28-Oct-2005, William Thompson, GSFC
;                       Use dos subdirectories for gen and sclk files
;
; Contact     :	WTHOMPSON
;-
;
pro load_stereo_spice_gen, reload=reload, verbose=verbose, errmsg=errmsg
common stereo_spice_gen, leapsec, solarsys, planet_const, frames, clocks
on_error, 2
;
;  Make sure that the SPICE/Icy DLM is available.
;
if not test_spice_icy_dlm() then begin
    message = 'SPICE/Icy DLM not available'
    goto, handle_error
endif
;
;  If the /RELOAD keyword wasn't passed, then check to see if the kernels have
;  already been loaded.
;
if (not keyword_set(reload)) and (n_elements(leapsec) gt 0) and $
  (n_elements(solarsys) gt 0) and (n_elements(planet_const) gt 0) and $
  (n_elements(frames) gt 0) and (n_elements(clocks) gt 0) then return
;
;  Start by unloading any kernels previously loaded by this routine.
;
unload_stereo_spice_gen, verbose=verbose
;
;  Load the leap-seconds file.
;
stereo_spice_gen = getenv('STEREO_SPICE_GEN')
if !version.os_family eq 'Windows' then $
  stereo_spice_gen = concat_dir(stereo_spice_gen, 'dos')
files = file_search( concat_dir(stereo_spice_gen, 'naif*.tls'), count=count)
if count eq 0 then begin
    message = 'Unable to find leap-seconds file'
    goto, handle_error
endif
leapsec = max(files)
if keyword_set(verbose) then print, 'Loaded ' + leapsec
cspice_furnsh, leapsec
;
;  Load the solar system ephmeris.  Currently hardwired to de405.bsp.
;
solarsys = concat_dir(stereo_spice_gen, 'de405.bsp')
if not file_exist(solarsys) then begin
    message = 'Unable to find planetary ephemeris file'
    goto, handle_error
endif
if keyword_set(verbose) then print, 'Loaded ' + solarsys
cspice_furnsh, solarsys
;
;  Load the planetary constants file.
;
files = file_search( concat_dir(stereo_spice_gen, 'pck*.tpc'), count=count)
if count eq 0 then begin
    message = 'Unable to find planetary constants file'
    goto, handle_error
endif
planet_const = max(files)
if keyword_set(verbose) then print, 'Loaded ' + planet_const
cspice_furnsh, planet_const
;
;  Load the heliospheric and STEREO frames files
;
frames = concat_dir(stereo_spice_gen, ['heliospheric.tf', 'stereo_rtn.tf'])
for i=0,n_elements(frames)-1 do begin
    if not file_exist(frames[i]) then begin
        message = 'Unable to find planetary ephemeris file'
        goto, handle_error
    endif
    if keyword_set(verbose) then print, 'Loaded ' + frames[i]
    cspice_furnsh, frames[i]
endfor
;
;  Load the spacecraft clock files.
;
clocks = strarr(2)
stereo_spice_sclk = getenv('STEREO_SPICE_SCLK')
ahead = concat_dir(stereo_spice_sclk, 'ahead')
if !version.os_family eq 'Windows' then ahead = concat_dir(ahead, 'dos')
files = file_search( concat_dir(ahead, 'ahead_science_*.sclk'), count=count)
if count eq 0 then begin
    message = 'Unable to find spacecraft clock file'
    goto, handle_error
endif
clocks[0] = max(files)
if keyword_set(verbose) then print, 'Loaded ' + clocks[0]
cspice_furnsh, clocks[0]
;
behind = concat_dir(stereo_spice_sclk, 'behind')
if !version.os_family eq 'Windows' then behind = concat_dir(behind, 'dos')
files = file_search( concat_dir(behind, 'behind_science_*.sclk'), count=count)
if count eq 0 then begin
    message = 'Unable to find spacecraft clock file'
    goto, handle_error
endif
clocks[1] = max(files)
if keyword_set(verbose) then print, 'Loaded ' + clocks[1]
cspice_furnsh, clocks[1]
;
return
;
;  Error handling point.
;
handle_error:
if n_elements(errmsg) eq 0 then message, message else $
  errmsg = 'load_stereo_spice_gen: ' + message
;
end
