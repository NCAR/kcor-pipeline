#!/bin/tcsh
#-------------------------------------------------------------------------------
# runkcorl1.sh
#-------------------------------------------------------------------------------
#--- tcsh script to execute 'dokcorl1s' (perl script).
#--- Performs Kcor L1 processing.
#-------------------------------------------------------------------------------
# Andrew L. Stanger   HAO/NCAR   1 April 2015
# 09 Dec 2015 Replace dokcorl1v with dokcorl1.
#-------------------------------------------------------------------------------

echo "--- runkcorl1.sh  start"

#--- Set up environment path variables.

source /home/iguana/.cshrc
umask 002

#--- Get current date.

set datestr = `date +"%Y%m%d"`

#--- Execute perl script program to do kcor L1 processing.

/hao/acos/sw/bin/dokcorl1 $datestr

echo "--- runkcorl1.sh  end"
