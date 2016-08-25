#!/bin/csh
#-------------------------------------------------------------------------------
# runkcor_eod.sh
#-------------------------------------------------------------------------------
# Execute "kcor_eod" perl script, which verifies that all kcor L0 files
# in the level0 directory match the list of files in the yyyymmdd.kcor.t1.log
# file.
#
# If all T1 files are found, and the sizes are correct:
#    kcor_eod generates IDL calls to "kcorp.pro" and "dokcor_catalog.pro".
#
#    "kcorar" [perl] is called by "kcor_eod" to generate a tar file,
#    a tar list, and to insert a link to the tar file in the HPSS-Queue/KCor
#    directory.
#
#    An E-mail message is sent with the status: "ok'.
#
# Otherwise, an E-mail message is sent with the status: "error".
# 
#-------------------------------------------------------------------------------
# Andrew L. Stanger   HAO/NCAR
#-------------------------------------------------------------------------------
# 21 Apr 2015 
# 04 May 2015 Add dokcor_nrgf.
# 30 May 2015 Remove dokcor_nrgf.
#-------------------------------------------------------------------------------

echo "runkcor_eod.sh --- start"

#--- Set up environment path variables.

source /home/iguana/.cshrc

#--- Get today's date.

set datestr = `date +"%Y%m%d"`

#--- Execute "kcor_eod" (perl).

/hao/acos/sw/bin/kcor_eod $datestr

