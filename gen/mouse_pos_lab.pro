;
; NAME		mouse_pos_lab
;
; FUNCTION	Determine pixel coordinates of the mouse cursor.
;
; SYNTAX	mouse_pos_lab, xdim, ydim, xcen, ycen, pixrs, roll, pos=1
;		xdim, ydim	image dimensions
;		xcen, ycen	sun center
;		pixrs		pixels/Rsun
;		roll		angle (deg) of solar north w.r.t. +Y axis.
;		pos		Optional position number label.
;		pfile		Optional output file name.
;		disp_label	Option to display position number.
;
; HISTORY	Andrew L. Stanger   HAO/NCAR   14 May 1999
;		26 Sep 2001: Label cursor position.
;		19 Sep 2003: Displaying the position number label is now
;			     an option.
;-

PRO mouse_pos_lab, xdim, ydim, xcen, ycen, pixrs, roll, pos=pos, pfile=pfile, $
		   disp_label=disp_label

   
   IF (STRLOWCASE (!version.os) EQ 'irix')    THEN cfac = 1.0 ELSE cfac = 2.0
   cs = cfac * 1.0

   IF (KEYWORD_SET (pos)) THEN pos_num = pos	$
   ELSE pos_num = 1

   IF (KEYWORD_SET (pfile)) THEN	$
   BEGIN
      CLOSE, 21
      OPENU, 21, pfile, /APPEND
   END

   angle  = 0.0
   radius = 0.0
   TVCRS, xcen, ycen				; Enable cursor

   PRINT, 'Click left   mouse button to print cursor position [r,pos_angle].'
   PRINT, 'Click middle mouse button to terminate cursor position coordinates.'

   WHILE ( 1 ) DO	$
   BEGIN
      CURSOR, rxcur, rycur, /DEVICE, WAIT=3
      IF (!ERR EQ 2) THEN GOTO, quit		; Done if middle button clicked.

      ierror = rcoord (radius, angle, rxcur, rycur, -1, roll, xcen, ycen, pixrs)
;      PRINT, 'x, y: ', rxcur, rycur, ' radius, angle: ', radius, angle
      PRINT, FORMAT = '("[x,y]: ", i4, i4, "   [r,th]: ", F5.2, " Rsun ", F7.2, " degrees")', $
		      rxcur, rycur, radius, angle
      WAIT,  0.5

      ;--- Write Region information into log file.

;      OPENW, lulog, logfile, /GET_LUN
;      PRINTF, lulog, 'Mouse-Defined Curved Wedge        Region: ',	$
;		      STRING (aoinum, FORMAT='(i3)')
;      PRINTF, lulog, STRING (rmin, FORMAT='(F7.2)'), ' -->	',	$
;	 	      STRING (rmax, FORMAT='(F7.2)'), ' Rsun   ',	$
;                     STRING (angmin, FORMAT='(F7.2)'), ' --> ',	$
;		      STRING (angmax, FORMAT='(F7.2)'), ' degrees'
;      PRINTF, lulog, 'polygon vertices file: ', pvfile
;      CLOSE, lulog
;      FREE_LUN, lulog

      ;--- Write info to screen.

;      PRINT, STRING (rmin, FORMAT='(F7.2)'), ' -->	',	$
;	      STRING (rmax, FORMAT='(F7.2)'), ' Rsun   ',	$
;             STRING (angmin, FORMAT='(F7.2)'), ' --> ',	$
;	      STRING (angmax, FORMAT='(F7.2)'), ' degrees'

      ;--- Draw point at cursor position.

      xv = [rxcur - 3, rxcur + 3]
      yv = [rycur - 3, rycur + 3]
      PLOTS, xv, yv, color=254, /DEVICE
      xv = [rxcur + 3, rxcur - 3]
      yv = [rycur - 3, rycur + 3]
      PLOTS, xv, yv, color=254, /DEVICE

      IF (KEYWORD_SET (disp_label)) THEN	$
       XYOUTS, rxcur+5, rycur, STRTRIM (STRING (pos_num), 2), $
       color=254, charsize=cs, /DEVICE

      IF (KEYWORD_SET (pfile)) THEN $
      BEGIN
         spos_num = STRING (pos_num, FORMAT='(I3)')     
	 sradius  = STRING (radius,  FORMAT='(F6.2)')
	 sangle   = STRING (angle ,  FORMAT='(F8.2)')
	 PRINTF, 21, 'Position #', spos_num, '   radius:', sradius, $
		     '   P.A.:', sangle
      END

      pos_num = pos_num + 1
   END

   quit: WAIT, 1.0

   IF (KEYWORD_SET (pfile)) THEN CLOSE, 21

END
