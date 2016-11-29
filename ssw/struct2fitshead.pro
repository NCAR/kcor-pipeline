function struct2fitshead, hdrstr, data, comments=comments,        $
	 use_sxaddpar=use_sxaddpar, use_fxaddpar=use_fxaddpar,    $
         allow_crota=allow_crota, _extra=_extra, dateunderscore2dash=dateunderscore2dash
;+
;   Name: struct2fitshead
;
;   Purpose: Map FITS Header-Structure structure back-> fits header (strarr)
;
;   Input Parameters:
;      hdrstr - IDL structure to map into fits header (ex: output of mreadfits)
;      data - Data array associated with fits header.  If not passed, then the
;             relevant parameters are taken from hdrstr, if available.  It's
;             highly recommended that data be passed.
;
;   Output:
;      function returns FITS header derived from structure
;
;   Calling Sequence:
;      header=struct2fitshead(structure [, data])
;
;   Calling Example:
;	mreadfits,f,hdr,data
;	ahdr = struct2fitshead(hdr(0))
;	writefits,"new-"+f(0),f(0),ahdr
;
;   Keywords:
;       USE_SXADDPAR    = Use the routine SXADDPAR
;       USE_FXADDPAR    = Use the routine FXADDPAR
;       ALLOW_CROTA     = Allow CROTA to be written to the FITS header.
;                         Normally, the non-standard keyword CROTA is
;                         translated into the standard keyword CROTA2.  Using
;                         /ALLOW_CROTA disables this check to enable CROTA to
;                         coexist with World Coordinate System PC matrices.
;	DATEUNDERSCORE2DASH = If tag contains 'DATE_', replace with 'DATE-' for 
;			  FITS compatibility
;   History:
;      Craig DeForrest w/S.L.Freeland - 11-apr-1997
;      2-March-1998 - S.L.Freeland add some error checking...
;                     add /USE_SXADDPAR keyword (eventual default?)
;                     (default if NAXIS etc missing - just do it)
;      6-Mar-1998 - S.L.Freeland - add COMMENTS input keyword
;      6-May-1998 - S.L.Freeland - ORDER a few standard FITS
;     23-Jun-1998 - C.E. DeForest - call ID_UNESC before stuffing the tags 
;		    into the fits header (complements ID_ESC in fitshead2struct).
;      3-Feb-2000 - S.L.Freeland - NOTE: made USE_SXADDPAR the default
;                                  (more forgiving about TAG contents/order)
;
;      10-Jul-2003, William Thompson - Treat CROTA1/CROTA2 correctly
;      23-Sep-2004, William Thompson - Rewrite to form FITS header correctly,
;                                      using fxhmake and fxhclean.
;                                      Added data as input parameter.
;                                      Made use_fxaddpar a keyword.
;      27-Sep-2004, William Thompson - Put in backward compatibility for
;                                      passing use_fxaddpar as a parameter.
;                                      Allow keywords to fxhmake.
;      10-Jan-2006, William Thompson - Added /ALLOW_CROTA.  Changed translation
;                                      to CROTA2, which is the actual standard
;      17-Feb-2006, William Thompson - Ignore substructs, pointers, obj refs
;                                      (e.g. WCS_POINTER)
;   Calls:
;      fxaddpar, sxaddpar, fxhmake
;
;-
common struct2fitshead_blk, lastproc

if not data_chk(hdrstr,/struct) then begin
   box_message,['Structure required','IDL> header=struct2fitshead(structure)']
   return,''
endif

;  Decide whether data or the old form of use_fxaddpar was passed.

data_passed = n_elements(data) ne 0
if (n_elements(data) eq 1) and (n_elements(use_fxaddpar) eq 0) then begin
    use_fxaddpar = data
    data_passed = 0
endif

