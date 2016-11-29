    // brdstrt.h   just tells both boards to start circular acquisitions.
    //             Circular acquisition can be quickly stopped with:
    //             brdstop.h
    // Alice 20120103

    #ifdef DEBUG_DO_PRINT_STATEMENTS  // {
    fprintf(stderr,"\n\t\t ***********************brdstrt.h\n\n");
    #endif // DEBUG_DO_PRINT_STATEMENTS  }

    // KeepRunningCam=TRUE; // Doing this here in brdstrt is too late.
    // KeepRunningCam=TRUE is done initially in socketcam
    // and then reset to TRUE at the very end of
    // threadsforavging.h:AvgingProgramCam0

    // Start Circular Acquisition Board0
    Error = BiCirControl(Board0, pBuff0, BISTART, BiAsync);
    if(Error != BI_OK) {
        if(Error < BI_WARNINGS) {
            // Show Error and Cleanup and Shutdown
            BiErrorShow  (Board0,Error);
            #include "cleanup.h"
            return;
        }
    }
    #ifdef DEBUG_DO_PRINT_STATEMENTS  // {
    if(Error == BI_OK)
        fprintf(logfid,"0 Circular Acquisition Started.\n");
    #endif // DEBUG_DO_PRINT_STATEMENTS  }

    // Start Circular Acquisition Board1
    Error = BiCirControl(Board1, pBuff1, BISTART, BiAsync);
    if(Error != BI_OK) {
        if(Error < BI_WARNINGS) {
            // Show Error and Cleanup and Shutdown
            BiErrorShow  (Board1,Error);
            #include "cleanup.h"
            return;
        }
    }
    #ifdef DEBUG_DO_PRINT_STATEMENTS  // {
    if(Error == BI_OK)
        fprintf(logfid,"1 Circular Acquisition Started.\n");
    #endif // DEBUG_DO_PRINT_STATEMENTS  }

    CamProgramStatus = P_RUNNING;
