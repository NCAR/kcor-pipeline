; docformat = 'rst'

;+
; Very simple check that the input is compliant with XML standards and
; escape it if need be.
;
; :Params:
;   input : in, required, type=string
;     input string to check
;-
function hv_xml_compliance, input
  compile_opt strictarr

  answer = str_replace(input, '<', '&lt;')
  answer = str_replace(answer, '>', '&gt;')
  answer = str_replace(answer, '&', '&amp;')
  ;  answer = str_replace(answer,'','&apos')
  answer = str_replace(answer, '"', '&quot;')

  ; test for the presence of control characters and replace them
  for i = 1B, 31B do begin
    test = string(i)
    instring = strpos(answer,test)
    if (instring[0] ne -1) then begin
      answer =  str_replace(answer, test, $
                            '(ASCII character value=' + trim(nint(i)) + ')')
    endif
  endfor

  return,answer
end
