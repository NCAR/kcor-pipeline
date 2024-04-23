# Release notes

#### 1.0.0 [May 12, 2017]

- initial release

#### 1.0.1 [May 12, 2017]

- default to production config file
- ssh_key config file option
- look for mlso_sgs_insert files in level0/ directory

#### 1.0.2 [May 12, 2017]

- typo in ssh_key usage

#### 1.0.3 [May 12, 2017]

- send relative paths to MLSO_SGS_INSERT

#### 1.0.4 [May 12, 2017]

- raw files are not zipped when dealt with my MLSO_SGS_INSERT

#### 1.1.0

- fix horizontal artifacts in raw files
- better transmission value for opal
- add options for end-of-day actions

#### 1.1.1 [May 16, 2017]

- typo in end-of-day processing

#### 1.2.0 [May 24, 2017]

- camera correction
- turn off horizontal correction for epoch starting 20170522

#### 1.2.1 [May 31, 2017]

- fix for horizontal correction not being applied
- better headers
- better email notifications

#### 1.2.2 [Jun 1, 2017]

- typo in end-of-day

#### 1.2.3 [Jun 1, 2017]

- typo in end-of-day

#### 1.2.4 [Jun 2, 2017]

- remove inventory files on reprocessing
- fix for errors listed in email notifications

#### 1.3.0 [Jun 2, 2017]

- after 20121204, use pipeline created calibration files
- use new distortion file for 20150619 and later
- add totalpB to science database table

#### 1.3.1 [Jun 5, 2017]

- fix for distributing NRGF FITS files
- handle bad occulter IDs in FITS headers better

#### 1.3.2 [Jun 6, 2017]

- full format for totalpB in kcor_sci

#### 1.3.3 [Jun 6, 2017]

- find occulter correctly in NRGF routine

#### 1.3.4 [Jun 6, 2017]

- typo in KCOR_L1 date_dp

#### 1.3.5 [Jun 14, 2017]

- add bias in camera correction

#### 1.4.0 [Jun 28, 2017]

- remove bias to camera correction
- added main kcor script
- add gamma correction for GIFs
- doesn't unzip compress FTS files
- configurable sky polarization correction

#### 1.4.1

- normalize dates in FITS headers to correct for invalid values
- skip first image of the day

#### 1.4.2 [Oct 6, 2017]

- change date that display values changed in 2017

#### 1.4.3

- daily animations of L1/NRGF full/cropped GIFs
- options to do reprocessing vs. updating

#### 1.4.4 [Oct 26, 2017]

- fix for daily animations for observing days across UT midnight
- better interface for kcor script

#### 1.4.5 [[Oct 26, 2017]

- fix for kcor script installation

#### 1.4.6 [Oct 26, 2017]

- fix for trying to change permissions of files not owned

#### 1.4.7 [Oct 30, 2017]

- fix for redundant obs day identifiers in database

#### 1.4.8 [Oct 31, 2017]

- verify script

#### 1.4.9 [Nov 14, 2017]

- more checks for t1.log correctness
- don't create L0 tgz if reprocessing

#### 1.4.10 [Nov 15, 2017]

- remove camera correction config option, corrects when we have corrections

#### 1.4.11 [Nov 15, 2017]

- bug fix

#### 1.4.12 [Jan 5, 2018]

- updated kcor program to produce only calibration (default or from a list of files)
- add kcorcat program
- add kcorlog program
- correct for DIMV
- option for using only a single camera

#### 1.4.13 [Jan 19, 2018]

- rotate logs when reprocessing
- enforce calibration files all have same LYOTSTOP value
- new cal epoch

#### 1.4.14 [Jan 20, 2018]

- bug fix

#### 1.4.15 [Jan 31, 2018]

- log camera correction filename
- run at MLSO, i.e., zip FTS files in raw directory if present
- check machine log against t1.log in verification
- new cal epoch

#### 1.4.16 [Jan 31, 2018]

- bug fix

#### 1.4.17 [Jan 31, 2018

- bug fix

#### 1.4.18 [Feb 9, 2018]

