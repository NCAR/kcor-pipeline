;;
;; Written by Alice Lecinski 2013
;;

;; whether or not to display the data processing steps
see_data = 0

is_eng = 0

;; Annotation extras

daytab=intarr(13,2)
daytab=[[0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 ],  $
        [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 ]]

montab=['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
imontb=['01_','02_','03_','04_','05_','06_','07_','08_','09_','10_','11_','12_']

;; pangle in degrees
    spawn,'/home/mlso/luna/bin/Getpangle',apangle
   ;pangle = 22
    pangle = apangle(0) + 180.

;; Read in the mask
   ;filenm = '/home/alice/idl_pros/kco/kcomask.bin'
    filenm = '/home/mlso/luna/idl_pros/kcomask.bin'
    xdim = 1024
    ydim = 1024
    mask = 0
    mask = fltarr(xdim,ydim)
    close,1 & openr,1,filenm & readu,1,mask & close,1


;; Set up memory for the header and the data.
    lfilenm=' '
    filenm = '20131113_194003_kcor.fts'
             ;123456789.123456789.1234
    pixx = 1024
    pixy = 1024*8
    simg = 0
    simg = intarr(pixx,pixy)

    hdr = 0
    hdr = bytarr(2880*2)

;; The list of images to process
    iimg  = 0
    clist = 'callist'
    close,13 & openr,13,clist

    while ( not eof(13) ) do begin ;{
      readf,13,lfilenm
      close,1 & openr,1,lfilenm & readu,1,hdr & readu,1,simg & close,1
     ;print,lfilenm
      llen = strlen(lfilenm)
      filenm = strmid(lfilenm,llen-24,24)
     ;print,filenm
      gfilenm = strmid(filenm,0,20) + '.gif'

      is_eng = 0  ;; assume data is science data.

      ;; Check that we have science data
      len = 80
      line=14 & hspt = line*len & datatype = string(hdr(hspt:hspt+79))
      scispot = strpos(datatype,'science')

      if(scispot ne 24 ) then begin ;{ We've got engineering data! :-)
        is_eng  = 1
        gfilenm = strmid(filenm,0,20) + '_e.gif'
        ;; now set scispot to 24 so eng data gets processed too.
        scispot = 24
      endif ;}

      if(scispot eq 24 ) then begin ;{ We've got science data! :-)

        iimg = iimg +1
        swap_endian_inplace, simg,/swap_if_little_endian
        img = long(simg) + 32768L

        ; The 1st camera.
        ii = 0L & yb = 1024L*ii & ye = yb+1023L & img0_0 = img(0:1023,yb:ye)
        ii = 1L & yb = 1024L*ii & ye = yb+1023L & img0_1 = img(0:1023,yb:ye)
        ii = 2L & yb = 1024L*ii & ye = yb+1023L & img0_2 = img(0:1023,yb:ye)
        ii = 3L & yb = 1024L*ii & ye = yb+1023L & img0_3 = img(0:1023,yb:ye)
        q0 = img0_0 - img0_3   & u0 = img0_1 - img0_2
        sqq0 = (q0*q0)
        squ0 = (u0*u0)
        pB0 = sqrt(sqq0+squ0)
        mxi = 200 ;; 0.16 exp time
        mxi = 600 ;; 0.6 exp time
        mxi = 1400 ;; 1.0 exp time
        mxi = 3000 ;; 1.0 exp time 20131203 lut tables
        mni = 10

        if ( see_data eq 1 ) then begin ;{
            set_plot,'x'
            tv,bytscl(pB0,mni,mxi)
            stop
        endif ;}

        ; Just use the 1st camera.
        ; The 2nd camera.
        ;ii = 4L & yb = 1024L*ii & ye = yb+1023L & img1_0 = img(0:1023,yb:ye)
        ;ii = 5L & yb = 1024L*ii & ye = yb+1023L & img1_1 = img(0:1023,yb:ye)
        ;ii = 6L & yb = 1024L*ii & ye = yb+1023L & img1_2 = img(0:1023,yb:ye)
        ;ii = 7L & yb = 1024L*ii & ye = yb+1023L & img1_3 = img(0:1023,yb:ye)
        ;q1 = img1_0 - img1_3   & u1 = img1_1 - img1_2
        ;sqq1 = (q1*q1)
        ;squ1 = (u1*u1)
        ;pB1 = sqrt(sqq1+squ1)

        ;; Check for clouds
        cldlimit = 7  ;; 0.16 exp time
        cldlimit = 17 ;; 1.0  exp time
        cldlimit = 20 ;; 1.0  exp time
        cldlimit = 32 ;; 1.0  exp time 20131203 lut tables
        cldlimit = 43 ;; 20131227 O1 rotated 90 degrees
        ctest = pB0(480:549,10:19) ;; 700 points
        cavg  = total(ctest) / 700. ;; 5 (<7) for clear and 60. for clouds
       ;print,cavg,' cavg should be < ',cldlimit,' to be cloud free'
        if ((cavg le 1.) or  ( cavg ge cldlimit )) then begin ;{
            if ( is_eng eq 0 ) then begin ;{
               ;Leave the gif filename alone for a little bit for testing.
               ;gfilenm = strmid(filenm,0,20) + '_b.gif'
            endif ;}
            ;; set cavg to an acceptable value so 
            ;; the data still gets processed below.
            cavg = cldlimit -1
        endif ;}
        if ((cavg ge 1.) and ( cavg le cldlimit )) then begin ;{

                     ;; Setting iimg = 2 will
            iimg = 2 ;; force skipping over the find center and shifts
                     ;; comment this out to calculate the shift.
            myx_shift =   4  ;; -19 prior to 20140620
            myy_shift =   4  ;;  10 prior to 20140620
            ;; find the center of the image and shift to the
            ;; center of the frame so we rotate everything properly.
            if ( iimg eq 1 ) then begin ;{
                xcen = ( float(xdim) * 0.5 ) - 0.5
                ycen = ( float(ydim) * 0.5 ) - 0.5
                xtest = pB0(*           ,fix(ycen))
                ytest = pB0(fix(xcen-50),*)

                ck_cenPlot = 0
                if(ck_cenPlot eq 1 ) then begin ;{
                    !p.multi=[0,1,2]
                    plot,xtest
                    plot,ytest
                    !p.multi=[0,1,1]
                endif ;}

                xmaxl = max(xtest(0   :xcen)  ,xspotl)
                xmaxr = max(xtest(xcen:xdim-1),xspotr) & xspotr=xspotr+xcen
                ymaxb = max(ytest(0   :ycen)  ,yspotb)
                ymaxt = max(ytest(ycen:ydim-1),yspott) & yspott=yspott+ycen

                cal_xcen = xspotl + (xspotr-xspotl)*0.5
                cal_ycen = yspotb + (yspott-yspotb)*0.5

                myx_shift =  fix(0.50 + xcen - cal_xcen)
                myy_shift =  fix(0.50 + ycen - cal_ycen)
                print,xspotl,xspotr,' ',cal_xcen, myx_shift
                print,yspotb,yspott,' ',cal_ycen, myy_shift
            endif ;}

            ;; Apply the shift
            shpB0 = shift(pB0, myx_shift, myy_shift)
            if ( see_data eq 1 ) then begin ;{
                tv,bytscl(shpB0,mni,mxi)
            endif ;}

            ;; rotate by the pangle
            rpB0   = rot(shpB0,pangle,/interp,cubic=-0.5)
            if ( see_data eq 1 ) then begin ;{
                tv,bytscl(rpB0,mni,mxi)
            endif ;}

            ;; Apply a mask to get rid of ugly pixels
            rpB0 = rpB0*mask
            rpB0[where(rpB0 lt 11)] = 11.
            if ( see_data eq 1 ) then begin ;{
                tv,bytscl(rpB0,mni,mxi)
            endif ;}

           ;smlrpB0 = rpB0(256:1023-256,256:1023-256)
            xbe = 128 + 32
            smlrpB0 = rpB0(xbe:1023-xbe,xbe:1023-xbe)
            smlrpB0 = congrid(smlrpB0,512,512,/interp)
            mypow = 0.9
            smlrpB0 = smlrpB0^mypow
            mxi     = mxi^mypow
            if ( see_data eq 1 ) then begin ;{
                tv,bytscl(smlrpB0,mni,mxi)
            endif ;}

            mk_gif = 1
            if ( mk_gif eq 1 ) then begin ;{
                doColor=1 ;; Dont use blue color table if ==0
                doanno=1  ;; Dont write out the annotation if ==0
                wrtgif=1  ;; Dont write out the gif file if ==0
                seegif=0  ;; See the gif file if ==1
                !order=0

                set_plot,'z'
                device,set_resolution=[512,512],set_colors=256,z_buffering=0

               ;gfilenm = strmid(filenm,0,21) + 'gif'
                print,gfilenm

                year=fix(strmid(filenm,0,4))
                year = strcompress(string(year),/remove_all)
                iyr=fix(year)

                hr   =strmid(filenm,9,2)  &  mn =strmid(filenm,11,2) 
                secs =strmid(filenm,13,2) 

                time=hr+':'+mn +':'+secs+' UT';; No seconds on kcor
                ccol = 255

                leap=long((iyr mod 4 eq 0) $
                      and (iyr mod 100 ne 0) $
                       or (iyr mod 400 eq 0))

                m=fix(strmid(filenm,4,2))
               ;print,m,' is month'
                m=m-1  & if(m lt 0) then m=0
                month=strlowcase(montab(m))
                imonth=imontb(m)

                iday=fix(strmid(filenm,6,2))
                doy = iday
                for ii=0,m do doy = doy + daytab(ii,leap)
                Sdoy=strcompress(string(doy))
                
                cday = strcompress(string(iday),/remove_all)

                if( iday lt 10) then $
                      date = '0' + cday +' '+montab(m)+' '+year $
                else  date =       cday +' '+montab(m)+' '+year

                if     ( doy lt 10 ) then Fdoy = '00'+ Sdoy $
                else if( doy lt 100) then Fdoy = '0' + Sdoy $
                else                      Fdoy = ''  + Sdoy

                Fdoy=strcompress(Fdoy,/remove_all)
                if     ( doy lt 10 ) then doy = 'DOY  '+ Sdoy $
                else if( doy lt 100) then doy = 'DOY ' + Sdoy $
                else                      doy = 'DOY'  + Sdoy 

                if(doColor eq 1) then begin;{
                    close,11
                   ;openr,11,'~alice/idl_pros/mk4blue.rgb'
                    openr,11,'/home/mlso/luna/idl_pros/mk4blue.rgb'
                    _a=bytarr(256)  &  _b=bytarr(256)  &  _c=bytarr(256)
                    readu,11,_a  &  readu,11,_b  &  readu,11,_c  &  close,11
                    tvlct,_a,_b,_c
                endif;}

                erase,0
                tv,bytscl(smlrpB0,mni,mxi)
                if(doanno eq 1) then begin ;{
                    Bsz=1.4
                    Lsz=1.15
                    Dsz=1.0
                    xyouts,  5, 5         ,'pB -- raw data ',$
                        size=Lsz,/dev,color=ccol
                    strt= 492
                    del = 17
                    xyouts,  5, strt-del*0,'MLSO/HAO/KCOR',$
                        size=Bsz,/dev,color=ccol
                    xyouts,  5, strt-del*1,'K-coronagraph',$
                        size=Lsz,/dev,color=ccol
                    strt=492
                    del = 17
                    xyouts,510,strt-del*0,date,$
                        size=Lsz,/dev,color=ccol,align=1.0
                    xyouts,510,strt-del*1,doy, $
                        size=Lsz,/dev,color=ccol,align=1.0
                    xyouts,510,strt-del*2,time,$
                        size=Lsz,/dev,color=ccol,align=1.0
                    xyouts,255,495,'North',    $
                        size=Dsz,/dev,color=ccol,align=0.5
                    xyouts, 20,255,'East',     $
                        size=Dsz,/dev,color=ccol,align=0.5,orien=90
                    xyouts,500,255,'West',     $
                        size=Dsz,/dev,color=ccol,align=0.5,orien=90
                endif;}

                zzz=tvrd()
                if(wrtgif eq 1)then write_gif,gfilenm,zzz,_a,_b,_c

                if(seegif eq 1) then begin;{
                    set_plot,'x'
                    tvlct,_a,_b,_c
                    tv,zzz
                    cursor,_x,_y
                    print,min(zzz),max(zzz)
                    set_plot,'z'
                    device,set_resolution=[512,512],$
                        set_colors=256,z_buffering=0
                endif;}
                
                set_plot,'x'
            endif;}
          endif;}
      endif;}
    end;}
    close,13
end
