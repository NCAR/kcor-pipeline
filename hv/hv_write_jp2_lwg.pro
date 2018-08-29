;+
; ji_write_jp2_lwg.pro
; write images in JPEG 2000 format, optionally include FITS header in
; XML format
;
;
; 2008-11-13 D. M., original [write_jp2.pro]
;
; 2009-01-23 Extensive edits by JI to accept hvs.sav files
; [ji_write_jp2.pro] 
;
; 2009-01-29 JI, added 'institute' and 'contact' required variables
;            to create a comment with attribution and creation
;            information in the JP2 file. [ji_write_jp2.pro]
;
; 2009-02-23 JI, implemented re-scaling of the images based on
;            contained in the FITS header as opposed to assuming
;            a fixed re-scaling for all files from a particular
;            observer.  Also implemented a minimal image embedding
;            when the data is written to JP2 file.  [ji_write_jp2.pro] 
;
; 2009-03-07 DM: Added option to include alpha channel. Since alpha
; channels are not supported in IDL's implementation of KDU, this requires
; compressing the images using kdu_compress outside of idl. Temporary
; .tif files are generated. The keyword alpha specifies a 1-bit .tif
; image containing the mask (alpha=0:transparent,alpha=1:not
; transparent)  [ji_write_jp2_dm.pro, never run in testing/production]
;
;
; 2009-03-23 JI: Removed explicit option to include alpha channel.
; Instead of this, the code looks for a tag called
; "hv_alpha_transparent" in the hvs file. If this tag is present, then
; the tag value is a binary value mask indicating which areas of the
; image are to be considered transparent, and which are not.  The code
; then calculates a tranpsarency mask based on the passed transparency
; mask and any embedding which may have occurred during processing.
; Putting a transparency (alpha) channel in the jp2 files requires the
; use of the Kakadu library, and so the program has been renamed to
; include "_kdu" to indicate that the program requires the Kakadu library.
; Hence the transparency mask is now calculated on an image by
; image basis, as and when is required.
; [ji_write_jp2_kdu.pro]
;
; 2009-05-05 JI: included lossless compression of alpha transparency
; mask
;
; 2009-05-07 TODO: remove the intermediate Kakadu step from processing
; transparency layers.  Apparently IDL can write JP2 files with
; arbitrary numbers of 'n' components (n,x,y).  Previously kakdu was
; used to implement this functionality
;
; 2009-05-12 JI: implemented the note of 2009-05-07,  IDL is now used
; to write the transparency mask as the 2nd component in a
; (2,nx_new,ny_new) image file.
;
; 2009-05-19 JI: added new tags to the <helioviewer></helioviewer> XML
; box. Now also included are details on the JP2 parameters used
; (bit_rate, etc), and if the image contains a alpha-transparency layer
;
; 2009-08-06 JI: renamed to ji_write_jp2_lwg.pro
; Major changes.  In previous versions of the code, the image was
; rescaled and recentred in order to make it easier for
; helioviewer.org to handle zooming, centering, etc.  However, since
; hv.org has to do a number of kdu_expand operations on the server
; side anyway, and JHV does not care, it is more or less redundant to
; have this preprocessing step.  Therefore, this preprocessing will be
; carried out inside JHV and on the helioviewer.org server.
;
;
; Required Inputs
; file = filename that the JP2 will be saved too
; image = 2 dimensional greyscale image
;
; OPTIONAL INPUTS
;
; bit_rate = JP2; bit_rate
; n_layers = JP2; number of layers
; n_levels = JP2; number of levels
;
; fitsheader = FITS header 
; head2struct = switch to convert the FITS header to a structure
;
;-

PRO HV_WRITE_JP2_LWG,file,image,bit_rate=bit_rate,n_layers=n_layers,n_levels=n_levels,fitsheader=fitsheader,quiet=quiet,kdu_lib_location=kdu_lib_location,details = details,measurement = measurement,reversible = reversible,_extra = _extra
;
  progname = 'HV_WRITE_JP2_LWG'
;
; Line feed character:
;
  lf=string(10b)
;
; Load in some general details
;
  g = HVS_GEN()
;
; set keyword "quiet" to suppress kdu_compress output
;
  IF KEYWORD_SET(quiet) THEN quiet_flag=' -quiet' else quiet_flag=''
