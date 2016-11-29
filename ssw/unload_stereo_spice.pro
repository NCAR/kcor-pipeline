;+
; Project     :	STEREO - SSC
;
; Name        :	UNLOAD_STEREO_SPICE
;
; Purpose     :	Unload the STEREO SPICE kernels
;
; Category    :	STEREO, Orbit
;
; Explanation :	Unloads any previously loaded SPICE kernels, such as those
;               loaded by LOAD_STEREO_SPICE and LOAD_STEREO_SPICE_GEN.
;
; Syntax      :	UNLOAD_STEREO_SPICE
;
; Inputs      :	None.
;
; Opt. Inputs :	None.
;
; Outputs     :	None.
;
; Opt. Outputs:	None.
;
; Keywords    :	VERBOSE = If set, then print a message for each file unloaded.
;
; Calls       :	CSPICE_UNLOAD, UNLOAD_STEREO_SPICE_GEN
;
; Common      :	STEREO_SPICE contains the names of the loaded files.
;
;               STEREO_SPICE_CONIC contains data used to extrapolate the Ahead
;               and Behind ephemerides beyond their end date.
;
;               STEREO_SPICE_GEN and STEREO_SPICE_EARTH are used by their
;               respective load routines.
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
; Side effects:	Version 4 unloads *all* loaded kernels, not just those loaded
;               by LOAD_STEREO_SPICE.  This was done to greatly speed up the
;               routine.
;
; Prev. Hist. :	None.
;
; History     :	Version 1, 25-Aug-2005, William Thompson, GSFC
;               Version 2, 29-Aug-2005, William Thompson, GSFC
;                       Added keyword VERBOSE
;               Version 3, 22-Mar-2006, William Thompson, GSFC
;                       Clear contents of STEREO_SPICE_CONIC
;               Version 4, 20-Apr-2007, William Thompson, GSFC
;                       Unload all kernels in the order they were loaded.
;                       This greatly speeds up the process.
;               Version 5, 21-May-2007, WTT, Use cspice_kclear
;               Version 6, 14-Jun-2010, WTT, Also clear STEREO_SPICE_EARTH
;
; Contact     :	WTHOMPSON
;-
;
pro unload_stereo_spice, verbose=verbose
;
common stereo_spice, def_ephem, ephem, attitude, att_sc, att_mjd, att_loaded
common stereo_spice_conic, mu, maxdate, conic
common stereo_spice_gen, leapsec, solarsys, planet_const, frames, clocks
common stereo_spice_earth, earth_pck
on_error, 2
;
;  Clear all the kernels.  First try using cspice_kclear.  If this doesn't
;  work, then get a list of all loaded ephemerides, and unload them in the
;  order in which they were loaded.
;
if not execute('cspice_kclear') then begin
    spice_kernel_report, kernels=kernels, /quiet
    for i=0,n_elements(kernels)-1 do begin
        cspice_unload, kernels[i]
        if keyword_set(verbose) then print, 'Unloaded ' + kernels[i]
    endfor
endif
;
;  Undefine the variables in the common blocks.
;
delvarx, leapsec, solarsys, planet_const, frames, clocks
delvarx, def_ephem, ephem, attitude, att_sc, att_mjd, att_loaded
delvarx, maxdate, conic
delvarx, earth_pck
;
end
