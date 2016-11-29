    // writestrmtif0.h   writes out either avging or strm image data.
    //
    // Alice 20120103

    if(FramesToWrite0>1) {
        sprintf(filenm,"%scam0_.tif",mydir);
        Error = BFIOWriteMultiple(filenm,pBufferArray0,StartFrame,
                xsz,ysz,16,FramesToWrite0-1,0);
        if(Error != BI_OK) {
            // Show Error and Shutdown.
            BiErrorShow  (Board0, Error);
            #include "cleanup.h"
        }
    }
