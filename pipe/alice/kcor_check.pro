;+
; kcor_check.pro
;------------------------------------------------------------------------------
; This routine, CkKcorGif.pro was written by Alice Lecinski 2013.
;
; It checks the realtime gif images as they arrive from
; MLSO.  The images are checked for clouds and
; occulting from the dome.
;
; It expects certain directories to exist, and is not
; generic by any means.
;
; $Id: CkKcorGif.pro,v 1.9 2014/08/06 18:48:18 sungod Exp $
;------------------------------------------------------------------------------
;-
PRO kcor_check, listfile

;--- Get host name.

myhost = getenv ('HOST')

;--- Initialize variables.

MyU = 13
filenm   = ' '
ftype    = ' '
seegif   = 0			; See the gif file if ==1
cksobel  = 1
ckclouds = 1
cksatu   = 1
ckbrisky = 1

dotest  = 0    ; This should be the only difference between 
               ;     CkKcorGif.pro
               ; and CkKcorGifTest.pro

if ( dotest eq 0 ) then $
begin ;{
    dospawn = 1

    if ( myhost eq 'sunseeker' ) then $
    begin ;{
        dospawncoronalgroup = 1
        dospawnlobby        = 0  ;;
        dospawnlobbyM       = 1  ;; Mesa
        dospawnsundry       = 1  ;; 
        dospawnevent        = 0  ;; 
    endif else begin ;}{
        dospawncoronalgroup = 0
        dospawnlobby        = 0
        dospawnlobbyM       = 0  ;; Mesa
        dospawnsundry       = 0  ;;
        dospawnevent        = 0  ;; 
    endelse ;}
endif else begin ;} {
    seegif  = 1
    dospawn = 0
    dospawncoronalgroup = 0
    dospawnlobby        = 0
    dospawnlobbyM       = 0  ;; Mesa
    dospawnsundry       = 0  ;; Mesa
    dospawnevent        = 0  ;; 
endelse ;}

;--- Directory definitions.

coronaldir = " /hao/ftpd5/kcor/raw_daily_image/"
lobbydir   = " /hao/sunseeker1/sungod/gallery/kcor/"
lobbyMdir  = " /hao/sundawg1/sungod/gallery/kcor/"
sundrydir  = " /hao/sundry1/sungod/gallery/kcor/"
eventdir   = " /hao/ftpd5/events/venus_transit_20120605"

isbad    = 0
rewrtgif = 0 
!order   = 0

;;;on_error,3

;--- Use Z-buffer.

set_plot,'z'
device,set_resolution=[512,512],set_colors=256,z_buffering=0

print, ' '
print, ' '
print, 'Routine: kcor_check.pro      ', systime()

;--- Request list file name.

if ( n_elements (listfile) eq 0) then $
begin ;{
    listfile = ' '
    print, $
      'Enter in a filename that contains a list of images to annotate.'
    print, 'The list should include the entire path to the images.'
    read, listfile
endif $
else begin ;}{
    print, ' '
    print, 'Your present listfile is: ',listfile
    print, 'To change it, enter the idl command: listfile=''newone'''
    print, 'Where ''newone'' is an example new list file.  '
    print, ' '
endelse;}

print, ' '
print, 'The images listed in file: ', listfile, ' will now be filtered.'
print, ' '
print, ' '

;--- Open list file.

close, MyU
openr, MyU,listfile
                  
;--- Image loop.