- fix for handling NaN SGS values (specifically for SGSLOOP)

#### 1.4.19 [Feb 9, 2018]

- more fixes for handling NaN SGS values

#### 1.4.20 [Feb 10, 2018]

- fix to handle new L1 GIF names

#### 1.4.21 [Feb 12, 2018]

- fix to distribute new L1 GIF names

#### 1.4.22 [Feb 15, 2018]

- fix for quality check for cloudy images

#### 1.4.23 [Feb 15, 2018]

- making average FITS/GIFs and daily average (but not distributing)

#### 1.4.24 [Mar 5, 2018]

- more verification constants in config file
- distribute average/daily average FITS/GIFs
- redo NRGF files in end-of-day processing using averages
- create daily NRGF file from daily average
- update kcor_sw table

#### 1.4.25 [Mar 5, 2018]

- fixes for filenames of daily average NRGF files
- fix for mlso_numfiles entry for daily average file

#### 1.4.26 [Mar 6, 2018]

- typo/bug in NRGF code

#### 1.4.27 [Mar 6, 2018]

- more fixes for distribution of averages/daily averages/NRGF daily averages

#### 1.4.28 [Mar 7, 2018]

- fix for scaling of difference GIFs
- fixes for new order of creating animations/averages and redoing NRGFs
- crash notification
- log messages

#### 1.4.29 [Mar 8, 2018]

- make calibration respect process flag in epochs file

#### 1.4.30 [Mar 8, 2018]

- add quality field to kcor_cal table

#### 1.4.31 [Mar 8, 2018]

- fix for using full paths for db files

#### 1.4.32 [Mar 9, 2018]

- fix DATE-OBS/DATE-END in averages

#### 1.4.33 [Mar 12, 2018]

- separate automated, real-time CME detection script for production

#### 1.4.34 [Mar 12, 2018]

- handle days which don't have an extended average

#### 1.4.35 [Mar 13, 2018]

- fix for now creating extended average on many days

#### 1.4.36 [Mar 14, 2018]

- handle days when the extended average time is not the same as any 2 min average

#### 1.4.37 [Mar 14, 2018]

- bug fix in handling days when the extended average time is not the same as 2 min average

#### 1.4.38 [Mar 14, 2018]

- bug fix in handling days when the extended average time is not the same as 2 min average

#### 1.4.39 [Mar 26, 2018]

- new distortion
- indexing fixes for CME detection
- create missing directories in CME detection
- send CME notification from config file "from_email" address

#### 1.4.40 [Apr 25, 2018]

- quality plot
- fixes for putting means/medians in kcor_eng table
- add kcor_hw reference to kcor_eng
- updated distortion in epochs
- epochs for changes on 20180406-20180423
- better ephemeris calculation

#### 1.4.41 [Jun 22, 2018]

- always create quality plot
- send L1 products to HPSS
- update to IDL 8.6
- remove taking absolute value of data
- replaced KCor L1 cropped GIF with fullres BW and no gamma correction
- updated annotations on average GIFS and FITS keywords
- fixes for updating kcor_hw table
- add use_calibration_data flag for marking bad calibration data
- new epochs for bad calibration data on 201806{19,20}

#### 1.4.42 [Jun 22, 2018]

- fix epochs file typo

#### 1.4.43 [Jun 30, 2018]

- fix for standard/cropped mp4s (was showing NRGFs)
- make avg cropped GIFs like standard cropped GIFs
- add "North" and "2 min avg" (avg only) to cropped GIFs
- add CSV file of readings in CME report

#### 1.4.44 [Jul 8, 2018]

- fix for sending L1 tarball to HPSS
- indicate values outside nominal range in param plots
- make extavg cropped GIFs like standard cropped GIFs
- fix for first 2 min average GIF

#### 1.4.45 [Jul 10, 2018]

- return only one latest row for hardware/software changes
- log error messages when reading FITS files for detecting hardware changes

#### 1.5.0 [Aug 10, 2018]

