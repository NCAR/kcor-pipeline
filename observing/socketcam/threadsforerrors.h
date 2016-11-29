// threadsforerrors.h  contains the threads used for error checking.
// Alice 20120103


UINT ErrorThread0(LPVOID lpdwParam) {
    BIBA   *pBuff_0 = (BIBA *)lpdwParam;
    BIRC   rv;
    BFBOOL Start,Stop,Abort,Pause,Cleanup;
    Bd     Board_0;

    Board_0 = pBuff_0->hBoard;

    BiControlStatusGet(Board_0,pBuff_0,&Start,&Stop,&Abort,&Pause,&Cleanup);
    while(!Cleanup) {
        // Wait here until a acquisition error occurs
        rv = BiCirErrorWait(Board_0, pBuff_0);

        // If a error is returned by BiCirWaitError, stop the program
        if(rv == BI_ERROR_CIR_ACQUISITION) {
            fprintf(logfid,"Brd0 circular acquisition error has occured.\n\n");
            fprintf(stderr,"Brd0 circular acquisition error has occured.\n\n");
        }
        // Get Cleanup status
        BiControlStatusGet(Board_0,pBuff_0,&Start,&Stop,&Abort,&Pause,&Cleanup);
    }
    return 0;
}


UINT ErrorThread1(LPVOID lpdwParam) {
    BIBA   *pBuff_1 = (BIBA *)lpdwParam;
    BIRC   rv;
    BFBOOL Start,Stop,Abort,Pause,Cleanup;
    Bd     Board_1;

    Board_1 = pBuff_1->hBoard;

    BiControlStatusGet(Board_1,pBuff_1,&Start,&Stop,&Abort,&Pause,&Cleanup);
    while(!Cleanup) {
        // Wait here until a acquisition error occurs
        rv = BiCirErrorWait(Board_1, pBuff_1);

        // If a error is returned by BiCirWaitError, stop the program
        if(rv == BI_ERROR_CIR_ACQUISITION) {
            fprintf(logfid,"Brd1 circular acquisition error has occured.\n\n");
            fprintf(stderr,"Brd1 circular acquisition error has occured.\n\n");
        }

        // Get Cleanup status
        BiControlStatusGet(Board_1,pBuff_1,&Start,&Stop,&Abort,&Pause,&Cleanup);
    }
    return 0;
}
