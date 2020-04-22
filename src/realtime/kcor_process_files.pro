; docformat = 'rst'

;+
; Do L1 and L2 processing for a list of files.
;
; :Author:
;   Joan Burkepile [JB]
;
; :History:
;   Modified version of 'make_calib_kcor_vig_gif.pro'
;   8 Oct 2014 09:57 (Andrew Stanger [ALS])
;   Extensive revisions by Giliana de Toma [GdT].
;   Merge two camera images prior to removal of sky polarization (radius, angle).
;
;   03 Oct 2014: Add date & list parameters.
;   13 Nov 2014: Add base_dir parameter.
;   13 Nov 2014: Use kcor_find_image function to locate disc center.
;   14 Nov 2014: Use Z-buffer instead of X window device for GIF images.
;                Note: charsize for xyouts needs to be reduced to about 2/3 of
;                of the size used for the X window device to yield approximately
;                the same size of characters in the annotated image.
;   19 Nov 2014: Change log file name so that the date always refers to 
;                the observing day (instead of calendar day for the L0 list).
;
;   7 Nov 2014: [GdT] Modified centering algorithm, since it did not find 
;               the correct center.
;   7 Nov 2014: [GdT] Changed to double precision to properly find inflection 
;               points
;               Added keyword center_guess to guess center location using with 
;               vertical/horizonatl scans (see Alice's quick-look code).
;               Added iteration if center is not found at first attempt.
;               Used Randy Meisner fitcircle.pro to fit a circle because faster.
;
;   Revisions to speed up code and fixed a few other things (GdT):
;     Dec 1 2014: negative and zero values in the gain are replaced with the
;                 mean value in a 5x5 region centered on bad data point
;     Dec 1 2014: coordinates and radius are defined as arrays for gain and images
;     Dec 1 2014: solar radius, platescale, and occulter are determined at the 
;                 beginning of the code
;     Dec 1 2014: gain is not shifted to properly flat-field images 
;                 region where gain is not available is based on a shifted gain 
;     Dec 1 2014: removed part about finding the center after demodulation 
;                 center for final images is based on distorted raw images - 
;                 this is the best way to find the correct center (hard to find 
;                 the center after image calibration because of saturation ring).
;     Dec 1 2014: Mk4 cordinate transformation is now based on arrays 
;                 (removed loops).
;     Dec 1 2014: sky polaritzion correction is now based on on arrays 
;                 (removed loops).
;                 sin2theta uses 2 instead of 3 parameters
;                 changed derivative in sin2theta and initial guesses in main code
;                 U fit is shifted by 45deg for Q correction
;     Dec 1 2014: "a" was used as fit parameter and also as index in for-loops
;                 changed to avoid possible variable conflicts
;     Dec 1 2014: final image masking is done with array (removed loop)
;
;     Dec 2014: Calibrated image is shifted and rotated using ROT - so only
;               one interpolation is made to put north up and image in the
;               array center (Giuliana de Toma & Andrew Stanger)
;     Jan 2015: fixed error in kcor_sine2theta fit: 
;               converted degrees in radiants for input in kcor_sine2theta_new.pro
;               changed degrees and "a" coeff to double precision
;               changed phase guess to zero (this should not make any difference)
;   24 Jan 2015 [ALS] Modify L1SWID = 'kcorl1g.pro 24jan2015'.
;               Remove kcor_sine2theta U plots to display.
;               Replace pb0r.pro with sun.pro to compute ephemeris data.
;   28 Jan 2015 [ALS] Modify L1SWID = 'kcorl1g.pro 28jan2015'.
;               Set maxi=1.8, exp=0.7 [previous values: maxi=1.2, exp=0.8]
;   03 Feb 2015 [ALS] Add append keyword (for output log file).
;   12 Feb 2015 [ALS] Add TIC & TOC commands to compute elapsed time.
;   19 Feb 2015 [ALS] Add current time to log file.
;   27 Feb 2015 [GdT] changed the DOY computation
;   27 Feb 2015 [GdT] removed some print statements
;   27 Feb 2015 [GdT] commened out the pb0r (not used anymore)
;   27 Feb 2015 [GdT] added mask of good data and make demodulation for 
;                     good data only
;    3 Mar 2015 [GdT] changed code so distorsion coeff file is restored  only once
;    3 Mar 2015 [GdT] made phase0 and phase1 keywords and set default values
;    3 Mar 2015 [GdT] made bias and sky_factor keywords and set default values
;    3 Mar 2015 [GdT] made cal_dir and cal_file keywords and set defaults
;    3 Mar 2015 [GdT] removed more print statements
;    3 Mar 2015 [GdT] changed call to sun.pro and removed ephem2.pro, 
;                     julian_date.pro, jd_carr_long.pro
;                     all ephemeris info is computed using sun.pro
;    4 Mar 2015 [ALS] L1SWID = 'kcorl1_quick.pro 04mar2015'.
;    6 Mar 2015 [JB] Replaced application of demodulation matrix multiplication
;                    with M. Galloy C-code method. 
;                    *** To execute Galloy C-code, you need a new environmental
;                    variable in your .login or .cshrc:
;                    IDL_DLM_PATH=/hao/acos/sw/idl/kcor/pipe:"<IDL_DEFAULT>"
;   10 Mar 2015 [ALS] Cropped gif annotation was incorrect (power 0.7 should have
;                     been 0.8).  Changed exponent to 0.8.
;                     Now both cropped & fullres gif images use the following:
;                     tv, bytscl (img^0.8, min=0.0 max=1.8).
;                     Annotation will also now be correct for both GIF images.
;   11 Mar 2015 [ALS] Modified GIF scaling: exp=0.7, mini=0.1, maxi=1.4
;                     This provides an improvement in contrast.
;                     L1SWID = "kcorl1g.pro 11mar2015"
;   15 Mar 2015 [JB]  Updated ncdf file from Jan 1, 2015 to March 15, 2015. 
;   18 Mar 2015 [ALS] Modified FITS header comment for RCAMLUT & RCAMLUT.
;                     RCAMLUT is the Reflected camera & TCAMLUT is Transmitted.
;
;                     Kcor data acquired prior to 16 Mar 2015 were using the
;                     WRONG LUT values !.
;                     Greg Card reported (15 Mar 2015) that the following tables
;                     were in use (KcoConfig.ini file [C:\kcor directory]) :
;                     LUT_Names
;                     c:/kcor/lut/Photonfocus_MV-D1024E_13890_adc0_20131203.bin
;                     c:/kcor/lut/Photonfocus_MV-D1024E_13890_adc1_20131203.bin
;                     c:/kcor/lut/Photonfocus_MV-D1024E_13890_adc2_20131203.bin
;                     c:/kcor/lut/Photonfocus_MV-D1024E_13890_adc3_20131203.bin
;                     c:/kcor/lut/Photonfocus_MV-D1024E_13891_adc0_20131203.bin
;                     c:/kcor/lut/Photonfocus_MV-D1024E_13891_adc1_20131203.bin
;                     c:/kcor/lut/Photonfocus_MV-D1024E_13891_adc2_20131203.bin
;                     c:/kcor/lut/Photonfocus_MV-D1024E_13891_adc3_20131203.bin
;                     These look-up tables are for the two SPARE cameras, NOT
;                     the ones in use at MLSO.
;
;                     On 16 Mar 2015, Ben Berkey changed the KcoConfig.ini file:
;                     LUT_Names
;                     c:/kcor/lut/Photonfocus_MV-D1024E_11461_adc0_20131203.bin
;                     c:/kcor/lut/Photonfocus_MV-D1024E_11461_adc1_20131203.bin
;                     c:/kcor/lut/Photonfocus_MV-D1024E_11461_adc2_20131203.bin
;                     c:/kcor/lut/Photonfocus_MV-D1024E_11461_adc3_20131203.bin
;                     c:/kcor/lut/Photonfocus_MV-D1024E_13889_adc0_20131203.bin
;                     c:/kcor/lut/Photonfocus_MV-D1024E_13889_adc1_20131203.bin
;                     c:/kcor/lut/Photonfocus_MV-D1024E_13889_adc2_20131203.bin
;                     c:/kcor/lut/Photonfocus_MV-D1024E_13889_adc3_20131203.bin
;                     These are the correct tables to be used, since the cameras
;                     in use at MLSO (since deployment, Nov 2013) are:
;                     camera 0 (Reflected)   S/N 11461
;                     camera 1 (Transmitted) S/N 13889
;   09 Apr 2015 [ALS] L1SWID='kcorl1s.pro 09apr2015'.
;                     Combine images from both cameras prior to removal
;                     of sky polarization (radius, angle).
;                     cal_file='20150403_203428_ALL_ANGLES_kcor_1ms_new_dark.ncdf'
;   10 Apr 2015 [ALS] Add fits header keyword: 'DATATYPE' (cal, eng, science).
;                     L1SWID='kcorl1s.pro 10apr2015'.
;   29 May 2015 [ALS] Generate NRGF file via "kcor_nrgf.pro".
;                     Ben Berkey installed painted occulter (1018.9 arcsec).
;                     new calibration file: 20150529_180919_cal_1.0ms.ncdf
;   01 Jun 2015 [ALS] L1SWID = 'kcorl1r.pro 01jun2015'
;   15 Jul 2015 [ALS] Change BSCALE parameter from 1.0 to 0.001.  Prior to this
;                     date, the value of BSCALE needs to be changed to 0.001 .
;                     Delete DATE-L1 keyword (replaced by DATE_DP).
;                     Delete L1SWID keyword (replaced by DPSWID).
;                     Add DPSWID  keyword (data processing software ID). 
;                     set DPSWID='kcorl1v.pro 16jul2015'.
;                     Add DATE_DP keyword (data processing date).
;                     Add DATE-BEG keyword (same as DATE-OBS).
;                     Add DATAMIN, DATAMAX keywords.
;                     Add DISPMIN, DISPMAX, DISPEXP keywords.
;                     Add XPOSURE keyword (total exposure for image).
;                     DATASUM & CHECKSUM keywords not yet implemented.
;   24 Sep 2015 [ALS] Add QUALITY keyword (image quality).
;                     Add RCAM_XCEN keyword (reflected camera x-center raw image).
;                     Add RCAM_YCEN keyword (reflected camera y-center raw image).
;                     Add RCAM_RAD keyword (reflected camera occ radius raw image)
;                     Add TCAM_XCEN keyword (transmit camera x-center raw image).
;                     Add TCAM_YCEN keyword (transmit camera y-center raw image).
;                     Add TCAM_RAD keyword (transmit camera occ radius raw image).
;   19 Oct 2015 [ALS] Replace DPSWID with L1SWID.
;                     Delete  DATE_DP keyword.
;                     Restore DATE-L1 keyword.
;                     Delete  DATE-BEG keyword.
;                     Delete  XPOSURE keyword.
;                     set L1SWID='kcorl1v.pro 19oct2015'.
;                     Rearrange keywords.
;   04 Nov 2015 [ALS] Add DATE_HST keyword (Hawaii Standart Time date: yyyy-mm-dd)
;                     Replace L1SWID  with DPSWID='kcorl1v.pro 04nov2015'.
;                     Replace DATE-L1 with DATE_DP.
;   10 Dec 2015 [ALS] Change name to kcorl1.pro.
;                     DPSWID='kcorl1.pro 10dec2015'.
;   14 Dec 2015 [ALS] Add comment to telescop keyword.
;                     set rcamfocs = tcamfocs = 0.0 if level0 values are 'NaN'.
;                     DPSWID='kcorl1.pro 14dec2015'.
;   26 Jan 2016 [ALS] Modify all paths to be in non-user directories.
;                     Use color table in /hao/acos/sw/idl/color.
;   04 Mar 2016 [ALS] Use kcor_nrgf.pro to generate both gif & FITS RG files.
;   02 Mar 2017 [JB]  Removing phase angle in coordinate transformation from cartesean
;                     to tangential. Removed comments about phase angle. Don't need it 
;                     anymore since we are now using Alfred's new calibration (Dec 12, 2016) \
;                     that fixed the bugs in the previous versions.
;   25 Jul 2018 [MG]  Change BSCALE back to 1.0 and save data as floats.
;   28 Aug 2018 [JI]  Initial edits to write a Helioviewer Project
;                     compatible JPEG2000 file
;
;   Make semi-calibrated kcor images.
;-------------------------------------------------------------------------------
; 1. Uses a coordinate transform to a mk4-q like image. 
;
;*** I have added a bias in order to help remove dark areas.
;*** Vignetting is OFF!!!!!!!
;*** Using only fraction of sky polarization removal.
;
;    I am only removing sky from Q and U. Need to remove it from I as well
;    at a later date.
;
; 2. FUTURE: Alfred needs to add the Elmore calibration of Mk4 Opal
; 3. Alfred still testing cameras to remove unwanted zeros in creating ncdf file
; 4. Need to streamline code and minimize number of interpolations.
; 5. Speed up vignetting BY using Giluiana's suggestion of creating a
;    vignetting image and doing matrix multiplication to apply to image.
;
; Order of processing: 
; 1. Apply Alfred's Demodulation Matrix
; 2. Find Image Centers for Each Camera
; 3. Apply Co-ordinate Transformation to get to Tangential (with respect to 
;    solar limb) Polarization ('mk4-q') and polarization 45 degrees from 
;    tangential ('mk4-u').
;    Ideally, tangential image will contain all corona + sky polarization and
;    image polarized 45 deg.to tangential will contain only sky polarization.
; FINAL CORONAL IMAGE: Only uses mk4-q like data.
;
;--- History of instrument changes which affect calibration and processing ---
;
; [JB] I have hardwired certain parameters to best process images acquired
; between Oct 2013 and present (May 2014).
; By 3rd week of Oct 2013, the instrument software was finally operating
; to give consistent sequences of polarization images by running socketcam
; continuously. Prior to that time, data may not be usable, since we are
; not sure of the order of polarization states
;
; CHANGES:
; BZERO in header Oct 15, and Oct 31 =  2147483648 = 2^15
; OCCLTRID value changes. Prior to ??? it was 'OC-1'.
; I believe this is occulter 1018.9". Need to verify.
; On Oct 15, the header value for modulator temperture is 512.0 deg C.
; That's nuts. It should be 35 deg C.
; Oct 20: Ben reports changing zero offset(BZERO). It was initially set at
; 16 bit (65536, 32768)
;
; Other things to check: integrity of SGS values
;
; FUTURE: Need to check occulter size and exposure to determine appropriate
; NCDF file.
; CURRENTLY: Hardwired.
; Short cut could be to read date of file to determine which ncdf calibration
; file to pick up.
; As of now (May 2014), we have used 1 msec exposures as the standard,
; since the mk4 opal went in back in early November 2013, so all ncdf files
; so far have same exposure.
; Occulters: There are 3 Kcor occulters. Dates of changes are: 
; r = 1018.9" occulter installed 30 October 2013 21:02 to 28 March 2014 16:59
; r = 1006.9" installed for a few minutes only on 28 Jan 2014 01:09:13 
;             installed 28 March 2014 17:00:09 to 28 Apr 2014 16:42
; r =  996.1" installed 28 April 2014 16:43:47
;------------------------------------------------------------------------------
; Functions and other programs called: 
;------------------------------------------------------------------------------
; :Uses:
;
; kcor_apply_dist    (/hao/acos/sw/idl/kcor/pipe; tomczyk)
; kcor_datecal       (/hao/acos/sw/idl/kcor/pipe; sitongia)
; kcor_find_image    (/hao/acos/sw/idl/kcor/pipe; tomczyk/detoma)
; kcor_radial_der    (/hao/acos/sw/idl/kcor/pipe; tomczyk/detoma)
; fitcircle          (/hao/acos/sw/idl/kcor/pipe; Randy Meisner)
; kcor_fshift        (/hao/acos/sw/idl/kcor/pipe)
;
; anytim2tai         (/hao/contrib/ssw/gen/idl/time)
; anytim2jd          (/hao/contrib/ssw/gen/idl/time)
; fitshead2struct    (/hao/contrib/ssw/gen/idl/fits)
; sun                (/hao/contrib/ssw/gen/idl/fund_lib/jhuapl)
;
; pb0r               (/hao/contrib/ssw/gen/idl/solar)
; ephem2             (/acos/sw/idl/gen dir)
;
;-------------------------------------------------------------------------------
; Parameters used for various dates.
;-------------------------------------------------------------------------------
; --- 31 Oct 2013 ---
; ncdf file:  20131031_cal_214306_kcor.ncdf created in May 2014
; Sky polarization amplitude: skyamp = .0035
; Sky polarization phase:     skyphase = -1.*!pi/4.   ; -45  deg
; Used image distortion test results of Oct 30, 2013 generated by Steve Tomczyk
; bias = 0.002
; tv, bytscl(corona^0.8, min=-.05, max=0.15)
; mini= 0.00
; maxi= 0.08
;
; The L0 FITS files need to be stored in the 'date' directory, which is located
; in the base directory.
;
; All level 1 files (FITS & GIF) will be stored in the sub-directory 'level1'
; under the date directory; all level 2 files will be stored in the
; sub-directory 'level2' under the date directory.
;
; :Params:
;   ok_files : in, out, optional, type=strarr
;     array containing FITS level 0 filenames
;
; :Keywords:
;   nomask : in, optional, type=boolean
;     set to not apply a mask to the FITS or GIF files, adding a "nomask" to the
;     filenames
;   run : in, required, type=object
;     `kcor_run` object
;   mean_phase1 : out, optional, type=fltarr
;     mean_phase1 for each file in `ok_files`
;   error : out, optional, type=lonarr
;     set to a named variable to retrieve the error status of the call; `!null`
;     if `ok_files` was empty or empty after skipping the first good science
;     image of the day
;-
pro kcor_process_files, ok_files, $
                        nomask=nomask, $
                        eod=eod, $
                        run=run, $
                        mean_phase1=mean_phase1, $
                        log_name=log_name, $
                        l1_filenames=l1_filenames, $
                        error=error
  compile_opt strictarr

  tic

  ; setup directories
  dirs  = filepath('level' + ['0', '1', '2'], $
                   subdir=run.date, $
                   root=run->config('processing/raw_basedir'))
  l0_dir = dirs[0]
  l1_dir = dirs[1]
  l2_dir = dirs[2]

  date_dir = filepath(run.date, root=run->config('processing/raw_basedir'))

  ; move to the processing directory
  cd, current=start_dir   ; save current directory

  ; get current date & time
  current_time = systime(/utc)

  mg_log, 'processing %s%s', run.date, keyword_set(nomask) ? ' (nomask)' : '', $
          name=log_name, /info

  ; check for empty list of OK files
  n_ok_files = n_elements(ok_files)
  if (n_ok_files eq 0) then begin
    mg_log, 'no files to process', name=log_name, /info
    error = !null
    goto, done
  endif

  error       = lonarr(n_ok_files)
  mean_phase1 = fltarr(n_ok_files)

  ; image file loop
  fnum = 0L
  first_skipped = 0B
  l1_filenames = strarr(n_ok_files)

  foreach l0_file, ok_files do begin
    catch, error_status
    if (error_status ne 0L) then begin
      mg_log, 'error processing %s, skipping', file_basename(l0_file), $
              name=log_name, /error
      mg_log, /last_error, name=log_name, /error
      continue
    endif

    fnum += 1L

    mg_log, '%d/%d: %s', $
            fnum, n_ok_files, file_basename(l0_file), $
            name=log_name, /info

    ; skip first good image of the day
    if (~kcor_state(/first_image, run=run)) then begin
      mg_log, 'skipping first good science image', $
              name=log_name, /info
      first_skipped = 1B
      continue
    endif

    kcor_l1, filepath(file_basename(l0_file), $
                      root=keyword_set(eod) ? l0_dir : date_dir), $
             run=run, $
             mean_phase1=file_mean_phase1, $
             l1_filename=l1_filename, $
             l1_header=l1_header, $
             intensity=intensity, $
             q=q, $
             u=u, $
             flat_vdimref=flat_vdimref, $
             log_name=log_name, $
             error=l1_error

    error[fnum - 1L] or= l1_error
    if (l1_error ne 0L) then begin
      mg_log, 'error in L1 processing, skipping L2 processing', $
              name=log_name, /warn
      continue
    endif

    mean_phase1[fnum - 1L] = file_mean_phase1
    l1_filenames[fnum - 1L] = l1_filename

    kcor_l2, l1_filename, $
             l1_header, $
             intensity, q, u, flat_vdimref, $
             run=run, $
             nomask=nomask, $
             log_name=log_name, $
               error=l2_error
    error[fnum - 1L] or= l2_error
  endforeach


  ; drop the first file from OK files if skipped
  if (first_skipped) then begin
    ok_files = n_ok_files gt 1L ? ok_files[1:*] : !null
    l1_filenames = n_ok_files gt 1L ? l1_filenames[1:*] : !null
    error = n_ok_files gt 1L ? error[1:*] : !null
  endif


  ; get system time & compute elapsed time since TIC command
  done:
  cd, start_dir
  total_time = toc()

  if (n_ok_files ne 0) then begin
    image_time = total_time / n_ok_files
  endif else begin
    image_time = 0.0
  endelse

  mg_log, /check_math, name=log_name, /debug
  mg_log, 'processed %d images in %0.1f sec', n_ok_files, total_time, $
          name=log_name, /info
  mg_log, 'time/image: %0.1f sec', image_time, name=log_name, /info
end