PRO OUTPLOT,X0, Y, xst0, $
        channel=channel, $
        clip=clip, color=color, device=device, $
        linestyle=linestyle, noclip=noclip, data=data, $
        normal=normal, nsum=nsum, polar=polar, $
        psym=psym, symsize=symsize, $
        t3d=t3d, thick=thick

quiet_save = !quiet
!quiet=1
on_error,2
;+
; NAME:
;	OUTPLOT
; PURPOSE:
;	Plot vector data over a previously drawn plot (using UTPLOT) with
;	universal time labelled X axis.  If start and end times have been
;	set, only data between those times is displayed.
; CATEGORY:
; CALLING SEQUENCE:
;	OUTPLOT,X,Y
;	OUTPLOT,X,Y,'UTSTRING'
; INPUTS:
;       X -     X array to plot in seconds relative to base time.
;               (MDM) Structures allowed
;       Y -     Y array to plot.
;       xst -   Optional. The reference time to use for converting a structure
;               into a seconds array. IMPORTANT - this should not be
;		used since it will use the start time that was defined in the
;		plot command.  It is necessary if the X input is an in seconds
;		already and the reference time is no the same as that used by
;		the UTPLOT base time.
; OPTIONAL INPUT PARAMETERS:
;	UTSTRING = ASCII string containing base time of data to be be overlaid.
;	If present, it is used as base time for this data, but UTBASE variable
;	in common is not changed.  If not present, last base time set is used.
; OUTPUTS:
;	None.
; OPTIONAL OUTPUT PARAMETERS:
;	None.
; COMMON BLOCKS:
;	None.
; SIDE EFFECTS:
;	Overlays X vs Y plot on existing plot.
; RESTRICTIONS:
;	Can only be used after issuing UTPLOT command.
; PROCEDURE:
;	If UTSTRING parameter is passed, a temporary X array is created 
;	containing the original X array offset by the new base
;	time minus the old base time (used in UTPLOT command).  OPLOT is 
;	called to plot the temporary X vs Y.
; MODIFICATION HISTORY:
;	Written by Kim Tolbert 4/88
;	Modified for IDL VERSION 2 by Richard Schwartz, Feb. 1991
;	21-Mar-92 (MDM) - Adjusted for YOHKOH spacecraft use - allowed 
;			  input variable to be a structure
;			- Added multiple keyword options (old version
;			  only took x and y)
;	28-Apr-92 (MDM) - "SYMSIZE" was not being implemented
;	23-Oct-92 (MDM) - IDL Ver 2.4.0 does not accept /DEV, /NORM, or /DATA
;			  for the OPLOT command any more
;-
COMMON UTCOMMON, UTBASE, UTSTART, UTEND, xst_plot
;
;overplot on UTPLOT
;;utbase=getutbase(0)
;;setutbase,utstring ;set new base time
;;utbasenew=getutbase(0)
;;setutbase,atime(utbase)
;;oplot,x+utbasenew-utbase,y

;--------------------- MDM added
if (n_elements(xst0) ne 0) then begin
    ex2int, anytim2ex(xst0), xst_msod, xst_ds79
    xst = [xst_msod, xst_ds79]
    off = int2secarr(xst, xst_plot)
    off = off(0)	;convert to scalar
end else begin
    xst = xst_plot	;use the value that was used for UTPLOT
    off = 0
end
;
siz = size(x0)
typ = siz( siz(0)+1 )
if (typ eq 8) then x = int2secarr(x0, xst) else x = x0 + off
;
psave = !p
        !p.channel=fcheck(channel,!p.channel)
        !p.clip=fcheck(clip,!p.clip)
        !p.color=fcheck(color,!p.color)
        !p.linestyle=fcheck(linestyle,!p.linestyle)
        !p.noclip=fcheck(noclip,!p.noclip)
        !p.nsum=fcheck(nsum,!p.nsum)
        !p.psym=fcheck(psym,!p.psym)
        !p.t3d=fcheck(t3d,!p.t3d)
        !p.thick=fcheck(thick,!p.thick)

;;oplot,x,y, data=fcheck(data), device=fcheck(device), $
;;        normal=fcheck(normal), $
;;        polar=fcheck(polar), symsize=fcheck(symsize,1)
oplot,x,y, polar=fcheck(polar), symsize=fcheck(symsize,1)	;MDM patch 23-Oct-92 because of change to IDL

!p = psave
;
;.........................................................................

!quiet = quiet_save
return
end