- change BSCALE to 1.0, units of L1 files are now B/Bsun
- change L1 fullres GIFs to BW color table and gamma of 1.0
- change bias to 3.0e-9
- check L1 tarball on HPSS in verification
- populate kcor_raw table
- check level from L1 to L1.5
- add R_SUN keyword and change RSUN to RSUN_OBS
- added rotation correction

#### 1.5.1 [Sep 19, 2018]

- adds level to kcor_sci database table (determines scale of other fields)
- fix check for saturated images
- apply distortion in double precision
- fix for finding L1.5 files for CME detection
- creating JPEG2000 images for Helioviewer
- reduced over masking of occulter from 5 pixels to 2 pixels
- changed default for NPICK in calibration file creation from 10000 to 50000

#### 1.5.2 [Sep 21, 2018]

- handle no L1 files for daily science file
- fixes for handling saturated images

#### 1.5.3 [Sep 21, 2018]

- fixes to and additional keyword raw/dist cor centering FITS keywords

#### 1.5.4 [Sep 21, 2018]

- added library routine

#### 1.5.5 [Sep 21, 2018]

- bug fix

#### 1.5.6 [Oct 22, 2018]

- engineering plot fixes
- saving extended averages, p/q dirs, difference, and unmasked images and logs
- [RT]CAMCORR FITS keywords in L1.5 files
- epochs file updated for bad cals
- calibration GBU check if GBU params file given in epochs (not given yet)

#### 1.5.7 [Nov 6, 2018]

- add option to specify sun-occulter offset in pixels
- using only good quality L0 files for files chosen to be nomask L1 files
- fix filenames for nomask cropped GIF files
- add config file to saved results
- add r_in_offset and r_out to epoch values (and used in NRGF files as well as L1)
- fix bug adding many extra KCOR_SW rows, only adding new rows for L1.5 files
- wait for machine log before running end-of-day processing
- remove old saved results and JPEG2000 files when reprocessing
- increased over masking of occulter from 2 pixels to 3 pixels
- remove circle annotation of photosphere on nomask GIFs

#### 1.5.8 [Nov 7, 2018]

- add epoch value for when to require a machine log file

#### 1.5.9 [Nov 28, 2018]

- fix for invalid XML in JP2 files

#### 1.5.10 [Jan 14, 2019]

- L1.5 tarballs will be updated on reprocessing if send_to_hpss is set
- include traceback for error in crash notification
- re-read image in quality check if it is not 4-dimensional
- recording socket cam ID
- correction applied to rotation of image to solar North (in addition to QU transform)

#### 1.5.11 [Jan 29, 2019]

- use interpolated fit_params for camera correction
- caching camera correction parameters
- add Carrington rotation to kcor_img database table
- simplify kcor_sw table and add an entry only when version/revision has changed

#### 1.5.12 [Feb 22, 2019]

- changed syntax for kcor command, added sub-commands
- added validate and archive subcommands to kcor command
- specification for config file and epoch file
- uses camera calibration files with camera ID + date for LUT name
- formatting in FITS keyword comments
- more accurate calculation of Carrington rotation number fro FITS keyword CAR_ROT
- fixes to make simulator work with machine log file
- add speedup factor to realtime simulator
- fix bug that realtime processes unlocked raw directory even if they didn't get lock
- added option to put PID in log messages
- option to specify NRGF gallery update method via cp or scp (or none)
- removed extraneous error messages when checking for extra log files in raw directory
- routing files to specify raw basedir locations
- epoch file updated to apply camera correction starting 20131122

#### 1.5.13 [Feb 22, 2019]

- change how config filename is specified to new style for realtime cme detection

#### 1.5.14 [Feb 22, 2019]

- extra release to get mlso release version to match up

#### 1.5.15 [Feb 23, 2019]

- fix when trying to lock raw directory that wasn't created yet
- fix for config parameter retrieval using old style

#### 1.5.16 [Feb 23, 2019]

- fix for DLM build date

#### 1.5.17 [Feb 25, 2019]

- update library routine for handling routing file

#### 1.5.18 [Feb 26, 2019]

