    // brdopen1.h  opens camera board 1 for circular buffers
    //             and gets the locations in memory of all the images
    // Alice 20120103

    // Open the camera board
    fprintf(logfid,"\tBiBrdOpen\n"); fflush (logfid);
    Error = BiBrdOpen(BiTypeR64, 1, &Board1);
    if(Error != BI_OK) {
        BiErrorShow  (Board1, Error);
        return;
    }

    // Allocate memory for buffers
    fprintf(logfid,"\tBiBufferAllocCam\n"); fflush (logfid);
    Error = BiBufferAllocCam(Board1, pBuff1, NumBuffers1);
    if(Error != BI_OK) {
        BiErrorShow  (Board1, Error);
        BiBrdClose   (Board1);
        return;
    }

    // Setup for circular buffers
    fprintf(logfid,"\tBiCircAqSetup\n"); fflush (logfid);
    Error = BiCircAqSetup(Board1, pBuff1, ErrorMode, CirSetupOptions);
    if(Error != BI_OK) {
        BiErrorShow  (Board1, Error);
        BiBufferFree (Board1, pBuff1);
        BiBrdClose   (Board1);
        return;
    }

    // Get pointers to the images.
    BiBufferArrayGet(Board1, pBuff1, &pBufferArray1);
