    // writestrmtif1.h   writes out either avging or strm image data.
    //
    // Alice 20120103

    if(FramesToWrite1>1) {
        sprintf(filenm,"%scam1_.tif",mydir);
        Error = BFIOWriteMultiple(filenm,pBufferArray1,StartFrame,
                xsz,ysz,16,FramesToWrite1-1,0);
        if(Error != BI_OK) {
            // Show Error and Shutdown.
            BiErrorShow  (Board1, Error);
            #include "cleanup.h"
        }
    }
