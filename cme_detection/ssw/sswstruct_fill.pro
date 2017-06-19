function sswstruct_fill, sswstr, loud=loud, debug=debug, $
	       solar=solar, time=time, pointing=pointing, $
	       nosolar=nosolar, notime=notime, nopointing=nopointing, $
               _extra=_extra, xcen_ycen=xcen_ycen
;+
;   Name: sswstruct_fill
;
;   Purpose: fill missing SSW tags , if possible
;
;   Input Parameters:
;      sswstr - Structure vector, usually including SSW standards
;
;   Keyword Parameters:
;      nosolar    - if set, do not fill in Solar ephemeris tags
;      notime     - if set, do not fill in Time tags
;      nopointing - if set, do not fill in Pointing tags
;      xxx=value  - where XXX =standard tag name, fill with VALUE
;
;   Category:
;      structure , SSW , time , alignment
;
;   History:
;      24-October-1998 - S.L.Freeland - combine common function
;      25-October-1998 - S.L.Freeland - allow explicit pass via keyword inherit
;      27-November-1998 - D.M. Zarro - made more FITS standard compliant
;      2-December-1998 - Zarro - removed case block for modifying CRVAL
;                        as this caused downstream problems.
;      7-Januaray-1999 - S.L.Freeland - auto flip date if DATE-OBS
;                        uses old FITS standard
;     12-Januaray-1999 - S.L.Freeland - fill in HXT/HXI part
;     20-Januaray-1999 - S.L.Freeland - fix variable typo name for HXI conv.
;     25-feb-1999 - S.L.Freeland - add CROTA for sxt
;      2-Mar-1999 - S.L.Freeland - use 'str2number' instead of st2num
;                                  for DATE-OBS/TIME-OBS->SSW check
;     17-apr-1999 - S.L.Freeland - check SXT history for roll correction
;     22-apr-1999 - S.L.Freeland - pass ROLL/CROTA->gt_center
;     11-aug-1999 - S.L.Freeland - fixed a logic error in XCEN/YCEN->ssw derivation
;     8-Oct-2001 - Zarro (EITI/GSFC) - added logic that if roll correction
;                is not applied, then do not roll center fov
;    18-Mar-2002 - S.L.Freeland - relax DATE_OBS verification (iso change?)
;    24-Nov-2002 - Zarro(EER)/Biesecker(NOAA) - fixed degenerate structure dimension error
;     4-jan-2006 - S.L.Freeland (this modification was added lately by Aki Takeda, 
;                                to unify the different versions. Mar-2013)
;                               - add /XCEN_YCEN (force use of xcen, ycen even if [0,0])
;    10-Jun-2008 - L. Acton - Test for true_FFI before centerfov computed.
;    17-Aug-2008 - Aki Takeda - Fill the SOLAR_R tag if not /nosolar set. 
;    16-Jan-2009 - S.L.Freeland - croata1/crota2 roll for sxt logic
;                                 add call_function wrapper for no-sxt in path 
;     3-May-2009 - Aki T - Added /use_history to the gt_center call. 
;     8-May-2013 - LWA - Added /quiet in calls to get_rb0p.
;-

if not data_chk(sswstr,/struct) then begin
   box_message,['Structure input required...', $
	'IDL> sswfilled=sswstruct_fill(sswstructs [,/nosolar,/notime] )']
endif

debug=keyword_set(debug)
loud=keyword_set(loud)

; check for a minimal subset of SSW tags - if not present, add them...
reqtags='crpix1,cdelt1,time,day,mjd,date_obs,exptime,naxis1,naxis2,xcen,ycen'
if required_tags(sswstr,reqtags) then begin
   retval=sswstr
endif else begin
   if loud then box_message,'Some "standards" missing, generating full template'
   retval=struct2ssw(sswstr)
endelse
 retval=reform(retval)

rettags=tag_names(retval)
 
xcen_ycen=keyword_set(xcen_ycen)

; -------- fill keyword inherited tag ----
if data_chk(_extra,/struct) then begin
   etags=tag_names(_extra)
   netags=n_elements(etags)
   for i=0,netags-1 do begin
     etind=(tag_index(retval,etags(i)))(0)
     if etind ne -1 then retval.(etind)=_extra.(i)    ; keyword->structure
   endfor
endif

