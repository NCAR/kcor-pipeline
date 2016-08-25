#!/bin/csh
#-------------------------------------------------------------------------------
# runkcor_rg2m.sh
#-------------------------------------------------------------------------------
# Execute "dokcor_rg2m" perl script, which generates RG 
# (normalized, radially-graded filter) GIF images, using kcor L1 fits files.
#-------------------------------------------------------------------------------
# Andrew L. Stanger   HAO/NCAR
#-------------------------------------------------------------------------------
# 28 May 2015 
# 28 Jan 2016 adapted from "runkcor_nrgf2m.sh".
# 01 Mar 2016 change source file from /home/stanger/.tcshrc to /home/iguana/.cshrc 
#-------------------------------------------------------------------------------

echo "runkcor_rgrm.sh --- start"

#--- Set up environment path variables.

source /home/iguana/.cshrc

#--- Get today's date.

set datestr = `date +"%Y%m%d"`

set datestr = '20150526'

#--- Execute "dokcor_rg2m" (perl).

/hao/acos/sw/bin/dokcor_rg2m  $datestr  okl1gz.ls

echo "runkcor_rg2m.sh --- end"
