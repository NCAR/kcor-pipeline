// threadsforavging.h   contains the threads used in co-averaging mode.
// Alice 20120103


UINT AvgingProgramCam0(LPVOID lpdwParam)
{
    BIBA        *pBuff_0 = (BIBA *)lpdwParam;
    BIRC        Error = 0xFFFF;
    BiCirHandle CirHandle;
    BFBOOL      Start,Stop,Abort,Pause,Cleanup;
    BFU32       NumFrames;
    Bd          Board_0;
    int         iiN, iiQ;
    int         iiNlimit;
    char        myInfo[80];

    Board_0 = pBuff_0->hBoard;

    long jj, ll;
    int qIndx;
    unsigned short *Sbuf;
    BFU32 *pAvg, *pAvgSpace, *pBuffQSz;
    HANDLE hBufferReadyEvent;
    int XorY;

    int DoRestart=0;

    XorY = USE_X;

    // Query status via "BiControlStatusGet" to insure this thread
    // hasn't received a 'Cleanup' and should exit.
    BiControlStatusGet(Board_0,pBuff_0,&Start,&Stop,&Abort,&Pause,&Cleanup);

    // Loop until Cleanup is true.
    while((!Cleanup ) && (KeepRunningCam==TRUE))
    {
        // Determine the correct write buffer
        XorY = XorY%2;
        if ( XorY == USE_X) {
            // Point to the correct write buffer and it's handle
            pAvgSpace         = pAvgSpaceX;
            hBufferReadyEvent = hBufferX0ReadyEvent;
            time ( &TimeStampX ) ;  // Do not do this in Cam 1 thread
            TimeStamp = TimeStampX; // Do not do this in Cam 1 thread
            pBuffQSz  = &BuffQSzX0;
        }
        else {
            // Point to the correct write buffer and it's handle
            pAvgSpace         = pAvgSpaceY;
            hBufferReadyEvent = hBufferY0ReadyEvent;
            time ( &TimeStampY ) ;  // Do not do this in Cam 1 thread
            TimeStamp = TimeStampY; // Do not do this in Cam 1 thread
            pBuffQSz  = &BuffQSzY0;
        }
        XorY++;


        #include "GetImgAndApplyLut0.h" // Wait for and get the first 4 images.


        // Grab the most recent NumIntegrations
        // This may have been changed by an avging start,
        // or by a Stop set in GetImgAndApplyLut0.h above.
        iiNlimit=NumIntegrations;  // Total number of images=NumIntegrations*4


        // Loop through the integrations, starting at 1!
        for(iiN=1;iiN<iiNlimit;iiN++) {

            #include "GetImgAndApplyLut0.h" // Wait for and get the rest.

        }   //  End of iiN NumIntegrations loop

        // Only set the semaphore if everything was successful
        if (Error==BI_OK) SetEvent(hBufferReadyEvent);

    }   // End while !cleaned up
    fprintf(stderr,"\t\t ***********************Board_0 OUTSIDE while %d.\n",
    CamProgramStatus);
    fprintf(logfid,"\t\t ***********************Board_0 OUTSIDE while %d.\n",
    CamProgramStatus);

    if(CamProgramStatus==P_RUNNING) {
        // This does both Cam0 and Cam1
        fprintf(stderr,"\t\t ****brdstop.h in threadsforavging\n");
        fprintf(logfid,"\t\t ****brdstop.h in threadsforavging\n");
        #include "brdstop.h"
        DoRestart=1;
    }

    if(DoAvgImageDump==TRUE)  {
        // This does both Cam0 and Cam1
        #include "writeoutavgs.h"
    }
    else {
        Sleep(500);
    }

    if(CamProgramStatus==P_STOPPED) {
        // This does both Cam0 and Cam1
        fprintf(stderr,"\t\t ****brdclse.h in threadsforavging\n");
        fprintf(logfid,"\t\t ****brdclse.h in threadsforavging\n");
        #include "brdclse.h"
        DoRestart=1;  // Seems to be ok and not cause infinite looping.
    }

    // Exiting the thread, so reset these to initial conditions.
    CamProgram       = P_NONE;
    CamProgramStatus = P_UNKNOWN;
  //KeepRunningCam   = TRUE;  // Done appropriately in parselogic.h

    if(DoRestart==1) { // Create thread to do an 'avging stop'
        hRestartThread = CreateThread(BFNULL,0,
                                 (LPTHREAD_START_ROUTINE)RestartThread,
                                 (LPDWORD)pBuff0, 0, &dwRestartThreadId);
        if (hRestartThread == BFNULL) {
            // Cleanup and Shutdown
            #include "cleanup.h"
            return 0;
        }
        SetThreadPriority(hRestartThread, THREAD_PRIORITY_NORMAL);
    }

    return 0;
}