- add epochs to not process bad cal files
- fixed use_camera_info (set too early when [RT]CAMID was OK, but [RC]CAMLUT was not)
- camera correction doesn't trust [RT]CAMID if use_camera_info is false

#### 1.5.19 [Mar 11, 2019]

- validate L0 files
- handle camera correction of a single camera
- update epochs.cfg with new versions of hard-coded cal files
- safer comparison to match exposure times between cal file and sci file

#### 1.5.20 [Mar 12, 2019]

- update validation file for new (old) TCAM
- update epochs file for odd data taken on 20131122
- increase to 2 digits of accuracy after decimal for display of exposure time
- can remove horizontal artifacts in a single camera, i.e., 20190307-

#### 1.6.0 [Mar 13, 2019]

- release for reprocessing, no new changes

#### 1.6.1 [Mar 22, 2019]

- hostname in start of log messages
- grid on pB, difference, and average GIF images
- epoch file updates

#### 1.6.2 [Mar 25, 2019]

- epoch change for quicklook GIF scaling

#### 1.6.3 [Apr 11, 2019]

- writing L1.5 FITS data as float, not double
- not setting negative dark corrected science values to 0
- log warning if negative dark corrected science values in masked coronal images
- log warning if Nan/infinity in corona
- handle NaN/infinity in corona when setting DATAMIN/DATAMAX
- add realtime/check_quality option
- mark some bad files in epoch file
- handle no L0 files, but empty t1/t2 log files
- correct for NUMSUM between sci/cal files before using dark/flat
- fix bug where L0 tarball was sent to HPSS in a reprocess
- fix issue where epoch date/time was not advanced during difference/average creation
- skip first good science image on reprocessing
- remove use_bzero option, always write FITS files with 0 BZERO
- validate L1.5 FITS files
- fix for sending log messages for correcting horiz lines to wrong log
- make sure distortion and calibration files are those actually used
- handle writing missing data in FITS keywords correctly
- CME detection alert specifies last file processed at detection

#### 1.6.4 [Jun 14, 2019]

- handle no L1.5 files when validating
- eod report
- savecme sub-command
- save tarlist, nomask/diff files
- new short epoch for test with NUMSUM=171

#### 1.6.5 [Jun 19, 2019]

- new short epoch for test with NUMSUM=171

#### 1.6.6 [Jul 2, 2019]

- fix for case where there is data, but not L1.5 files for a day
- epoch file changes for display min/max/exp
- detect bad horizontal lines
- produce median row/col images
- major quicklook scaling changes
- epoch for Eclipse day with NUMSUM=171

#### 1.6.7 [Jul 3, 2019]

- fix for crashing bug in log message in KCOR_QUALITY for saturated images

#### 1.6.8 [Jul 15, 2019]

- remove bad cal files from 20170530 in epochs file
- use md5 hash instead of date to check that HPSS tarballs match local ones
- make y-range for ocen plots epoch dependent
- removing camera correction from quality check

#### 1.6.9 [Jul 16, 2019]

- fix for ocen_yrange use typo

#### 1.6.10 [Jul 18, 2019]

- not rotating/translating quicklook image
- fix for name of remove sub-command (was repeated as purge)
- check for valid date in entry-point routines
- made CME detection alert a WARN in the logs
- put CME plots in p/ directory since engineering/basedir has been removed
- send crash notifications for CME detection crashes

#### 1.6.11 [Jul 18, 2019]

- fix for date check in CME detection launch

#### 1.6.12 [Jul 18, 2019]

- typo in crash notification

#### 1.6.13 [Jul 18, 2019]

- typo in CME detection report

#### 1.6.14 [Jul 18, 2019]

- fix for saturated images in quality check

#### 1.6.15 [Oct 22, 2019]

- use simulated SGSDIMV for early epochs
- adjust plots of radial intensity and centering
- create plot of sky transmission over the day
- create plot of mean pB over the day at four heights
- fixes for processing early epoch data
- fix for CME CSV output
- better reporting of CME events
- use UT date/time in CME output filenames
- can turn off row/col images and report generation
- initial version of streaming aerosol removal (not in rt/eod pipelines)
- find and remove horizontal line artifacts automatically
- do not rotate quicklook images
- fix for when only OK image in batch is first good science image

