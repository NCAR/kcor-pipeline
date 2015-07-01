;;; This is a very quick program to look at kcor luts
;;;
;;; Edit this code for your special case.
;;; You'll need to create a list of your luts that either contains
;;; the full path, or edit the "cd" command below appropriately.
;;;
;;; Edit "domouse" below if you don't want to use the
;;; cursor to step through the images.
;;;
;;; This code will create 'gif' images of all the raw files.
;;; You can trun this off too if you need to.
;;; But the gif images can be nicely animated with 'xanim'
;;; on a linux system.
;;;
;;; Alice Lecinski 2012 Jan 25
;;;

    cd,'C:/alice/kco/svn/lut'
    clist='imlist'

pixx = 4096
img  = 0
img  = ulonarr(pixx)

wxsz = 512
wysz = 512

mywin=0
seewindow = 1
filenm=' '
top =long(0)
fpos=0
fpos=lonarr(5000)   &  ftmp=long(0)   &   ii=0


print,' '
print,'The luts listed in file: ',clist,' will now be displayed.'
print,' '
print,'You can use the mouse to move backwards and forwards in your list.'
print,'Place the mouse in the image window, and then:'
print,'     To move forwards, use the left most mouse button.'
print,'     To move backwards, use the middle   mouse button.'
print,' '
print,' '

if(seewindow eq 1 ) then begin ;{
    ; Open a window
    device,window_state=winst
    if(winst(mywin) eq 0)then begin ;{
	window,mywin,xsize=wxsz,ysize=wysz,xpos=50,ypos=270
	; Load color table
	dome=1
	if (dome eq 1) then begin ;{
	    loadct,3
	endif;}
    endif

endif ;}

close,13 & openr,13,clist
                  
while ( not eof(13) ) do begin ;{

    point_lun,-13,ftmp  & fpos(ii)=ftmp
    readf,13,filenm
    close,1 & openr,1,filenm & readu,1,img & close,1
    print, filenm


    if(seewindow eq 1 ) then begin ;{
	wset,mywin
        plot,img,title=filenm
	print,max(img),' is the max'
    endif ;}

    dogif = 0
    if ( dogif eq 1 ) then begin ;{

	set_plot,'z'
	device,set_resolution=[wxsz,wysz],set_colors=256,z_buffering=0
	plot,img,title=filenm
	filenm=filenm+'.gif'
	giffy=tvrd()
	write_gif,filenm,giffy,_a,_b,_c

	set_plot,'win'

    endif ;}


    ; Logic to move forwards or backwards in the list of images.
    if (seewindow eq 1 ) then begin  ;{
	domouse = 1
	if(domouse eq 1 ) then begin ;{
        cursor,x,y,/NORMAL,/DOWN
	if ( !ERR eq 2 ) then begin ;{
	    ii=ii-1  & if (ii le 0) then ii=0
	    point_lun,13,fpos(ii)
	endif else begin ;}{
	    ii=ii+1
	endelse ;}
	endif else begin ;}{
	    ii=ii+1
	    wait,0.2
	endelse ;}
    endif ;}

endwhile ;}
                  
close,13
print,'Done!'


end
