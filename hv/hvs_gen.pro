;
; Function which defines various parameters for GEN
;

FUNCTION HVS_GEN
;
; Details on how to transfer data from the production machine to the
; server
;
; As of 2010/03/24 the commands used are
;
; chown -R <local.group>:<remote.group> <filename>
; rsync -Ravxz --exclude "*.DS_Store" <filename> -e ssh -l
; <remote.user> @ <remote.machine> : <remote.incoming>
;
; Note that
;
; (1) local and remote computers MUST have the same group with the
; SAME group IDs and group names
; (2) the owner of the JP2 files MUST be member of that group on both
; the LOCAL machine and the REMOTE machine
;
; Linux gotcha: Ubuntu 9.10 (2010/03/24) requires that the JP2
; creation machine be RESTARTED before the group assignment for a user
; is recognized by the system.  For example, if you attempt to put
; a user into a group, then the change only "sticks" after a restart.
; This is important for the current application as you want the
; username on both the local and remote machines to be in the same groups.
;
;
; Everything below here should not be changed except by the JP2Gen source
; -----------------------------------------------------------------------
;
; Get the source details
;
  wby = HV_WRITTENBY()
  loc = wby.local.jp2gen
  source = {institute:'NASA-GSFC',$
            contact:'ESA/NASA Helioviewer Project [contact the Helioviewer Project at contact@helioviewer.org]',$
            all_code:'https://github.com/Helioviewer-Project',$
            jp2gen_code:'https://github.com/Helioviewer-Project/jp2gen',$
            jp2gen_version:'0.8',$
            jp2gen_branch_revision:''}
;
; Set up default values for JP2 compression
;
  d = {measurement: "", n_levels: 8, n_layers: 8, idl_bitdepth: 8, bit_rate: [0.5,0.01]}
  a = replicate( d , 1 )
;
; Not given flag
;
  notgiven = 'NotGiven'
;
; Construct the return value
;
  b = {details:a,$
       observatory:notgiven,$
       instrument:notgiven,$
       detector:notgiven,$
       web:'~/Desktop/',$
       already_written:'already_written',$
       not_compliant:'not_compliant',$
       na:'not_applicable',$
       notgiven:notgiven,$
       minusonestring:'-1',$
       exact:'exact',$
       range:'range',$
       time:['ccsds'],$
       source:source}
;
; Default values for compression
;
  b.details[0].measurement = 'NotGiven'; REQUIRED
  b.details[0].n_levels = 8 ; REQUIRED
  b.details[0].n_layers = 8 ; REQUIRED
  b.details[0].idl_bitdepth = 8 ; REQUIRED
  b.details[0].bit_rate = [4.0,0.1] ; REQUIRED

  return,b
end 