#### 1.6.16 [Oct 22, 2019]

- fix for DLM path in CME detection code

#### 1.6.17 [Oct 25, 2019]

- add epoch for bad cal data on 20191024

#### 2.0.0 [Dec 19, 2019]

- creating L1 and L2 (equivalent to old L1.5) products
- add CAMERAS, FIXCAMLC, SKYPOLRM FITS keywords
- moved 1.08 Rsun kcor_sci table column to 1.11 Rsun
- bad horizontal line finding tweaks and optional diagnostics
- add L1 specification validation
- added separate notification options for validation
- changed validation option names in config file ("data" to "validation")

#### 2.0.1 [Dec 20, 2019]

- add epochs to not process different exposures on 20190923
- handle a day with raw data, but not data passing quality

#### 2.0.2 [Dec 26, 2019]

- missed zipping and distributing NRGF files

#### 2.0.3 [Jan 2, 2020]

- epoch fix for trusting camera info pushed by from 20150319 to 20150324

#### 2.0.4 [Jan 2, 2020]

- ignore long exposure data for 20140829 in epoch file

#### 2.0.5 [Jan 2, 2020]

- epoch fixes for bad cal files on 20150219 and 20160801

#### 2.0.6 [Jan 2, 2020]

- fix bug which checked exposures of bad calibration files

#### 2.0.7 [Jan 3, 2020]

- option to not check raw remote files during verification
- epoch fixes for 20150601 and 20180118 to mark bad cal data

#### 2.0.8 [Feb 7, 2020]

- produce synoptic map of the last 28 days
- produce synoptic map for the day
- epoch value for cameras to use (config value overrides epoch value)
- added epochs for using only camera 1 in Dec 2019
- verification can handle lack of L0 tarball on reprocessing
- system to repair raw data with incorrect headers through epochs
- added back missing DOY label on GIFs

#### 2.0.9 [Feb 7, 2020]

- fixed issue creating synoptic maps if p/ directory not already created

#### 2.0.10 [Mar 25, 2020]

- handle failures in the L1/L2 processing more gracefully, recording in level2/failed.ls
- fixed annotation issue in non-averaged NRGF GIFs

#### 2.0.11 [Mar 25, 2020]

- new epoch for bad occulter value

#### 2.0.12 [Mar 26, 2020]

- handle no OK files in realtime processing

#### 2.0.13 [Mar 26, 2020]

- handle no OK files in end-of-day processing

#### 2.0.14 [Mar 26, 2020]

- fix to check whether to use occulter ID in end-of-day processing

#### 2.0.15 [Apr 1, 2020]

- fix to handle saturated images in quality control

#### 2.0.16 [Apr 24, 2020]

- using new distortion for new cameras installed on 20191216
- no files to process log message change from error to info
- add L2 archive scripts
- add epoch option for fixing vertical line (default: NO)
- add config option for using smooth sky (default: NO)
- added nrgf sub-command to kcor utility to process single files
- producing NRGF profile plots

#### 2.0.17 [Apr 29, 2020]

- epoch to remove bad data on 20200422
- epoch to save good data with bad metadata on 20200425
- NRGF annotation fix

#### 2.0.18 [Jun 17, 2020]

- option to x-shift camera correction coefficients

#### 2.0.19 [Jun 17, 2020]

- removing display_{min,max} epoch values that were accidentally included

#### 2.0.20 [Aug 20, 2020]

- config option to distribute quicklooks to gallery
- move x-shift camera correction value to epoch file
- ability to fix data taken in the wrong polarization sequence
- daily/monthly O1 focus engineering plots
- added complete version metadata to cal files
- filling flats outside of annulus with mean value
- use bilinear for most interpolations, cubic for distortion

#### 2.0.21 [Aug 28, 2020]

- gallery quicklooks
- fix for interpolation artifact

#### 2.0.22 [Aug 30, 2020]