;  validity check (sxaddpar permits 'malformed' headers, ok in many applications
vindex=where(tag_index(hdrstr,str2arr('BITPIX,NAXIS,NAXIS1')) eq -1,ivcnt)
use_fxaddpar=keyword_set(use_fxaddpar) 
use_sxaddpar=1-use_fxaddpar                      ; default='sxaddpar'
addproc=(['fxaddpar','sxaddpar'])(use_sxaddpar)  ; choose procedure

if n_elements(lastproc) eq 0 then lastproc=''
if lastproc ne addproc then begin
   box_message,'struct2fitshead - using procedure: ' + addproc
   lastproc=addproc
endif  

;if addproc eq 'sxaddpar' then ohdr=strarr(1)              ; diff initial val
fxhmake, ohdr                                   ;Make initial basic header.

tags = tag_names(hdrstr)
ntags=n_elements(tags)

coms=strarr(ntags)
if n_elements(comments) eq ntags then coms=comments       ; user supplied

IF keyword_set(DATEUNDERSCORE2DASH) THEN FOR j=0,ntags-1 DO BEGIN
	tagj=tags[j]
	loc=strpos(tagj,'DATE_')
	IF loc GE 0 THEN BEGIN
		strput,tagj,'DATE-',loc
		tags[j]=tagj
	ENDIF
ENDFOR	; nbr, 7/20/06
	
for i=0,n_elements(tags)-1 do begin
   value=hdrstr.(i)
   data_type = data_chk(value,/type)
;
;  Don't try to process structures, pointers, or object references.
;
   if (data_type ne 8) and (data_type ne 10) and (data_type ne 11) then begin
       if n_elements(value) gt 1 then begin               ; comment&history
           nonnulls=where(strtrim(value,2) ne '',nncnt)
           for j=0,nncnt-1 do begin
               tagname = id_unesc(tags(i))
               if (tagname eq 'CROTA') and (not keyword_set(allow_crota)) $
                 then tagname = 'CROTA2'
               tagvalue = (hdrstr.(i))(nonnulls(j))
               call_procedure,addproc,ohdr,tagname,tagvalue
           endfor
       endif else begin
           if data_type eq 1 then value=fix(value)

      ;; --- check for 1-element array for IDL > 5.5 (HPW 19-Feb-2003)
           sz = size(value)
           if sz[0] eq 1 and sz[1] eq 1 then value = value[0]
           tagname = id_unesc(tags(i))
           if (tagname eq 'CROTA') and (not keyword_set(allow_crota)) then $
             tagname = 'CROTA2'
           call_procedure, addproc, ohdr, tagname, value, coms(i)
       endelse
   endif
endfor

; minimal standard ordering
;fitsstand=strupcase(str2arr('simple,bitpix,naxis,naxis1,naxis2,naxis3'))
;movepat='????'
;for i=n_elements(fitsstand)-1,0, -1 do begin
;  chk=where(strpos(ohdr,fitsstand(i)) ne -1, ccnt)
;  if ccnt gt 0 then begin
;     prelines=ohdr(chk)
;     ohdr(chk)=movepat
;     ohdr=[prelines,ohdr]
;   endif    
;   ohdr=ohdr(where(ohdr ne movepat))
;endfor

;
;  Clean up any of the FITS keywords related to the structure of the FITS file,
;  and recreate them based on the data array.
;
if data_passed then fxhmake, ohdr, data, _extra=_extra else begin
    fxhmake, ohdr, _extra=_extra
    if tag_exist(hdrstr,'bitpix') then  $
      fxaddpar, ohdr, 'BITPIX', hdrstr.bitpix, after='SIMPLE'
    if tag_exist(hdrstr,'naxis') then begin
        naxis = hdrstr.naxis
        fxaddpar, ohdr, 'NAXIS', naxis, after='BITPIX'
        last = 'NAXIS'
        for i=1,hdrstr.naxis do begin
            naxisi = 'NAXIS'+ntrim(i)
            axis = 1
            if tag_exist(hdrstr,naxisi,index=j) then axis = hdrstr.(j)
            fxaddpar, ohdr, naxisi, axis, after=last
            last = naxisi
        endfor
    endif
endelse
;
;  Make sure the header isn't too long.
;
endline = (where(strmid(ohdr,0,8) eq 'END     '))[0]
ohdr = ohdr(0:endline)
return,ohdr
end
