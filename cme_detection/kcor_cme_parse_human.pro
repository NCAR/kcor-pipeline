; docformat = 'rst'

;+
; Parse one line of a human observer alert.
;
; :Params:
;   text : in, required, type=string
;     one line from a human observer alert file
;
; :Keywords:
;   time : out, optional, type=string
;     set to a named variable to retrieve the UT time of the alert
;   position_angle : out, optional, type=float
;     set to a named variable to retrieve the position angle of the CME in the
;     alert
;   width : out, optional, type=float
;     set to a named variable to retrieve the width of the CME in the alert
;   comment : out, optional, type=string
;     set to a named variable to retrieve the free form comment of the observer
;     about the CME
;-
pro kcor_cme_parse_human, text, $
                          time=time, $
                          position_angle=position_angle, $
                          width=width, $
                          comment=comment
  compile_opt strictarr

  pos = strsplit(text, length=len)

  time = strmid(text, pos[1], len[1])
  position_angle = float(strmid(text, pos[4], len[4]))
  width = float(strmid(text, pos[7], len[7]))
  comment = strmid(text, pos[9])
end


; main-level example program

;text = 'TIME: 30:70:80 UT  PA: 700 deg  WIDTH: 300 deg  Observers report with low confidence a CME at the time, position angle, and width noted.    Test of the new CME code.'

text = 'TIME: 19:24:02 UT PA 310 deg WIDTH: 90 deg ****Possible CME in Progress mcotter**** : Mon Jun 28 20:03:26 GMT 2021 Possible CME seen launching near PA: 310 deg at time 19:24:02 UT.'

kcor_cme_parse_human, text, $
                      time=time, $
                      position_angle=position_angle, $
                      width=width, $
                      comment=comment

end
