;  docformat = 'rst'

;+
;  Create animation of side-by-side K-Cor nrgf and K-Cor subtraction images
;
;  Read in nrgf average gif images and subtraction gif images 
;  K-Cor Subtraction images have a nominal 5 minute cadence (if no data gaps)
;  K-Cor nrgf average images have a nominal 2 minute cadence (if no data gaps)
;  Find nrgf image closest in time to subtraction image
;  If these are 'close' together in time then save these 2 images in a new array then save as a new combined gif image`
;  HOW CLOSE IN TIME SHOULD IMAGES BE?
;  Want images less than 'numsec' seconds apart where 'numsec' is set as a default below 
;
;  History  J. Burkepile  August 2021
;-

pro kcor_nrgf_diff_movie, run=run
  compile_opt strictarr

   ; set image dimensions to 1024 x 512
   newarray = bytarr(1024, 512)

nrgf_file = ''
subt_file = ''
basename = ''
newname = ''
animation_name = ''

  ; set default values

  ; [secs] maximum DESIRED time difference between subt and nrgf image (no data
  ; gaps)
  numsec = 80.0D
  ; [secs] maximum REQUIRED (not to exceed) time difference between subt and
  ; nrgf image when gaps present
  maxsec = 300.0D

  secs_per_day = 86400.0D

  ; used to find ngrf images in units of fraction of a day in seconds. 
  goodtime = numsec / secs_per_day
  ; used to find nrgf if data gaps in fraction of a day in seconds
  maxtime = maxsec / secs_per_day
  ; used to determine if data gap present. Initialize to 1 day
  savetime = secs_per_day / secs_per_day

  read_subt = 1     ; flag to determine if a new subt. image should be read in. 1=yes, 0=no
  ncount = 0        ; counter for number of good nrgf/subt pairs
  end_of_data = 0   ; use flag to find last good image matches
  no_subt = 0       ; Set to one if no subtraction images are present

  ; read in list of good subtraction gifs and 2 min avg nrgf gifs

spawn,'ls *minus*_good.gif >& subt.ls'
spawn,'ls *l2_nrgf_avg.gif >& nrgf.ls'

subtlist = 'subt.ls'
nrgflist = 'nrgf.ls'

CLOSE,3
CLOSE,4
OPENR, 3, subtlist
OPENR, 4, nrgflist

numsubt = file_lines(subtlist)
numsubt = fix(numsubt)
numnrgf = file_lines(nrgflist)
numnrgf = fix(numnrgf)
subt_keep=strarr(numsubt)
nrgf_keep=strarr(numsubt)

WHILE (end_of_data ne 1) DO BEGIN ;{ this logic should find the last good subt/nrgf match of the day

   readf, 4,   nrgf_file     ; read in next nrgf image
   IF (read_subt eq 1) THEN readf,3,subt_file   ; read in next subt image
;  If NO subtraction images were made the subt.ls file above will contain the string: 'ls: No match.'
;  Check if this is present and if it is then exit program
   IF (subt_file eq 'ls: No match.') THEN BEGIN
      no_subt = 1
      GOTO, JUMP1
   ENDIF

   ftspos   = STRPOS (nrgf_file, '_kcor')


  ; determine time of images

  ; extract subtraction time from filename
  syear   = fix(strmid(subt_file,  0, 4))
  smonth  = fix(strmid(subt_file,  4, 2))
  sday    = fix(strmid(subt_file,  6, 2))
  shour   = fix(strmid(subt_file,  9, 2))
  sminute = fix(strmid(subt_file, 11, 2))
  ssecond = fix(strmid(subt_file, 13, 2))

  ; extract nrgf time from filename
  nyear   = fix(strmid(nrgf_file,  0, 4))
  nmonth  = fix(strmid(nrgf_file,  4, 2))
  nday    = fix(strmid(nrgf_file,  6, 2))
  nhour   = fix(strmid(nrgf_file,  9, 2))
  nminute = fix(strmid(nrgf_file, 11, 2))
  nsecond = fix(strmid(nrgf_file, 13, 2))

;  use subtraction time to find nearest nrgf image 
;  convert to julian date to make it easier to find difference between times 
;  Want images to be < numsec seconds apart (i.e. < numsec/86400; 86400 = number of sec/day)

   subttime= julday(smonth, sday, syear, shour, sminute, ssecond)
   nrgftime= julday(nmonth, nday, nyear, nhour, nminute, nsecond)
   delta_time = double(abs(subttime - nrgftime)) 
   
;  Check to see if nrgf is within 'goodtime' from the subtraction image

   IF (delta_time lt goodtime) THEN BEGIN
      nrgf_keep(ncount) = nrgf_file
      subt_keep(ncount) = subt_file
      print, ' found a good nrgf file'
      read_subt = 1
      savetime = 1.   ;  found a good image so reset to start looking for next good image
      ncount = ncount + 1
   ENDIF ELSE IF (delta_time lt savetime) THEN BEGIN   ; time difference decreasing (i.e. closer to subt) but want something closer
      savetime = delta_time         ; save current img time difference to check for future data gaps
      saveimg = nrgf_file           ; save current image filename in case of future data gaps
      read_subt = 0
   ENDIF ELSE IF (delta_time ge savetime) AND (savetime lt maxtime) THEN BEGIN    
; time difference increasing; probably data gap. Use previous img if meets less strict criteria
      nrgf_keep(ncount) = saveimg
      subt_keep(ncount) = subt_file
      print, ' found an acceptable nrgf file'
      read_subt = 1
      savetime = 1.
      ncount = ncount + 1
   ENDIF ELSE IF (delta_time ge savetime) AND (savetime ge maxtime) THEN BEGIN    ; No good image found to match subtraction 
      read_subt = 1              ; need to read in a new subtraction 
      savetime = 1.
      print, ' NO acceptable nrgf found '
   ENDIF

;  When the last subtraction image is found; continue reading nrgfs to find a match

   IF (EOF(3) ne 0) AND (EOF(4) ne 0) THEN end_of_data= 1  ; at EOF in both
   IF (EOF(3) ne 0 ) AND (EOF(4) eq 0) THEN BEGIN  ; still have some nrgf images
      if (read_subt eq 1) THEN end_of_data = 1 ; no more nrgfs within time range
      if (read_subt eq 0) THEN end_of_data = 0 ; keep going to find last good nrgf
   ENDIF

ENDWHILE ;}


   print,' number of subtraction images = ',numsubt
;  close files 
CLOSE, 3
CLOSE, 4

  for i=0L, ncount - 1L  do begin
    read_gif, nrgf_keep[i], nrgfimg
    read_gif, subt_keep[i], subtimg

    ; remove the seconds from the filename
    ftspos   = strpos(subt_keep[i], '_kcor')
    basename = strmid(subt_keep[i], 0, ftspos - 2)

    nrgfimg = rebin(nrgfimg, 512, 512)
    subtimg = rebin(subtimg, 512, 512)

    ; put nrgf image on left and subtraction on the right side of the window
    newarray[0:511, *] = nrgfimg
    newarray[512:1023, *] = subtimg
    
    ;  Create gif name and save image
    newname = basename + '_kcor_l2_nrgf_and_subt.gif'
    write_gif, newname, newarray
  endfor


;  create list with names of side-by-side gifs
spawn,'ls *kcor_l2_nrgf_and_subt.gif >& nrgf_and_subt.ls'

; Create movie filename
basename = strmid(subt_keep(0), 0, 8)  ;  remove the seconds from the filename. 
movie_name = basename + '_kcor_l2_nrgf_and_subt_movie.gif'

; There are a handful of days when there is only 1 K-Cor subtraction image
; If that is the case then add that info to the filename
IF (numsubt eq 1) THEN movie_name = basename + '_kcor_l2_nrgf_and_subt_one_frame_only_movie.gif'

GET_LUN, MOVIENAME
OPENW,MOVIENAME,'animation_name'
printf, MOVIENAME, movie_name    ;save movie filename to create animate filename 
CLOSE, MOVIENAME

  ; TODO: make mp4 instead of animated GIF
spawn,'convert -delay 10 -loop 0 `cat nrgf_and_subt.ls` `cat animation_name` '

  JUMP1: IF (no_subt eq 1)  THEN print,' No subtractions available for this day'
end