;
; check to see if lossless compression was requested.  This is
; expressed by the REVERSIBLE property of the IDLffJPEG2000 object.
; If reversible is set to 1 (true) in the IDLffJPEG2000 object then a
; lossless compression is set.  See the IDL documentation for the
; effect the reversible property has on the bit_rate property.  In IDL
; IDL 7.1.1, the documentation states that
;
; "When the /REVERSIBLE switch is set the last rate will be
; automatically set to -1 to ensure that the last layer contains the
; bits needed to recreate the original image data."
;
  IF KEYWORD_SET(reversible) then reversible = 1 ELSE reversible = 0
;
; Get the header information
;
  IF keyword_set(fitsheader) EQ 0 THEN BEGIN
     print,'No FITS header provided - no meta information included in JP2 file.'
     image_new=bytscl(image)
     sz = size(image_new,/dim)
     nx = sz[0]
     ny = sz[1]
     obsdet = HV_OBSERVER_DETAILS('unknown_observer','unknown_measurement')
  ENDIF ELSE BEGIN
     image_new=bytscl(image)
     sz = size(image_new,/dim)
     nx = sz[0]
     ny = sz[1]
     IF not(is_struct(fitsheader)) THEN header = fitshead2struct(fitsheader) ELSE header = fitsheader
;
; Find which observation we are looking at
;
     observatory = details.observatory
     instrument = details.instrument
     detector = details.detector
;
     observer = observatory + '_' + instrument + '_' + detector
     observation = observer + '_' + measurement
;
; Get details on the observer, JP2 compression details, etc
;
     w = where(details.details.measurement eq measurement)
     if w[0] eq -1 then begin
        supported_yn = 0
        print,'Nickname = ' + details.nickname + ' with measurement = ' + $
              'not explicitly supported. Continuing.'
     endif else begin
        supported_yn = 1
        obsdet = details.details[w]
     endelse
;
; Is this observer supported?
;    
     if not(supported_yn) then begin
        print,'Unsupported observer.  Contining.'
     endif else begin
;
; Get contact details
;
        wby = HV_WRITTENBY()
;
; Set the JP2 compression details, override defaults if set from
; function call
;
     IF KEYWORD_SET(bit_rate) eq 0 THEN bit_rate = obsdet.bit_rate
     IF KEYWORD_SET(n_layers) eq 0 THEN n_layers = obsdet.n_layers
     IF KEYWORD_SET(n_levels) eq 0 THEN n_levels = obsdet.n_levels
     IF KEYWORD_SET(reversible) eq 0 THEN BEGIN
        if have_tag(obsdet,'reversible') then begin
           reversible = obsdet.reversible
        endif else begin
           reversible = 0
        endelse
     ENDIF
;
; Set where the KDU library is, if required
;
        IF KEYWORD_SET(kdu_lib_location) eq 0 THEN kdu_lib_location = wby.local.kdu_lib_location
;
; Set one colour to be transparent
;
        transcol = 0
        kdu_bit_rate = trim(bit_rate[0]) + ',' + trim(bit_rate[1])
;
; Who created this file and where
;
        hv_comment = 'JP2 file created locally at ' + wby.local.institute + $
                                       ' using '+ progname + $
                                       ' at ' + systime() + '.' + lf + $
                                       'Contact ' + wby.local.contact + $
                                       ' for more details/questions/comments regarding this JP2 file.'+lf
;
; Which setup file was used
;
        hv_comment = hv_comment + 'HVS (Helioviewer setup) file used to create this JP2 file: ' + $
                     details.hvs_details_filename + ' (version ' + details.hvs_details_filename_version + ').'+lf
;
; Source code attribution
;
        hv_comment = HV_XML_COMPLIANCE(hv_comment + $
                                       'FITS to JP2 source code provided by ' + g.source.contact + $
                                       '[' + g.source.institute + ']'+ $
                                       ' and is available for download at ' + g.source.jp2gen_code + '.' + lf + $
                                       'Please contact the source code providers if you suspect an error in the source code.' + lf + $
                                       'Full source code for the entire Helioviewer Project can be found at ' + g.source.all_code + '.')
