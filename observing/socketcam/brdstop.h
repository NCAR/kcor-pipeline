    // brdstop.h   just tells both boards to stop circular acquisitions.
    //             Circular acquisition can be quickly restarted with:
    //             brdstrt.h
    // Alice 20120103

    // Abort all the threads...
    BiCirControl(Board0, pBuff0, BISTOP, BiAsync);
    BiCirControl(Board1, pBuff1, BISTOP, BiAsync);
    // other options are BISTART BIPAUSE BIRESUME BISTOP BIABORT


    fprintf(logfid,"\t\t... brdstop BiCaptureStatusGet\n"); fflush (logfid);

    BiCaptureStatusGet(Board0, pBuff0, pFramesCaptured0, pFramesMissed0);
    fprintf(logfid,"Board0 missed   %d Frames\n", *pFramesMissed0);
    fprintf(logfid,"Board0 captured %d Frames\n", *pFramesCaptured0);

    fflush (logfid);

    BiCaptureStatusGet(Board1, pBuff1, pFramesCaptured1, pFramesMissed1);
    fprintf(logfid,"Board1 missed   %d Frames\n", *pFramesMissed1);
    fprintf(logfid,"Board1 captured %d Frames\n", *pFramesCaptured1);

    fflush (logfid);

    FramesToWrite0 = (FramesCaptured0 <= NumBuffers0) ? FramesCaptured0
                                                      : NumBuffers0;
    FramesToWrite1 = (FramesCaptured1 <= NumBuffers1) ? FramesCaptured1
                                                      : NumBuffers1;


    #ifdef DEBUG_DO_PRINT_STATEMENTS  // {
    fprintf(stderr,"\t\t... brdstop Looping through error stack\n");
    #endif // DEBUG_DO_PRINT_STATEMENTS }


    // Look through the Error stack for boards 0 and 1
    fprintf(logfid,"Looping through error stack for board 0\n");
    fflush (logfid);
    ErrorCheck = BiCirErrorCheck(Board0, pBuff0);
    fprintf(logfid,"BiCirErrorCheck board 0\n"); fflush (logfid);
    while(ErrorCheck != BI_OK) {
        BiErrorShow(Board0, ErrorCheck);
        ErrorCheck = BiCirErrorCheck(Board0, pBuff0);
    }
    fprintf(logfid,"Done with error stack for board 0\n");

    fprintf(logfid,"Looping through error stack for board 1\n");
    ErrorCheck = BiCirErrorCheck(Board1, pBuff1);
    while(ErrorCheck != BI_OK) {
        BiErrorShow(Board1, ErrorCheck);
        ErrorCheck = BiCirErrorCheck(Board1, pBuff1);
    }
    fprintf(logfid,"Done with error stack for board 1\n"); fflush (logfid);

    #ifdef DEBUG_DO_PRINT_STATEMENTS  // {
    fprintf(stderr,"\t\t... brdstop Looping through error stack... done\n");
    #endif // DEBUG_DO_PRINT_STATEMENTS }


    // Send information to the client on lagging, ie. missed frames.
    sprintf(my_Res,"cam lagged %d %d",BufferQueueSize0,BufferQueueSize1);
    SendSignals(my_Res);



    CamProgramStatus = P_STOPPED;
