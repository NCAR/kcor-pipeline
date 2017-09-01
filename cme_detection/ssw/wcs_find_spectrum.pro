;+
; Project     :	STEREO
;
; Name        :	WCS_FIND_SPECTRUM
;
; Purpose     :	Find spectral axis information in FITS header
;
; Category    :	FITS, Coordinates, WCS
;
; Explanation :	This procedure extracts spectral axis information from a
;               FITS index structure, and adds it to a World Coordinate System
;               structure in a separate SPECTRUM substructure.
;
;               This routine is normally called from FITSHEAD2WCS.
;
; Syntax      :	WCS_FIND_SPECTRUM, INDEX, TAGS, SYSTEM, WCS
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
; Outputs     :	The output is the structure SPECTRUM, which will contain
;               keywords relevant to the spectral axis.  The primary keywords
;               are
;
;                       SPEC_INDEX:     Index of the spectral axis
;                       RESTFRQ:        Rest frequency
;                       RESTWAV:        Rest wavelength
;
;               and the remainder concern the reference frame that the data
;               were taken in.
;
;               If successful, the SPECTRUM structure is added to the WCS
;               structure.
;
; Opt. Outputs:	None.
;
; Keywords    :	COLUMN    = String containing binary table column number, or
;                           the null string.
;
;               LUNFXB    = The logical unit number returned by FXBOPEN,
;                           pointing to the binary table that the header
;                           refers to.  Usage of this keyword allows
;                           implementation of the "Greenbank Convention",
;                           where keywords can be replaced with columns of
;                           the same name.
;
;               ROWFXB    = Used in conjunction with LUNFXB, to give the
;                           row number in the table.  Default is 1.
;
; Calls       :	WCS_FIND_KEYWORD
;
; Common      :	None.
;
; Restrictions:	Currently, only one FITS header, and one WCS, can be examined
;               at a time.
;
; Side effects:	None.
;
; Prev. Hist. :	None.
;
; History     :	Version 1, 06-Jun-2005, William Thompson, GSFC
;               Version 2, 23-Jun-2005, William Thompson, GSFC
;                       Add support for binary tables
;
; Contact     :	WTHOMPSON
;-
;
pro wcs_find_spectrum, index, tags, system, wcs, column=column, $
                       lunfxb=lunfxb, rowfxb=rowfxb
on_error, 2
if n_elements(column) eq 0 then column=''
c = 2.99792458D8        ;Speed of light
;
;  Look for the axis containing the spectrum.
;
command = ''
ctype = strupcase( strmid(wcs.ctype,0,4) )
w = where((ctype eq 'FREQ') or (ctype eq 'ENER') or (ctype eq 'WAVN') or $
          (ctype eq 'VRAD') or (ctype eq 'WAVE') or (ctype eq 'VOPT') or $
          (ctype eq 'ZOPT') or (ctype eq 'AWAV') or (ctype eq 'VELO') or $
          (ctype eq 'BETA'), count)
if count gt 0 then begin
    spec_index = w[0]
    command = command + 'spec_index: ' + ntrim(spec_index)
;
;  If the axis was one previously assumed to be a spatial dimension, make sure
;  that a spherical projection is not assumed.
;
    if (spec_index eq wcs.ix) or (spec_index eq wcs.iy) then $
      wcs.projection = ''
endif
;
;  Look for the rest frequency and wavelength.
;
val = wcs_find_keyword(index, tags, column, system, count, $
                       ['RESTFRQ','RESTFREQ'], 'RFRQ', /allow_primary, $
                       lunfxb=lunfxb, rowfxb=rowfxb)
if count gt 0 then restfrq = val[0]
;
val = wcs_find_keyword(index, tags, column, system, count, 'RESTWAV', 'RWAV', $
                       /allow_primary, lunfxb=lunfxb, rowfxb=rowfxb)
if count gt 0 then restwav = val[0]
;
if (n_elements(restfrq) eq 1) and (n_elements(restwav) eq 0) then $
  restwav = c / restfrq
if (n_elements(restwav) eq 1) and (n_elements(restfrq) eq 0) then $
  restfrq = c / restwav