if not keyword_set(notime) then begin
; ---------------------- TIME TAGS ----------------------
;   find a time standard and put it in a common format

   dobs= gt_tagval(retval,/date_obs,missing='')
   dobscnt=total(strpos(dobs,'T') ne -1)
   t$obs=gt_tagval(retval,id_esc('time-obs'),missing='')
   d$obs=strtrim(gt_tagval(retval,id_esc('date-obs'),missing=''),2)
   ; flip date if required...
   if (str2number(strmid(d$obs(0),0,2)))(0) le 31 and strlen(d$obs(0)) gt 5 then begin
      d$obs=flipdate(d$obs)
   endif
   d$obs=strtrim(d$obs + ' ' + t$obs,2)
   case 1 of
      rettags(0) eq 'GEN' and data_chk(retval.(0),/struct): tstand=anytim(retval.(0),/utc_int)
      min(gt_tagval(retval,/mjd)) gt 0: tstand=anytim(retval,/utc_int) ; utcint
      min(gt_tagval(retval,/day)) gt 0 :tstand=anytim(anytim2ints(retval),/utc_int) ; intern.
      min(strlen(dobs)) ge 23 and dobscnt eq n_elements(dobs): tstand=anytim(dobs,/utc_int)            ; ccsds
      min(strlen(d$obs)) gt 5: begin
        box_message,'Warning - no SSW Time standards , deriving from FITS DATE-OBS/TIME-OBS'
        tstand=anytim(d$obs,/utc_int)                                 ; fits?
      endcase
      else: begin
        box_message,'Could not determine time tags, returning...'
        return, retval
      endcase
   endcase

; ----------- now fill in time fields from derived standard --------------
   days=anytim(tstand,/int)
   dobs=anytim(tstand,/ccsds)
   retval.day=days.day
   retval.date_obs=dobs
   retval.time=tstand.time
   retval.mjd=tstand.mjd
endif                        ; ------- end TIME block ------------


; ------------------ POINTING TAGS -----------------

genindex=tag_index(retval,'GEN')
if not keyword_set(nopointing) then begin        ; 3 possible "standards"
   naxis1=gt_tagval(retval,/naxis1,missing=0.)
   naxis2=gt_tagval(retval,/naxis2,missing=0.)
   crval1=gt_tagval(retval,/crval1,missing=0.)
   crval2=gt_tagval(retval,/crval2,missing=0.)
   crpix1=gt_tagval(retval,/crpix1,missing=0.)
   crpix2=gt_tagval(retval,/crpix2,missing=0.)
   cdelt1=gt_tagval(retval,/cdelt1,missing=0.)
   cdelt2=gt_tagval(retval,/cdelt2,missing=0.)
   xcen=gt_tagval(retval,/xcen,missing=0.)
   ycen=gt_tagval(retval,/ycen,missing=0.)
   shape=gt_tagval(retval,/shape_sav,missing=0.)

   case 1 of
     (max(abs(xcen)) gt 0) or (max(abs(ycen)) gt 0) or xcen_ycen: begin
        if loud then box_message,'Using XCEN/YCEN conversions'
        crpix1=comp_fits_crpix(xcen,cdelt1,naxis1,crval1)
        crpix2=comp_fits_crpix(ycen,cdelt2,naxis2,crval2)
        retval.crpix1=crpix1
        retval.crpix2=crpix2
   endcase

;   max(abs(crval1)) gt 0 or max(abs(crval2)) gt 0: begin
;        if loud then box_message,'Using CRVAL/CRPIX conversions'
;       retval.crpix1=crval1-crpix1  ! can't really do this since units differ
;	retval.crpix2=crval2-crpix2
;	retval.crval1=0.
;	retval.crval2=0.
;        crpix1=comp_fits_crpix(xcen,cdelt1,naxis1,retval.crval1)
;        crpix2=comp_fits_crpix(ycen,cdelt2,naxis2,retval.crval2)
;   endcase

   max(abs(crpix1)) gt 0 or max(abs(crpix2)) gt 0: begin
        if loud then box_message,'Using CRPIX conversions'
        xcen=comp_fits_cen(crpix1,cdelt1,naxis1,crval1)
        ycen=comp_fits_cen(crpix2,cdelt2,naxis2,crval2)
        retval.xcen=xcen
	retval.ycen=ycen
     endcase
     genindex ge 0 and max(shape) gt 0: begin  ; Yohkoh (SXT/HXT ) standard
       retval.telescop='Yohkoh'
       retval.instrume=rettags(genindex+1)
       case 1 of
	   tag_index(retval,'SXT') ne -1: begin
              retval.naxis=2
              sz_shape=size(shape)
              if sz_shape(0) eq 3 then begin	; Added by DAB to correct apparent error
               retval.naxis1=reform(shape(0,0,*))
               retval.naxis2=reform(shape(1,0,*))
              endif else begin
	       retval.naxis1=reform(shape(0,*))
	       retval.naxis2=reform(shape(1,*))
	      endelse
              rollcorr=gt_tagval(retval,/q_roll_corr,miss=0)
              corrss =where(rollcorr ne 0,ccnt)
	      ncorrss=where(rollcorr eq 0,nccnt)
              
	      if ccnt gt 0 then begin
                 retval(corrss).crota1=0.0
                 retval(corrss).crota2=0.0
              endif    
                  
              if nccnt gt 0 then begin 
                 roll=get_roll(retval(ncorrss))
                 retval(ncorrss).crota1=roll
                 retval(ncorrss).crota2=roll
              endif 

