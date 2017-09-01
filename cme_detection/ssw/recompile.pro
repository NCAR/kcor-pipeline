;+
; Project     : SOHO - CDS
;
; Name        : RECOMPILE
;
; Purpose     : recompile a routine
;
; Category    : utility
;
; Explanation : a shell around RESOLVE_ROUTINE (> vers 4) that checks
;               if compiled routine is not recursive, otherwise 
;               recompile will stop suddenly.
;
; Syntax      : IDL> recompile,proc
;
; Inputs      : PROC = procedure name
;
;
; Keywords    : /IS_FUNCTION - set if routine is a function
;               /SKIP - set to skip if already compiled
;               /QUIET - set to not show compile messages
;
; Side effects: PROC is recompiled
;
; History     : 1-Sep-1996,  Zarro (ARC/GSFC)  Written
;               20-May-1999, Zarro (SM&A/GSFC) - added /SKIP 
;               12-Aug-2000, Zarro (EIT/GSFC) - added /QUIET
;               7-Sept-2001, Zarro (EIT/GSFC) - added check for 
;                existing file
;               21-Dec-2016, Zarro (ADNET) - added /COMPILE_FULL
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

pro recompile,proc,is_function=is_function,status=status,skip=skip,$
               quiet=quiet,_extra=extra

status=0b
if is_blank(proc) then return

;-- get list of compiled routines if planning to skip

skip=keyword_set(skip)
if skip then begin
 compiled=routine_info()
 compiled=[compiled,routine_info(/functions)]
 compiled=strtrim(strlowcase(compiled),2)
endif

nproc=n_elements(proc)
for i=0,n_elements(proc)-1 do begin
 status=0b
 if have_proc(proc[i]) then begin
  break_file,proc[i],dsk,dir,name,ext
  name=strlowcase(name)
  doit=1
  if skip then begin
   chk=where(name eq compiled,count)
   if count gt 0 then begin
    dprint,'% RECOMPILE: '+'"'+name+'"'+' already compiled'
    doit=0 
   endif
  endif
 
;-- can't compile if called recursively

  if doit && was_called(name) then begin
;   dprint,'% RECOMPILE: '+'"'+proc[i]+'"'+' being called recursively. Cannot compile.'
   doit=0
  endif

  quiet=keyword_set(quiet)
  if doit then begin
   if quiet then begin
    squiet=!quiet
    !quiet=1
   endif
   resolve_routine,name,/either,/compile_full,_extra=extra
   if quiet then !quiet=squiet
   status=1b
  endif
 endif
endfor

return & end
