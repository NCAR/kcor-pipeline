;
; Very simple check that the input is compliant with XML standards and
; escape it if need be
;
FUNCTION HV_XML_COMPLIANCE,input
  answer = str_replace(input,'<','&lt;')
  answer = str_replace(answer,'>','&gt;')
  answer = str_replace(answer,'&','&amp;')
;  answer = str_replace(answer,'','&apos')
  answer = str_replace(answer,'"','&quot;')

  ; Test for the presence of control characters and replace them
  for i = 1B, 31B do begin
     test =  STRING(i)
     instring = STRPOS(answer,test)
     if instring[0] ne -1 then begin
        answer =  str_replace(answer, test, '(ASCII character value=' + trim(nint(i)) + ')')
     endif
  endfor
  return,answer
end