- fix for no plate scale value for certain qualities

#### 2.0.23 [Oct 11, 2020]

- epochs for x-shift for camera correction
- separating epoch values for permanent x-shift vs. x-shift just for camera linearity correction
- allowing each camera to have a separate x-shift for camera correction

#### 2.0.24 [Oct 23, 2020]

- using KCOR_OLD_READFITS to handle old raw FITS files with extra 4 bytes before data
- new epoch for bad start state for 20201020

#### 2.0.25 [Nov 6, 2020]

- fix for late image on last day of rolling synoptic map
- epoch fix for O1ID on 20201029-20201030

#### 2.0.26 [Dec 3, 2020]

- error messages for truncated raw FITS files
- end-of-day check script
- check raw file size when validating FITS keywords
- name of cal file now matches exact time of first cal image
- handle 180 deg cal pol images as 0 deg for warnings

#### 2.0.27 [Dec 4, 2020]

- fix for validation errors

#### 2.0.28 [Dec 4, 2020]

- fix for validating L1/L2 file size against raw file size

#### 2.0.29 [Dec 9, 2020]

- fix for missing DIFFSIR FITS keyword for the morning of 20150320

#### 2.0.30 [Dec 9, 2020]

- fix for CALPOLID, RCAMLUT, TCAMLUT keywords for 20150320

#### 2.0.31 [Dec 10, 2020]

- more epoch fixes for RCAMID, TCAMID for around 20150318-20150324

#### 2.0.32 [Dec 23, 2020]

- add cs_gateway directory option, similar to hpss_gateway
- change name of section in routing file from locations to kcor
- fix for multiple end-of-day processes running in near real-time mode

#### 2.0.33 [Dec 23, 2020]

- fix for typo in KCOR_STATE

#### 2.0.34 [Jan 1, 2021]

- verification checks archive on Campaign Storage

#### 2.0.35 [Jan 11, 2021]

- new tapered occulter

#### 2.0.36 [Jan 11, 2021]

- forgot new occulter value

#### 2.0.37 [Feb 2, 2021]

- writing azimuthally averaged pB for a fixed height to a text file
- weekly verification does not check HPSS any more

#### 2.0.38 [Mar 4, 2021]

- produce an NRGF for every 15 second image
- handle errors in verification more robustly

#### 2.0.39 [Mar 5, 2021]

- fix bug where date/time for epoch reads was not set until after reading a file

#### 2.0.40 [Mar 5, 2021]

- adding more database checks for errors

#### 2.0.41 [Mar 5, 2021]

- re-using database connection instead of connecting in end-of-day

#### 2.0.42 [Mar 5, 2021]

- typo

#### 2.0.43 [Mar 11, 2021]

- fix for database timing out

#### 2.0.44 [Mar 18, 2021]

- fix for not distributing average NRGF files

#### 2.0.45 [Mar 19, 2021]

- fix for crash in calibration data reading
- fix for not distributing NRGF cropped GIF files

#### 2.0.46 [Apr 1, 2021]

- fix for when only a single L2 file produced

#### 2.0.47 [Apr 13, 2021]

- ignore distortion test data on 20210413

#### 2.0.48 [Apr 14, 2021]

- handle OCCLTRID=GRID FITS keyword

#### 2.0.49 [May 14, 2021]

- fix for handling extended averages with only a few files
- new epoch for malformed OCCLTRID value on 20210513
- adding intensity to level 1 files

#### 2.0.50 [May 21, 2021]

- better error messages for file validation
- epoch for bad polarization state on 20210520

#### 2.0.51 [June 2, 2021]

- epoch for images with wrong exposure time on 20210531

#### 2.0.52 [June 3, 2021]

- fix for typo in epoch for 20210531

#### 2.0.53 [Jul 29, 2021]

- fix for status of verification on non-remote check issues
- allow start_state to vary by camera
- produce realtime lag plot

#### 2.0.54 [Jul 31, 2021]

- fix crash from display on cronjob run

#### 2.0.55 [Aug 1, 2021]

