    // brdopen0.h  opens camera board 0 for circular buffers
    //             and gets the locations in memory of all the images.
    // Alice 20120103

    // Open the camera board
    fprintf(logfid,"\tBiBrdOpen\n"); fflush (logfid);
    Error = BiBrdOpen(BiTypeR64, 0, &Board0);
    if(Error != BI_OK) {
        BiErrorShow  (Board0, Error);
        return;
    }

    // Allocate memory for buffers
    fprintf(logfid,"\tBiBufferAllocCam\n"); fflush (logfid);
    Error = BiBufferAllocCam(Board0, pBuff0, NumBuffers0);
    if(Error != BI_OK) {
        BiErrorShow  (Board0, Error);
        BiBrdClose   (Board0);
        return;
    }

    // Setup for circular buffers
    fprintf(logfid,"\tBiCircAqSetup\n"); fflush (logfid);
    Error = BiCircAqSetup(Board0, pBuff0, ErrorMode, CirSetupOptions);
    if(Error != BI_OK) {
        BiErrorShow  (Board0, Error);
        BiBufferFree (Board0, pBuff0);
        BiBrdClose   (Board0);
        return;
    }

    // Get pointers to the images.
    BiBufferArrayGet(Board0, pBuff0, &pBufferArray0);
