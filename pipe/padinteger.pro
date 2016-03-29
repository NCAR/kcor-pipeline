;+
; NAME:
; PADINTEGER
;
; PURPOSE:
; Use this function to convert an integer to string with leading zeros.
;
; CALLING SEQUENCE:
;  result = PADINTEGER(value, width, $
;       [TYPE = value], [FORMAT =  variable])
;
; ARGUMENTS:
;  VALUE the values to be converted, may be an array
;  WIDTH  the width of the output string (default = 2)
;
; OPTIONAL KEYWORDS:
; FORMAT set this keyword to a named variable to return the
;       format specifier created for the integer-to-string conversion.
;
; TYPE Set this keyword to a type value flag. Options are...
;       'I' for decimal integers (the default)
;       'O' for octal intergers
;       'Z' for hexidecimal integers
;
; EXAMPLE:
;       IDL> print, padinteger(indgen(12),4)
;       0000 0001 0002 0003 0004 0005 0006 0007 0008 0009 0010 0011
;
;       IDL> print, padinteger(findgen(12),4, type = 'z')
;       0000 0001 0002 0003 0004 0005 0006 0007 0008 0009 000a 000b
;
; AUTHOR:
;      Ben Tupper
;      Bigelow Laboratory for Ocean Science
;      180 McKown Point Road
;      POB 475
;      West Boothbay Harbor, Me, 04575-0475
;-


FUNCTION PadInteger, value, width, $
        type = type, $
        format = format


If n_elements(width) EQ 0 then pad = '2' else pad = StrTrim(LONG(width[0]),2)
If n_elements(type) EQ 0 then typ = 'I' else typ = type[0]


format = '(' + typ + pad + '.' + pad + ')'
Return, STRING(value, format = format)
END

