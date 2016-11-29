#!/bin/csh

unalias ls

set files = `ls -1 *.c *.h`

foreach f ( $files )  #{
   echo $f
   ex $f < ./excmnds1
   ex $f < ./excmnds2
end #}