;
; Finish up the Helioviewer comment by adding in any existing comment
;
        if tag_exist(header,'hv_comment') then begin
           hv_comment = HV_XML_COMPLIANCE(header.hv_comment) + lf + hv_comment
        endif
;
; ********************************************************************************************************
;
; Write the XML tags
;
;
;  FITS header into string in XML format:  
;
        xh = ''
; Line feed character:
        lf=string(10b)
;
        ntags = n_tags(header)
        tagnames = tag_names(header) 
        tagnames = HV_XML_COMPLIANCE(tagnames)
        jcomm = where(tagnames eq 'COMMENT')
        jhist = where(tagnames eq 'HISTORY')
        jhv = where(strupcase(strmid(tagnames[*],0,3)) eq 'HV_')
        jhva = where(strupcase(strmid(tagnames[*],0,4)) eq 'HVA_')
        indf1=where(tagnames eq 'TIME_D$OBS',ni1)
        if ni1 eq 1 then tagnames[indf1]='TIME-OBS'
        indf2=where(tagnames eq 'DATE_D$OBS',ni2)
        if ni2 eq 1 then tagnames[indf2]='DATE-OBS'     
        xh='<?xml version="1.0" encoding="UTF-8"?>'+lf
;
; Enclose all the FITS keywords in their own container
; 
        xh+='<meta>'+lf
;
; FITS keywords
;
        xh+='<fits>'+lf
        for j=0,ntags-1 do begin
           if ( (where(j eq jcomm) eq -1) and $
                (where(j eq jhist) eq -1) and $
                (where(j eq jhv) eq -1)   and $
                (where(j eq jhva) eq -1) )then begin      
;            xh+='<'+tagnames[j]+' descr="">'+strtrim(string(header.(j)),2)+'</'+tagnames[j]+'>'+lf
              value = HV_XML_COMPLIANCE(strtrim(string(header.(j)),2))
              xh+='<'+tagnames[j]+'>'+value+'</'+tagnames[j]+'>'+lf
           endif
        endfor
;
; FITS history
;
        xh+='<history>'+lf
        j=jhist
        k=0
        kmax = n_elements(header.(j))
        for k = 0, kmax-1 do begin
           value = HV_XML_COMPLIANCE((header.(j))[k])
           if value ne '' then begin
              xh+=value+lf
           endif
        endfor
        xh+='</history>'+lf
        ;while (header.(j))[k] ne '' and (k lt kmax) do begin
        ;   value = HV_XML_COMPLIANCE((header.(j))[k])
        ;   xh+=value+lf
        ;   k=k+1
        ;endwhile
        ;xh+='</history>'+lf
;
; FITS Comments
;
        if jcomm ne -1 then begin
           xh+='<comment>'+lf
           j=jcomm
           k=0
           kmax = n_elements(header.(j))
           for k = 0, kmax-1 do begin
              value = HV_XML_COMPLIANCE((header.(j))[k])
              if value ne '' then begin
                 xh+=value+lf
              endif
           endfor
           xh+='</comment>'+lf
        endif
        ;while (header.(j))[k] ne '' and (k lt kmax) do begin
        ;   value = HV_XML_COMPLIANCE((header.(j))[k])
        ;   xh+=value+lf
        ;   k=k+1
        ;endwhile
        ;xh+='</comment>'+lf
;
; Close the FITS information
;
        xh+='</fits>'+lf
;
; Explicitly encode the allowed Helioviewer JP2 tags
;
        xh+='<helioviewer>'+lf
;
; Helioviewer XML tags
;
        for j=0,ntags-1 do begin
           if (where(j eq jhv) ne -1) then begin 
              ;print,strmid(tagnames[j],0,3)
              if (strmid(tagnames[j],0,3) eq 'HV_') THEN BEGIN
                 reduced = HV_XML_COMPLIANCE( strtrim(tagnames[j],2) )
                 xh+='<'+reduced+'>'+HV_XML_COMPLIANCE(strtrim(string(header.(j)),2))+'</'+reduced+'>'+lf
              endif
           endif
        endfor