if n_elements(restwav) eq 1 then begin
    if strlen(command) gt 0 then command = command + ', '
    command = command + 'RESTFRQ: RESTFRQ, RESTWAV: RESTWAV'
endif
;
val = wcs_find_keyword(index, tags, column, system, count, 'SPECSYS', 'SPEC', $
                       /allow_primary, lunfxb=lunfxb, rowfxb=rowfxb)
if count gt 0 then begin
    specsys = val[0]
    if strlen(command) gt 0 then command = command + ', '
    command = command + 'SPECSYS: SPECSYS'
endif
;
val = wcs_find_keyword(index, tags, column, system, count, 'SSYSOBS', 'SOBS', $
                       /allow_primary, lunfxb=lunfxb, rowfxb=rowfxb)
if count gt 0 then begin
    ssysobs = val[0]
    if strlen(command) gt 0 then command = command + ', '
    command = command + 'SSYSOBS: SSYSOBS'
endif
;
val = wcs_find_keyword(index, tags, column, '', count, 'OBSGEO-X', 'OBSGX', $
                       /allow_primary, lunfxb=lunfxb, rowfxb=rowfxb)
if count gt 0 then begin
    obsgeo_x = val[0]
    if strlen(command) gt 0 then command = command + ', '
    command = command + 'OBSGEO_X: OBSGEO_X'
endif
;
val = wcs_find_keyword(index, tags, column, '', count, 'OBSGEO-Y', 'OBSGY', $
                       /allow_primary, lunfxb=lunfxb, rowfxb=rowfxb)
if count gt 0 then begin
    obsgeo_y = val[0]
    if strlen(command) gt 0 then command = command + ', '
    command = command + 'OBSGEO_Y: OBSGEO_Y'
endif
;
val = wcs_find_keyword(index, tags, column, '', count, 'OBSGEO-Z', 'OBSGZ', $
                       /allow_primary, lunfxb=lunfxb, rowfxb=rowfxb)
if count gt 0 then begin
    obsgeo_z = val[0]
    if strlen(command) gt 0 then command = command + ', '
    command = command + 'OBSGEO_Z: OBSGEO_Z'
endif
;
val = wcs_find_keyword(index, tags, column, system, count, 'VELOSYS', 'VSYS', $
                       /allow_primary, lunfxb=lunfxb, rowfxb=rowfxb)
if count gt 0 then begin
    velosys = val[0]
    if strlen(command) gt 0 then command = command + ', '
    command = command + 'VELOSYS: VELOSYS'
endif
;
val = wcs_find_keyword(index, tags, column, system, count, 'ZSOURCE', 'ZSOU', $
                       /allow_primary, lunfxb=lunfxb, rowfxb=rowfxb)
if count gt 0 then begin
    zsource = val[0]
    if strlen(command) gt 0 then command = command + ', '
    command = command + 'ZSOURCE: ZSOURCE'
endif
;
val = wcs_find_keyword(index, tags, column, system, count, 'SSYSSRC', 'SSRC', $
                       /allow_primary, lunfxb=lunfxb, rowfxb=rowfxb)
if count gt 0 then begin
    ssyssrc = val[0]
    if strlen(command) gt 0 then command = command + ', '
    command = command + 'SSYSSRC: SSYSSRC'
endif
;
val = wcs_find_keyword(index, tags, column, system, count, 'VELANGL', 'VANG', $
                       /allow_primary, lunfxb=lunfxb, rowfxb=rowfxb)
if count gt 0 then begin
    velangl = val[0]
    if strlen(command) gt 0 then command = command + ', '
    command = command + 'VELANGL: VELANGL'
endif
;
if strlen(command) gt 0 then begin
    command = 'spectrum = {' + command + '}'
    test = execute(command)
;
;  Add the SPECTRUM tag to the WCS structure.
;
    if tag_exist(wcs,'SPECTRUM',/top_level) then wcs = rem_tag(wcs,'SPECTRUM')
    wcs = add_tag(wcs, spectrum, 'SPECTRUM', /top_level)
endif
;
return
end
