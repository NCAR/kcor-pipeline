    // createthread0.h   starts the error thread and camera thread for board 0.
    //
    //             The correct camera thread, avging or streaming, is set up
    //             via a pointer to pProgramCam0
    // Alice 20120103

  //fprintf(stderr,"\n\t\t ***********************createthread0.h\n\n");

    // Create thread to catch camera errors
    hErrThread0 = CreateThread(BFNULL,0,(LPTHREAD_START_ROUTINE)ErrorThread0,
                             (LPDWORD)pBuff0, 0, &dwErrThreadId0);
    if (hErrThread0 == BFNULL) {
        // Cleanup and Shutdown
        #include "cleanup.h"
        return;
    }
    SetThreadPriority(hErrThread0, THREAD_PRIORITY_NORMAL);


    // Create thread to capture and process images.
    hAcqThread0 = CreateThread(BFNULL,0,
                              (LPTHREAD_START_ROUTINE)pProgramCam0,
                              (LPDWORD)pBuff0, 0, &dwAcqThreadId0);
    if (hAcqThread0 == BFNULL) {
        // Cleanup and Shutdown
        #include "cleanup.h"
        return;
    }
    SetThreadPriority(hAcqThread0, THREAD_PRIORITY_NORMAL);

    #ifdef DEBUG_DO_PRINT_STATEMENTS  // {
    fprintf(stderr,"dwErrThreadId0 %x dwAcqThreadId0 %x\n",
                    dwErrThreadId0,   dwAcqThreadId0);
    #endif // DEBUG_DO_PRINT_STATEMENTS }