;
; Original rotation state
;
;        xh+='<HV_ROTATION>'+HV_XML_COMPLIANCE(strtrim(string(header.hv_rotation),2))+'</HV_ROTATION>'+lf
;
; JP2GEN version
;
;        xh+='<HV_JP2GEN_VERSION>'+HV_XML_COMPLIANCE(trim(g.source.jp2gen_version))+'</HV_JP2GEN_VERSION>'+lf
;
; JP2GEN branch revision
;
;        xh+='<HV_JP2GEN_BRANCH_REVISION>'+HV_XML_COMPLIANCE(trim(g.source.jp2gen_branch_revision))+'</HV_JP2GEN_BRANCH_REVISION>'+lf
;
; HVS setup file
;
;        xh+='<HV_HVS_DETAILS_FILENAME>'+HV_XML_COMPLIANCE(trim(details.hvs_details_filename))+'</HV_HVS_DETAILS_FILENAME>'+lf
;
; HVS setup file version
;
;        xh+='<HV_HVS_DETAILS_FILENAME_VERSION>'+HV_XML_COMPLIANCE(trim(details.hvs_details_filename_version))+'</HV_HVS_DETAILS_FILENAME_VERSION>'+lf
;
; JP2 comments
;
        xh+='<HV_COMMENT>'+hv_comment+'</HV_COMMENT>'+lf
;
; Explicit support from the Helioviewer Project
;
        if trim(supported_yn) THEN BEGIN
           xh+='<HV_SUPPORTED>TRUE</HV_SUPPORTED>'+lf
        ENDIF ELSE BEGIN
           xh+='<HV_SUPPORTED>FALSE</HV_SUPPORTED>'+lf           
        ENDELSE
;
; Explicitly show the reversible variable
;
        xh+='<HV_REVERSIBLE>'+trim(reversible)+'</HV_REVERSIBLE>'
;
; Is this a quicklook file or not?
;
        IF have_tag(header,'hv_quicklook') then begin
           xh+='<HV_QUICKLOOK>TRUE</HV_QUICKLOOK>'+lf
        ENDIF ELSE BEGIN
           xh+='<HV_QUICKLOOK>FALSE</HV_QUICKLOOK>'+lf
        ENDELSE

;
;        xh+='<BIT_RATE_FACTOR>'+trim(bit_rate_factor)+'</BIT_RATE_FACTOR>'+lf
;
;        IF have_tag(header,'hva_alpha_transparency') THEN BEGIN
;           xh+='<HV_ALPHA_TRANSPARENCY>TRUE</HV_ALPHA_TRANSPARENCY>'+lf
;           xh+='<ALPHA_TRANSPARENCY_YN>Alpha transparency included.' + $
;               'Two layer image (0,*,*) = image, ' + $
;               '(1,*,*) = alpha transparency layer</ALPHA_TRANSPARENCY_YN>'+lf
;        endif else begin
;           xh+='<HV_ALPHA_TRANSPARENCY>FALSE</HV_ALPHA_TRANSPARENCY>'+lf
;           xh+='<ALPHA_TRANSPARENCY_YN>No alpha transparency.' + $
;               'Single layer image.</ALPHA_TRANSPARENCY_YN>'+lf
;        endelse
;
; If the image is a coronograph then include the inner and outer radii
; of the coronagraph in solar radii
;
        if have_tag(header,'hv_rocc_inner') then begin
           xh+='<HV_ROCC_INNER>'+HV_XML_COMPLIANCE(trim(header.hv_rocc_inner))+'</HV_ROCC_INNER>'+lf
        endif
        if have_tag(header,'hv_rocc_outer') then begin
           xh+='<HV_ROCC_OUTER>'+HV_XML_COMPLIANCE(trim(header.hv_rocc_outer))+'</HV_ROCC_OUTER>'+lf
        endif
;
; If there is an error report, write that too
;
        if have_tag(header,'hv_error_report') then begin
           xh+='<HV_ERROR_REPORT>'+HV_XML_COMPLIANCE(trim(header.hv_error_report))+'</HV_ERROR_REPORT>'+lf
        endif