UINT AvgingProgramCam1(LPVOID lpdwParam)
{
    BIBA        *pBuff_1 = (BIBA *)lpdwParam;
    BIRC        Error = 0xFFFF;
    BiCirHandle CirHandle;
    BFBOOL      Start,Stop,Abort,Pause,Cleanup;
    BFU32       NumFrames;
    Bd          Board_1;
    int         iiN, iiQ;
    int         iiNlimit;
    char        myInfo[80];

    Board_1 = pBuff_1->hBoard;

    long jj, ll;
    int qIndx;
    unsigned short *Sbuf;
    BFU32 *pAvg, *pAvgSpace, *pBuffQSz;
    HANDLE hBufferReadyEvent;
    int XorY;

    XorY = USE_X;

    // Query status via "BiControlStatusGet" to insure this thread
    // hasn't received a 'Cleanup' and should exit.
    BiControlStatusGet(Board_1,pBuff_1,&Start,&Stop,&Abort,&Pause,&Cleanup);

    // Loop until Cleanup is true.
    while((!Cleanup ) && (KeepRunningCam==TRUE))
    {
        // Determine the correct write buffer
        XorY = XorY%2;
        if ( XorY == USE_X) {
            // Point to the correct write buffer and it's handle
            pAvgSpace         = pAvgSpaceX1;
            hBufferReadyEvent = hBufferX1ReadyEvent;
          //time ( &TimeStampX ) ;  // Do not do this in Cam 1 thread
          //TimeStamp = TimeStampX; // Do not do this in Cam 1 thread
            pBuffQSz  = &BuffQSzX1;
        }
        else {
            // Point to the correct write buffer and it's handle
            pAvgSpace         = pAvgSpaceY1;
            hBufferReadyEvent = hBufferY1ReadyEvent;
          //time ( &TimeStampY ) ;  // Do not do this in Cam 1 thread
          //TimeStamp = TimeStampY; // Do not do this in Cam 1 thread
            pBuffQSz  = &BuffQSzY1;
        }
        XorY++;


        #include "GetImgAndApplyLut1.h" // Wait for and get the first 4 images.


        // Grab the most recent NumIntegrations
        // This may have been changed by an avging start,
        // or by a Stop set in GetImgAndApplyLut1.h above.
        iiNlimit=NumIntegrations;  // Total number of images=NumIntegrations*4

        // Loop through the integrations, starting at 1!
        for(iiN=1;iiN<iiNlimit;iiN++) {

            #include "GetImgAndApplyLut1.h" // Wait for and get the rest.

        }   //  End of iiN NumIntegrations loop

        // Only set the semaphore if everything was successful
        if (Error==BI_OK) SetEvent(hBufferReadyEvent);

    }   // End while !cleaned up
    fprintf(stderr,"\t\t ***********************Board_1 OUTSIDE while.\n");
    fprintf(logfid,"\t\t ***********************Board_1 OUTSIDE while.\n");

    // AvgingProgramCam0 handles brdstop.h, writeoutavgs.h, brdclse.h
    // and  CamProgram       = P_NONE;
    // and  CamProgramStatus = P_UNKNOWN;
    // and  KeepRunningCam   = TRUE;

    return 0;
}


void RestartThread(LPVOID lpdwParam)
{
    char my_BufferIn [MY__BYTES];
    int kk, kcmp;
    char my_Status[20];

    fprintf(stderr,"\t\t Restarting avging program with \'avging stop\'\n");
    fprintf(logfid,"\t\t Restarting avging program with \'avging stop\'\n");

    // Load the avging program.
    // It will be loaded, but won't start until an 'avging start'
    // is received.
    sprintf(my_BufferIn,"avging stop");
  //sprintf(my_BufferIn,"stream stop"); // for stream to disk testing
    #include "parselogic.h"
    
    return;
}