while ( not eof(MyU) ) do $
begin ;{
    readf, MyU, filenm
    print, ' '
    print, 'Working on file:    ',filenm

            ; Redo this here each time, as it may get reset below.
	    ; Establish 1D arrays for sampling a circle, every 1 degree.

            nray = 36
            nraym1 = nray-1
            acirc  = !PI * 2.0 / float (nray)
            dp     = findgen (nray) * acirc  
            dpx    = intarr (nray)
            dpy    = intarr (nray)
            xcen   = 255.5   & ycen = 255.5	; center of image (512,512).
            rnder  = 0.5005

    GifIsBad       = 0
    GifIsTruncated = 0

    ;--- Check for an ok gif file.

    gif_ok = query_gif (filenm,gif_info)
    if (gif_ok ne 1 ) then $
    begin ;{
        print, 'gif_ok ne 1 ', filenm
        GifIsTruncated = 1
    endif ;}

    ;--- Truncated GIF file.

    if ( GifIsTruncated eq 1 ) then $
    begin ;{
        print, ' There is a TRUNCATED gif file...'
        badfile = filenm
        print, badfile,'   is the bad one'

        cmnd = 'mv ' + badfile + ' ../Truncated'
        print, cmnd

        if (dospawn eq 1 ) then $
	begin ;{
            spawn, cmnd
            wait,1
        endif ;}

        GifIsBad = 1
        isbad    = 1
    endif ;}

    ;--- File length is OK.

    if (GifIsBad eq 0 ) then $
    begin ;{
        print,'        Reading:    ', filenm
        wrtgif    = 1		; Dont write out the gif file if == 0
        isbad     = 0		; Assume good.
        old_cmnd  = "mv " + filenm + " ../OLD"
        bad_cmnd  = "mv " + filenm + " ../Bad"
        good_cmnd = "mv " + filenm + " .."

        ; check the filenm for kcor_e.gif (engineering) or kcor_b.gif (bad).
        ; spot = strpos(filenm,'kcor.gif')	; should be kcor.gif
        ; if ( spot eq -1 ) then isbad = 1

        coronalgroup_cmnd  = "cp " + filenm + coronaldir
        coronalgroup_chmod = "chmod 664    " + coronaldir + filenm
        lobby_cmnd         = "cp " + filenm + lobbydir
        lobbyM_cmnd        = "cp " + filenm + lobbyMdir
        sundry_cmnd        = "cp " + filenm + sundrydir
        event_cmnd         = "cp " + filenm + eventdir


        if (isbad eq 0 ) then $
	begin ;{

            ;--- Read gif file.

            MyGif = 0			; zero out the length each time...
            read_gif, filenm, MyGif, _a, _b, _c  
            tvlct, _a, _b, _c

            ;--- Check for too bright a sky.

            if (ckbrisky eq 1 ) then $
	    begin ;{
                satu    = 50.			; brightness threshold.
                pixR    = 215.			; radius of circle [pixels].
                dpx     = fix ( cos (dp) * pixR  + xcen + rnder )
                dpy     = fix ( sin (dp) * pixR  + ycen + rnder )

                print, 'Outer sky bright check satu limit is: ',satu
                print, 'Outer sky bright check gif  info  is: ',MyGif(dpx,dpy)
                print, 'Outer sky bright avg  is: ',total(MyGif(dpx,dpy))/nray
                bady    = where (MyGif (dpx,dpy) ge satu)

		;--- If too many pixels in circle are bright, set isbad=1.

                if ( bady (0) ne -1 ) then $
		begin ;{
                    bsz = size (bady)
                    print, 'Cloud check bady is: ', bady
                    print, 'Cloud check bsz  is: ', bsz
                    if (bsz (1) ge (nray / 5)) then $
		    begin ;{
                        isbad = 1
                        print, '        Outer Clouds, zero values ', bad_cmnd
                    endif ;}
                endif ;}
            endif ;}

            ;--- Check for saturation.

            if (cksatu eq 1 ) then $
	    begin ;{
                satu    = 254			; Saturation threshold.
                pixR    = 225.
                pixR    = 155.			; move in a bit further
                dpx     = fix ( cos (dp) * pixR  + xcen + rnder )
                dpy     = fix ( sin (dp) * pixR  + ycen + rnder )
                print, 'Outer saturation check satu limit is: ', satu
                print, 'Outer saturation check gif  info  is: ', MyGif(dpx,dpy)
                print, 'Outer saturation avg  is: ', total(MyGif(dpx,dpy))/nray
                bady    = where (MyGif (dpx,dpy) ge satu)

                ;--- If too many pixels are saturated, set isbad=1.

                if ( bady (0) ne -1 ) then $
		begin ;{
                    bsz = size(bady)
                    print, 'Cloud check bady is: ', bady
                    print, 'Cloud check bsz  is: ', bsz
                    if (bsz(1) ge (nray / 5)) then $
		    begin ;{
                        isbad = 1
                        print, '        Outer Clouds, zero values ', bad_cmnd
                    endif ;}
                endif ;}
            endif ;}

            ;--- Check for clouds.

            if ((ckclouds eq 1 ) and (isbad eq 0 )) then $
	    begin ;{
                avglim  =  88.				; average threshold.
                cld     =  18				; lower threshold.
                pixR    = 225.
                pixR    = 155. ;; move in a bit further
                pixR    = 135. ;; move in a bit further
                pixR    = 138. ;; move out just a bit further
                dpx     = fix ( cos (dp) * pixR  + xcen + rnder )
                dpy     = fix ( sin (dp) * pixR  + ycen + rnder )
                avgcld  = total (MyGif (dpx,dpy)) / nray	; Average.

                print, 'Inner Cloud check cld limit is: ', cld
                print, 'Inner Cloud check gif info  is: ', MyGif (dpx,dpy)
                print, 'Inner Cloud avg is: ', avgcld

                bady    = where (MyGif (dpx,dpy) le cld)   ; below lower limit.

                ;--- If too many pixels are below lower limit, set isbad=1.

                if ( bady (0) ne -1 ) then $
		begin ;{
                    bsz = size (bady)
                    print, 'Cloud check bady is: ', bady
                    print, 'Cloud check bsz  is: ', bsz
                    if (bsz (1) ge (nray / 5)) then $
		    begin ;{
                        isbad = 1
                        print, '        Outer Clouds, zero values ', bad_cmnd
                    endif ;}
                endif ;}

                ;--- if average pixel intensity is above avglim, set isbad=1.

                if ( avgcld le avglim ) then $
		begin ;{
                    isbad = 1
                    print, '        Inner Clouds, avg < ',avglim,' ', bad_cmnd
                endif ;}
            endif ;}

            ;--- Do sobel test if isbad=0.

            if ((cksobel eq 1 ) and (isbad eq 0 )) then $
	    begin ;{
                print, 'Checking sobel'
                nray = 480
                nraym1 = nray-1
                acirc = !PI * 2.0 / float (nray)
                dp    = findgen (nray) * acirc  
                dpx   = intarr (nray)
                dpy   = intarr (nray)

                ;--- Radius loop.

                numbads = long ( 0 )
                for pixR = 201.0, 205.0, 1.0  do $
		begin ;{
                    dpx     = fix ( cos (dp) * pixR  + xcen + rnder )
                    dpy     = fix ( sin (dp) * pixR  + ycen + rnder )
                    mysobel = float (MyGif (dpx,dpy))
                    mydiff  = (abs (mysobel (0:nray-2) - mysobel(1:nray-1)))

                    if (dotest eq 1 ) then $
		    begin ;{
                        set_plot, 'x'
                        tvlct, _a, _b, _c
                        !p.multi = [0,1,2]
                        plot, mysobel, title = filenm + ' sobel '
                        plot, mydiff,  title = filenm + ' diff sobel '
                        !p.multi = [0,1,1]
                       ;MyGif (dpx,dpy) = 250
                        cursor, _x, _y, 3, /normal
                        set_plot, 'z'
                        device, set_resolution = [512,512],$
                            set_colors = 256, z_buffering = 0
                    endif ;}

                    sobellimit     = 40.0
                    sobeldifflimit = 15.0
                    badlimit       = 80.0

                    ; The sobel itself is not a good test.
                    ; The diff of the sobel works great.

                   ;bady = where(mysobel gt sobellimit)
                   ;if ( bady(0) ne -1 ) then begin ;{
                   ;    bsz = n_elements(bady)
                   ;    print,'sobellimit ',sobellimit
                   ;    print,'Sobel baddies: ',fix(mysobel(bady))
                   ;    print,'Sobel bsz  is: ',bsz,pixR
                   ;    numbads = numbads + bsz
                   ;endif ;}

                    bady = where (mydiff gt sobeldifflimit)
                    if ( bady (0) ne -1 ) then $
		    begin ;{
                        bsz = n_elements (bady)
                        print, 'sobeldifflimit ', sobeldifflimit
                        print, 'sobel difference baddies: ', fix (mydiff (bady))
                        print, 'sobel difference bsz  is: ', bsz, pixR
                        numbads = numbads + bsz
                    endif ;}
                endfor ;}

                if( dotest eq 1 ) then $
		begin ;{
                    set_plot, 'x'
                    tv, MyGif
                    set_plot, 'z'
                    device,set_resolution=[512,512],set_colors=256,z_buffering=0
                endif ;}

                print, filenm, '       Sobel total baddies:', numbads
                print, filenm, '       Sobel      badlimit:', badlimit

                ;--- If sobel limit is exceeded, set isbad=1.

                if (numbads ge badlimit) then $
		begin ;{
                    isbad = 1
                    print, '        Too many sobel baddies   ', bad_cmnd
                endif ;}
            endif;}
        endif;}

        print, ' '

        ;--- Move bad GIF images to "bad" directory.

        if ( isbad eq 1 ) then $
	begin ;{
            print, '                    ', bad_cmnd
            if (dospawn eq 1 ) then $
	    begin ;{
                spawn, bad_cmnd
                wait, 1
            endif ;}
            if ( wrtgif eq 1 ) then wrtgif = 0
        endif ;} 

        ;--- Copy GIF image to selected directories.

        if (wrtgif eq 1)then $
	begin ;{
            if(rewrtgif eq 1 ) then write_gif, filenm, MyGif, _a, _b, _c
            print, '        Good image  ', good_cmnd

            if (dospawncoronalgroup eq 1 ) then $
	    begin ;{
                spawn, coronalgroup_cmnd
                spawn, coronalgroup_chmod
                wait,1
            endif ;}
            if (dospawnlobby        eq 1 ) then $
	    begin ;{
                spawn,lobby_cmnd
            endif ;}
            if (dospawnlobbyM       eq 1 ) then $
	    begin ;{
                spawn,lobbyM_cmnd
            endif ;}
            if (dospawnsundry       eq 1 ) then $
	    begin ;{
                spawn,sundry_cmnd
            endif ;}
            if (dospawnevent        eq 1 ) then $
	    begin ;{
                spawn,event_cmnd
            endif ;}

            if (dospawn eq 1 ) then $
	    begin ;{
                spawn, good_cmnd
                wait, 1
            endif ;}
        endif ;}

        ;--- Display GIF image on screen.

        if (seegif eq 1) then $
	begin;{
            set_plot, 'x'
            tvlct, _a, _b, _c
            tv, MyGif
            cursor, _x, _y, 3, /normal
            MyGif (dpx,dpy) = 200
            tv, MyGif
            cursor, _x, _y, 3, /normal
            print, min (MyGif), max (MyGif)
            set_plot, 'z'
            device, set_resolution=[512, 512], set_colors=256, z_buffering=0
        endif;}

    endif ;}

    print, ' '
    
endwhile ;}

close, MyU
end
