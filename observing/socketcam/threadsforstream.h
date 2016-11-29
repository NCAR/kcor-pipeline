// threadsforstream.h   contains the threads used in streaming mode.
// Alice 20120103


UINT StreamProgramCam0(LPVOID lpdwParam)
{
    BIBA        *pBuff_0 = (BIBA *)lpdwParam;
    BIRC        Error = 0xFFFF;
    BiCirHandle CirHandle;
    BFBOOL      Start,Stop,Abort,Pause,Cleanup;
    BFU32       NumFrames;
    Bd          Board_0;

    Board_0 = pBuff_0->hBoard;

    int kkkjj;
    unsigned short *Sbuf;
    unsigned short myval=20;

    BufferQueueSize0 = 0;

    // Loop until clean up is called. Don't write if an error occurs.
    BiControlStatusGet(Board_0,pBuff_0,&Start,&Stop,&Abort,&Pause,&Cleanup);
    while(!Cleanup)
    {
        // Wait until the user stops, aborts or pauses acquisition
        Error = BiCirWaitDoneFrame(Board_0, pBuff_0, INFINITE, &CirHandle);

        // Get the status of what happened.
        BiControlStatusGet(Board_0,pBuff_0,&Start,&Stop,&Abort,&Pause,&Cleanup);

        BiBufferQueueSize (Board_0, pBuff_0, &NumFrames);
        if(NumFrames!=0) {
            BufferQueueSize0++;
            fprintf(stderr,"Board_0 fell behind %d frames.\n", NumFrames);
        }

        if(!Cleanup) {

            // if BI_OK, the buffer is full, i.e. an image is complete
            if(Error == BI_OK) {

                // CirHandle.pBufData is PBFU32
                Sbuf  = (unsigned short *)CirHandle.pBufData;

                #undef  DO_CALC0
                #ifdef  DO_CALC0
                    // see if we can do a very small arithmetic operation
                    for(jj=0;jj<impix;jj++) {
                        *Sbuf++ *= myval;
                    }
                #endif

                #ifdef  DO_LUT0_STREAM // defined in socketcam.c
                        // Apply LUT (lookup table)
                        // plut0_0 is cam0, quad0
                        // plut0_1 is cam0, quad1, etc
                        for(jj=0;jj<impixlut;jj++) {
                            *Sbuf++ = (unsigned short)(*(plut0_0 + *Sbuf));
                            *Sbuf++ = (unsigned short)(*(plut0_1 + *Sbuf));
                            *Sbuf++ = (unsigned short)(*(plut0_2 + *Sbuf));
                            *Sbuf++ = (unsigned short)(*(plut0_3 + *Sbuf));
                        }
                #endif

                // Mark the buffer available
                BiCirStatusSet(Board_0, pBuff_0, CirHandle, BIAVAILABLE);

                // Get Cleanup status
                BiControlStatusGet(Board_0,pBuff_0,
                                   &Start,&Stop,&Abort,&Pause,&Cleanup);

            } // End if Error == BI_OK
            else {
                if     (Error == BI_CIR_ABORTED)
                    fprintf(stderr,"Acquisition has been aborted\n");
                else if(Error == BI_CIR_STOPPED)
                    fprintf(stderr,"Acquisition has been stopped\n");
                else if(Error == BI_ERROR_CIR_WAIT_TIMEOUT)
                    fprintf(stderr,"BiSeqWaitDone has timed out\n");
                else if(Error == BI_ERROR_CIR_WAIT_FAILED)
                    fprintf(stderr,"The wait in BiSeqWaitDone Failed\n");
                else if(Error == BI_ERROR_QEMPTY)
                    fprintf(stderr,"The queue was empty\n");
            }
        }     // End of if !cleaned up
    }         // End while !cleaned up
    return 0;
}

UINT StreamProgramCam1(LPVOID lpdwParam)
{
    BIBA        *pBuff_1 = (BIBA *)lpdwParam;
    BIRC        Error = 0xFFFF;
    BiCirHandle CirHandle;
    BFBOOL      Start,Stop,Abort,Pause,Cleanup;
    BFU32       NumFrames;
    Bd          Board_1;

    Board_1 = pBuff_1->hBoard;

    int jj;
    unsigned short *Sbuf;
    unsigned short myval=30;

    BufferQueueSize1 = 0;

    // Loop until clean up is called. Don't write if an error occurs.
    BiControlStatusGet(Board_1,pBuff_1,&Start,&Stop,&Abort,&Pause,&Cleanup);
    while(!Cleanup)
    {
        // Wait until the user stops, aborts or pauses acquisition
        Error = BiCirWaitDoneFrame(Board_1, pBuff_1, INFINITE, &CirHandle);

        // Get the status of what happened.
        BiControlStatusGet(Board_1,pBuff_1,&Start,&Stop,&Abort,&Pause,&Cleanup);

        BiBufferQueueSize (Board_1, pBuff_1, &NumFrames);
        if(NumFrames!=0) {
            BufferQueueSize1++;
            fprintf(stderr,"Board_1 fell behind %d frames.\n", NumFrames);
        }

        if(!Cleanup) {

            // if BI_OK, the buffer is full, i.e. an image is complete
            if(Error == BI_OK) {

                // CirHandle.pBufData is PBFU32
                Sbuf  = (unsigned short *)CirHandle.pBufData;

                #undef  DO_CALC1
                #ifdef  DO_CALC1
                    // see if we can do a very small arithmetic operation
                    for(jj=0;jj<impix;jj++) {
                        *Sbuf++ *= myval;
                    }
                #endif

                #ifdef  DO_LUT1_STREAM // defined in socketcam.c
                        // Apply LUT (lookup table)
                        // plut1_0 is cam1, quad0
                        // plut1_1 is cam1, quad1, etc
                        for(jj=0;jj<impixlut;jj++) {
                            *Sbuf++ = (unsigned short)(*(plut1_0 + *Sbuf));
                            *Sbuf++ = (unsigned short)(*(plut1_1 + *Sbuf));
                            *Sbuf++ = (unsigned short)(*(plut1_2 + *Sbuf));
                            *Sbuf++ = (unsigned short)(*(plut1_3 + *Sbuf));
                        }
                #endif

                // Mark the buffer available
                BiCirStatusSet(Board_1, pBuff_1, CirHandle, BIAVAILABLE);

                // Get Cleanup status
                BiControlStatusGet(Board_1,pBuff_1,
                                   &Start,&Stop,&Abort,&Pause,&Cleanup);

            } // End if Error == BI_OK
            else {
                if     (Error == BI_CIR_ABORTED)
                    fprintf(stderr,"Acquisition has been aborted\n");
                else if(Error == BI_CIR_STOPPED)
                    fprintf(stderr,"Acquisition has been stopped\n");
                else if(Error == BI_ERROR_CIR_WAIT_TIMEOUT)
                    fprintf(stderr,"BiSeqWaitDone has timed out\n");
                else if(Error == BI_ERROR_CIR_WAIT_FAILED)
                    fprintf(stderr,"The wait in BiSeqWaitDone Failed\n");
                else if(Error == BI_ERROR_QEMPTY)
                    fprintf(stderr,"The queue was empty\n");
            }
        }     // End of if !cleaned up
    }         // End while !cleaned up
    return 0;
}
