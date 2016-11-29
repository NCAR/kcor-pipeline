    // createthread1.h   starts the error thread and camera thread for board 1.
    //
    //             The correct camera thread, avging or streaming, is set up
    //             via a pointer to pProgramCam1
    // Alice 20120103

  //fprintf(stderr,"\n\t\t ***********************createthread1.h\n\n");

    // Create thread to catch camera errors
    hErrThread1 = CreateThread(BFNULL,0,(LPTHREAD_START_ROUTINE)ErrorThread1,
                             (LPDWORD)pBuff1, 0, &dwErrThreadId1);
    if (hErrThread1 == BFNULL) {
        // Cleanup and Shutdown
        #include "cleanup.h"
        return;
    }
    SetThreadPriority(hErrThread1, THREAD_PRIORITY_NORMAL);


    // Create thread to capture and process images.
    hAcqThread1 = CreateThread(BFNULL,0,
                              (LPTHREAD_START_ROUTINE)pProgramCam1,
                              (LPDWORD)pBuff1, 0, &dwAcqThreadId1);
    if (hAcqThread1 == BFNULL) {
        // Cleanup and Shutdown
        #include "cleanup.h"
        return;
    }
    SetThreadPriority(hAcqThread1, THREAD_PRIORITY_NORMAL);

    #ifdef DEBUG_DO_PRINT_STATEMENTS  // {
    fprintf(stderr,"dwErrThreadId1 %x dwAcqThreadId1 %x\n",
                    dwErrThreadId1,   dwAcqThreadId1);
    #endif // DEBUG_DO_PRINT_STATEMENTS }