- only produce realtime lag plot if updating database
- fix crash from display on cronjob run

#### 2.0.56 [Aug 3, 2021]

- fix for checking cal data for correct start state by camera
- new epoch for missing RCAMID on 20210730

#### 2.0.57 [Aug 4, 2021]

- typo in {R,T}CAMLUT names in 20210730 epoch

#### 2.0.58 [Aug 6, 2021]

- reverting error not distributing NRGF average GIF files

#### 2.0.59 [Aug 17, 2021]

- report total time per level 0 image in realtime processing log
- distribute difference images

#### 2.0.60 [Aug 17, 2021]

- zip difference FITS files

#### 2.0.61 [Aug 29, 2021]

- decreased cadence of frames in mp4s
- change epochs file to produce calibration for 20131204

#### 2.0.62 [Aug 29, 2021]

- fix for checking if catalog directory exists in end-of-day

#### 2.0.63 [Sep 3, 2021]

- produce HPR and HPR diff GIFs in CME detection
- produce combined NRGF and difference image movie in end-of-day

#### 2.0.64 [Sep 13, 2021]

- name CME HPR/HPR diff FITS files appropriately, i.e, .fts not .fts.gz
- check for invalid HPR/HPR diff data when writing GIF
- fix for writing HPR GIF files

#### 2.0.65 [Sep 21, 2021]

- distribute combined NRGF and difference GIFs and mp4s
- do not create combined NRGF and difference mp4 if only a single GIF
- epoch fixes for 2015 calibration files
- updating SGS plots
- better CME HPR GIF scaling

#### 2.0.66 [Oct 18, 2021]

- distribute 28 day rolling synoptic map FITS files
- allow quicklooks to be created in realtime or at the end-of-day
- set style of quicklooks to be normal, gallery, or both
- use UT date in subject of notification email for CME detection
- better SGS plot titles and ranges

#### 2.0.67 [Oct 20, 2021]

- fix camera x-shift for 20150718, 20151213, 20151217, 20160503, 20170405

#### 2.0.68 [Oct 27, 2021]

- fix camera x-shift for 20170405
- separate logs by year

#### 2.0.69 [Nov 2, 2021]

- distribute engineering plots: SGS, radial intensity, mean pB at height
- add epoch for 20211018
- fix for bug in creation NRGF+subtraction movies

#### 2.0.70 [Nov 16, 2021]

- new epoch for start_state for 20211101
- updated L1 OBJECT FITS keyword comment

#### 2.0.71 [Nov 30, 2021]

- new epoch for start_state for 20211119
- fix for realtime crashes when no OK level 0 files in a launch
- distortion correct raw files for profile plots

#### 2.0.72 [Dec 6, 2021]

- new cal epoch for 20141026 1.0 ms data
- send non-CME detection notification emails from kcor-pipeline@ucar.edu

#### 2.0.73 [Dec 13, 2021]

- send 28 day rolling synoptic maps to engineering directory

#### 2.0.74 [Dec 13, 2021]

- typo

#### 2.0.75 [Dec 14, 2021]

- remove level 0 files that have already been processed

#### 2.0.76 [Jan 6, 2022]

- handle extremely long days in KCOR_DAILY_SYNOPTIC_MAP

#### 2.0.77 [Jan 11, 2022]

- epoch for exposure time differences on 20150420

#### 2.0.78 [Jan 19, 2022]

- epoch for bad polarization start state on 20200816
- epoch for bad occulter ID on 20160914
- put start state for a file in FITS header, quicklook, and calibration_files.txt
- handle no good or acceptable NRGF images for a day
- send all kcor command line utility emails from kcor-pipeline

#### 2.0.79 [Jan 21, 2022]

- handle the string 'NaN' in SGS values
- fix distributing 28 day rolling synoptic GIF to engineering directory
- add CME log errors section to eod notification email

#### 2.0.80 [Jan 21, 2022]

- handle read errors in raw FITS files

#### 2.0.81 [Feb 3, 2022]