;
; JP2 specific tag names - number of layers, bit depth, etc
;
;        jp2_tag_names = tag_names(obsdet.jp2)
;        for i = 0,n_tags(obsdet.jp2)-1 do begin
;           tag_value = trim( gt_tagval(obsdet.jp2,jp2_tag_names[i]) )
;           if isarray(tag_value) then begin
;              xh+='<'+jp2_tag_names[i]+'>'
;              for j = 0,n_elements(tag_value)-1 do begin
;                 xh+='(' + tag_value[j] + ')'
;              endfor
;              xh+='</'+jp2_tag_names[i]+'>'+lf
;           endif else begin
;              xh+='<'+jp2_tag_names[i]+'>' + tag_value    + '</'+jp2_tag_names[i]+'>'+lf
;           endelse
;        endfor
;        xh+='</Helioviewer>'+lf
;
; Close the Helioviewer information
;
        xh+='</helioviewer>'+lf
;
; Enclose all the XML elements in their own container
;
        xh+='</meta>'+lf
;

   endelse

; end of FITS header loop:
  ENDELSE 

;
; If the image has an alpha channel transparency mask supplied with
; it, then we need to use the KDU library.  If not, then we just use
; the inbuilt IDL methods for writing JP2
;
  if supported_yn then begin
     IF have_tag(header,'hva_alpha_transparency') THEN BEGIN
;
; Adjust the passed mask with the same processing that was done to the
; image data
;
;;      mask_congrid = congrid(header.hva_alpha_transparency,hv_xlen,hv_ylen)
;;      mc_lz = where(mask_congrid lt 1.0)
;;      mask_congrid(mc_lz) = 0
;;      mask_new = bytarr(nx_embed,ny_embed)
;;      mask_new(x1:x2,y1:y2) = mask_congrid(*,*)
;;      mask_new = mask_new( nx_embed/2 - hv_xlen/2 - mlen:$
;;                           nx_embed/2 + hv_xlen/2 + mlen-1,$
;;                           ny_embed/2 - hv_ylen/2 - mlen:$
;;                           ny_embed/2 + hv_ylen/2 + mlen-1)
        mask_new = header.hva_alpha_transparency
;
; Create a mask indicating where the transparency is located, taking
; into account the previously passed mask, mask_new, and any embedding
; that may have been done above
;
        tmask = float(image_new) - 1.0
        tmask_index = where(tmask eq -1.0, count)
        temp_alpha = 255 + bytarr(nx,ny)
        IF (count gt 0) then begin
           temp_alpha(tmask_index) = 0
           mask_new_index = where(mask_new eq 0,count)
           IF (count gt 0) then begin
              temp_alpha(mask_new_index) = 0
           ENDIF
        ENDIF
;
; REQUIRED BY KDU: Write the transparency locations as a temporary tiff file.
;
;     temp_alpha_filename = observation + '_alpha_temp.tif'
;     write_tiff,temp_alpha_filename,reverse(temp_alpha,2),bits=8
;
; REQUIRED BY KDU: Write temporary image TIFF file
;
;    temp_image_filename = observation + '_image_temp.tif'
;     write_tiff,temp_image_filename,reverse(image_new,2),bits=8
;
; REQUIRED BY KDU: Create JP2 file by spawning kdu_compress outside of idl.
; REQUIRED BY KDU: Write meta data into XML file:
;
;     IF KEYWORD_SET(fitsheader) THEN BEGIN
;        meta_xml = observation + '_meta.xml'
;        openw,1,meta_xml
;        printf,1,lf+xh
;        close,1
;     ENDIF
;
; REQUIRED BY KDU
; If alpha channel is provided, pass it on to kdu_compress to create a
; 2-component JP2 file
;
;     IF KEYWORD_SET(alpha) THEN BEGIN 
;     data_in = '-jp2_alpha -i ' + temp_image_filename + ',' + temp_alpha_filename
;     ENDIF ELSE BEGIN
;        data_in = '-i ' + temp_image_filename
;     ENDELSE
;     data_out=' -o '+file+'.jp2'
;
; Create the option for including meta data
;
;     IF KEYWORD_SET(fitsheader) eq 0 THEN meta_data='' ELSE meta_data=' -jp2_box '+meta_xml
;
; Create the KDU command and spawn it
;
;     kdu_command='kdu_compress ' + data_in + data_out + $
;                 ' Creversible:C0=no Creversible:C1=yes' + $
;                 ' Clayers=' + strtrim(string(n_layers),2) + $
;                 ' Clevels=' + strtrim(string(n_levels),2) + $
;                 ' -rate '   + kdu_bit_rate + meta_data + quiet_flag
;     spawn,kdu_lib_location + kdu_command
;     print,'Executing '+ kdu_lib_location + kdu_command
;