;-- if roll correction is not applied, then don't apply roll to center fov

              temp=retval.crota2*0.
	      ffi=call_function('gt_pfi_ffi',retval,/true_ffi)
	      ffi=ffi(0)
              if ccnt gt 0 and NOT ffi then $
	         temp(corrss)=get_roll(retval(corrss))
;              centerfov=call_function('gt_center',retval,/ang,/pfi,roll=temp)
; (3-May-2009)             
              centerfov=call_function('gt_center',retval,/ang,/pfi,roll=temp,/use_history)

	      retval.xcen=reform(centerfov(0,*))
	      retval.ycen=reform(centerfov(1,*))
              retval.cdelt1=gt_pix_size(retval)
	      retval.cdelt2=gt_pix_size(retval)
              retval.crval1=0.
              retval.crpix1=$
       comp_fits_crpix(retval.xcen,retval.cdelt1,retval.naxis1,retval.crval1)
              retval.crval2=0.
              retval.crpix2=$
       comp_fits_crpix(retval.ycen,retval.cdelt2,retval.naxis2,retval.crval2)
              retval.cunit1='arcsec'
              retval.cunit2='arcsec'
              retval.wavelnth=call_function('gt_filtb',retval,/string)
              retval.exptime=gt_expdur(retval)/1000.
	   endcase
	   tag_Index(retval,'HXI') ne -1: begin
               box_message,'HXT Image (HXI)  Index...'
               retval.crota2=get_roll(retval)

               sz_shape=size(shape)
               if sz_shape(0) eq 3 then begin
                retval.naxis1=reform(shape(0,0,*))
                retval.naxis2=reform(shape(1,0,*))
               endif else begin
	        retval.naxis1=reform(shape(0,*))
	        retval.naxis2=reform(shape(1,*))
	       endelse

;              -------- xcen/ycen code borrowed from mk_hxi_map	-----------
               hh = fltarr(2, n_elements(retval))
               hh(0, *) = gt_tagval(retval,/x0)
               hh(1, *) = gt_tagval(retval,/y0)
               xcyc = conv_hxt2a(hh, retval)
               retval.xcen=reform(xcyc(0, *))      ;center position in arcseconds
               retval.ycen=reform(xcyc(1, *))
               retval.cdelt1= gt_tagval(retval,/resolution)/1000.0 ;pixel size in arcsec
               retval.cdelt2=retval.cdelt1
               retval.crval1=0.
               retval.crpix1=$
              comp_fits_crpix(retval.xcen,retval.cdelt1,retval.naxis1,retval.crval1)
              retval.crval2=0.
              retval.crpix2=$
              comp_fits_crpix(retval.ycen,retval.cdelt2,retval.naxis2,retval.crval2)
              retval.cunit1='arcsec'
              retval.cunit2='arcsec'
              hchan='HXT/HXI ' + ['LO', 'M1', 'M2', 'HI']
              retval.wavelnth=reform(hchan( gt_tagval(retval,/chan)<3>0))
              retval.exptime=gt_tagval(retval,/actim)/10.
	   endcase
	   else: box_message,"Unknown structure, cannot determine pointing convention"
	endcase
     endcase
     else:begin
       box_message,'Warning - could not determine pointing coordinates'
     endcase
   endcase
endif                        ; end of POINTING block -----------------

if not debug then $
    delvarx,naxis1,naxis2,crpix1,crpix2,crval1,crval2,cdelt1,cdelt2

if not keyword_set(nosolar) then begin
    retval.solar_r=get_rb0p(retval,/radius,/quiet)             ; 17-Aug-2008
;----------------------------------------------------------------- 7-Mar-2013
    retval.solar_b0=get_rb0p(retval,/b0,/deg,/quiet) 
    rsun_meters=6.95508e8
    retval.dsun_obs=rsun_meters/((!dpi/180.d0) * retval.solar_r/3600.d0)
;----------------------------------------------------------------- 7-Mar-2013

endif

; --------------- Miscellaneous ------------------

;           SSWTAG:     |-------------SYNONYMS----------------|
synonyms=[                                                       $
           'exptime:    mshut_dur,expdur                      ', $
           'wavelnth:   wave_len,wave,filter,                 ', $
           'crota:      roll                                  '  ]

synlist=str2cols(synonyms,':',/trim,/unaligned)

mtags=reform(synlist(0,*))

; ---- for each tag, fill in with synonyms --------
for i=0,n_elements(mtags)-1 do begin
  synx=str2arr(strcompress(synlist(1,i),/remove))
  tagval=gt_tagval(retval,mtags(i),missing='')
  nsyns=n_elements(synx)
endfor

return,retval
end


