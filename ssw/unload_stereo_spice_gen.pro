;+
; Project     :	STEREO - SSC
;
; Name        :	UNLOAD_STEREO_SPICE_GEN
;
; Purpose     :	Unload the general STEREO SPICE kernels
;
; Category    :	STEREO, Orbit
;
; Explanation :	Unloads the general SPICE kernels previously loaded by
;               LOAD_STEREO_SPICE_GEN.
;
; Syntax      :	UNLOAD_STEREO_SPICE_GEN
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
; Calls       :	CSPICE_UNLOAD
;
; Common      :	STEREO_SPICE_GEN contains the names of the loaded files.
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
;               Version 2, 25-Aug-2005, William Thompson, GSFC
;                       Undefine common block variables after unloading
;               Version 3, 29-Aug-2005, William Thompson, GSFC
;                       Added keyword VERBOSE
;
; Contact     :	WTHOMPSON
;-
;
pro unload_stereo_spice_gen, verbose=verbose
common stereo_spice_gen, leapsec, solarsys, planet_const, frames, clocks
on_error, 2
;
;  Unload the files.
;
if n_elements(leapsec) eq 1 then begin
    cspice_unload, leapsec
    if keyword_set(verbose) then print, 'Unloaded ' + leapsec
    delvarx, leapsec
endif
;
if n_elements(solarsys) eq 1 then begin
    cspice_unload, solarsys
    if keyword_set(verbose) then print, 'Unloaded ' + solarsys
    delvarx, solarsys
endif
;
if n_elements(planet_const) eq 1 then begin
    cspice_unload, planet_const
    if keyword_set(verbose) then print, 'Unloaded ' + planet_const
    delvarx, planet_const
endif
;
if n_elements(frames) ne 0 then begin
    for i=0,n_elements(frames)-1 do begin
        cspice_unload, frames[i]
        if keyword_set(verbose) then print, 'Unloaded ' + frames[i]
    endfor
    delvarx, frames
endif
;
if n_elements(clocks) ne 0 then begin
    for i=0,n_elements(clocks)-1 do begin
        cspice_unload, clocks[i]
        if keyword_set(verbose) then print, 'Unloaded ' + clocks[i]
    endfor
    delvarx, clocks
endif
;
end