;
; REQUIRED BY KDU
; Due to exiftool not being able to read the XML box created by
; Kakadu, we re-read the JPEG2000 file using IDL.  IDL is able to
; write out a JPEG200 file with a well formed XML box that exiftool
; can read.
;
;     reloaded = READ_JPEG2000(file + '.jp2')
;     oJP2 = OBJ_NEW('IDLffJPEG2000',file + '.jp2',/WRITE,$
;                    bit_rate=bit_rate,$
;                    n_layers=n_layers,$
;                    n_levels=n_levels,$
;                    xml=xh)
;     oJP2->SetData,reloaded
;     OBJ_DESTROY, oJP2
;     print,' '
;     print,progname + ' created ' + file + '.jp2'
;
; Remove the temporary transparency file
;
;     spawn,'rm '+ temp_alpha_filename
;
; Remove the temporary tif file as default
;
;     IF KEYWORD_SET(keep_tif) eq 0 THEN spawn,'rm '+ temp_image_filename
;
; Remove the temporary xml file as default
;
;     IF KEYWORD_SET(fitsheader) and (KEYWORD_SET(keep_xml) eq 0) THEN spawn,'rm '+meta_xml

;
; 2009-05-12:  IDL can write images with an arbitrary number of
; components.  We put the alpha transparency in as the second component.
;
        image_new_with_transparency = bytarr(2,nx,ny)
        image_new_with_transparency(0,*,*) = image_new(*,*)
        image_new_with_transparency(1,*,*) = temp_alpha(*,*)

        if have_tag(details.details,'palette') then begin
           oJP2 = OBJ_NEW('IDLffJPEG2000',file + '.jp2',/WRITE,$
                       bit_rate=bit_rate,$
                       n_layers=n_layers,$
                       n_levels=n_levels,$
                       PROGRESSION = 'RPCL',$
                       palette = obsdet.palette,$
                       xml=xh)
        endif else begin
           oJP2 = OBJ_NEW('IDLffJPEG2000',file + '.jp2',/WRITE,$
                          bit_rate=bit_rate,$
                          n_layers=n_layers,$
                          n_levels=n_levels,$
                          PROGRESSION = 'RPCL',$
                          xml=xh)
        endelse

        ;oJP2 = OBJ_NEW('IDLffJPEG2000',file + '.jp2',/WRITE,$
        ;               bit_rate=bit_rate,$
        ;               n_layers=n_layers,$
        ;               n_levels=n_levels,$
        ;               PROGRESSION = 'RPCL',$
        ;               xml=xh)
;
        oJP2->SetData,image_new_with_transparency
        OBJ_DESTROY, oJP2
        print,' '
        print,progname + ' created ' + file + '.jp2'
;
; Change the permissions on the file
;

     ENDIF ELSE BEGIN
;
; create JP2 file
; this is how it is done inside IDL.  Note that the current
; implementation of JPEG2000 in IDL 7.0 does not support alpha channel
; No transparencey mask was passed, so just use normal IDL routines.
;
        if have_tag(details.details,'palette') then begin
           oJP2 = OBJ_NEW('IDLffJPEG2000',file + '.jp2',/WRITE,$
                       bit_rate=bit_rate,$
                       n_layers=n_layers,$
                       n_levels=n_levels,$
                       PROGRESSION = 'RPCL',$
                       palette = obsdet.palette,$
                       xml=xh)
        endif else begin
           oJP2 = OBJ_NEW('IDLffJPEG2000',file + '.jp2',/WRITE,$
                          bit_rate=bit_rate,$
                          n_layers=n_layers,$
                          n_levels=n_levels,$
                          PROGRESSION = 'RPCL',$
                          xml=xh)
        endelse
;
        oJP2->SetData,image_new
        OBJ_DESTROY, oJP2
        print,' '
        print,progname + ' created ' + file + '.jp2'
     ENDELSE
  ENDIF

END