- fixes for checking CME log during eod notification email
- new and revised epochs for bad polarization start state and cameras to use
  on 20141024, 20151125, 20171026, 20181022, 20200127, 20200816, 20200828,
  20201009, 20201020, 20201024, 20201128, 20211101, and 20220121
- ignoring NUMSUM=512 cal files on 20190612 so can get a good NUMSUM=171 cal
  file for cal epoch 21.1
- black-and-white NRGF GIFs

#### 2.0.82 [Feb 4, 2022]

- more adjustments to epoch 21.1 on 20190612, 20190618, and 20190702
- epoch for cal data on 20190311

#### 2.0.83 [Feb 14, 2022]

- removing cal epoch for 20211101
- new epoch for bad polarization start state for 20160619 and 20220208
- new epoch for SGS guider error on 20180215
- new epoch for no corresponding cal files for 2.8 ms sci files on 20201018

#### 2.0.84 [Feb 17, 2022]

- fix cal epoch 24 start time on 20201226

#### 2.0.85 [Feb 18, 2022]

- new epochs for bad polarization start state on 20220211
- fix for setting time for epoch lookup during row-col image creation

#### 2.0.86 [Feb 18, 2022]

- fix typo in epochs file

#### 2.0.87 [Mar 3, 2022]

- more epoch fixes for bad polarization start states for 20220211

#### 2.0.88 [Mar 7, 2022]

- more epoch fixes for bad polarization start states for 20220303

#### 2.0.89 [Mar 15, 2022]

- x-shift in camera 1 for 20220303

#### 2.0.90 [Mar 20, 2022]

- fix crashing bug in verification
- added epochs for bad calibration on 20220316

#### 2.0.91 [Mar 31, 2022]

- new epoch for bad polarization start state for 20140610

#### 2.0.92 [Mar 31, 2022]

- typo in epoch file

#### 2.0.93 [Apr 5, 2022]

- plot just process lag if no access to database

#### 2.0.94 [Apr 8, 2022]

- fix for plotting realtime lag without access to database

#### 2.0.95 [Apr 11, 2022]

- debugging info for plotting realtime lag error

#### 2.0.96 [Apr 12, 2022]

- another fix for plotting realtime lag error without access to database

#### 2.0.97 [Apr 28, 2022]

- more logging in validation to track crash in realtime

#### 2.0.98 [Aug 17, 2022]

- more debug logging messages for when realtime hangs in validation
- create/send JSON files for all CME alerts

#### 2.0.99 [Sep 7, 2022]

- epoch fix for bad raw file
- potential fix for realtime hangs in validation (/NO_ABORT on FITS_READ)
- add last_data_time to observer JSON alerts

#### 2.1.0 [Sep 8, 2022]

- do not read at all files from a "no process" epoch

#### 2.1.1 [Oct 2, 2022]

- use default occulter size if occulter ID not found
- fix indexing issue giving incorrect height values in CME report CSV file
- improve formatting of CME report CSV file
- only add points to CME report CSV file if at least on finite measurement and
  since the current CME started

#### 2.1.2 [Oct 3, 2022]

- fixes for CME report formatting
- accept time of observer alert without colons

#### 2.1.3 [Oct 3, 2022]

- more fixes for CME report CSV

#### 2.1.4 [Nov 23, 2022]

- fixes for difference image scales
- fix for bad polarization start state on 20221118

#### 2.1.5 [Nov 28, 2022]

- fix for bad polarization start state on 20221123

#### 2.1.6 [Sep 17, 2023]

- add PRODUCT FITS keyword
- do not stop when running realtime CME detection in simulator
- log CME detection parameters
- add entries to CME database table

#### 2.1.7 [Apr 4, 2024]

- send interim CME reports
- send summary CME report if a new CME occurs during an existing CME
- don't send heartbeat alert if no new data
- new occulters
- epochs for new data

#### 2.1.8 [Apr 10, 2024]

- epochs for new data
- updated validation files

#### 2.1.9 [Apr 10, 2024]

- fix typo in kcor script

#### 2.1.10 [Apr 23, 2024]

- fix to make verification find new configuration file specification
