    // brdclse.h  just safely closes both camera boards.
    // Alice 20120103

    // Clean up Board0
    Error = BiCircCleanUp(Board0, pBuff0);
    if(Error != BI_OK) {
        fprintf(logfid,"Error from BiCircCleanUp Board0\n"); fflush (logfid);
        BiErrorShow(Board0,Error);
    }
    fprintf(logfid,"Done with BiCircCleanUp Board0\n"); fflush (logfid);

    // Free memory Board0
    Error = BiBufferFree(Board0, pBuff0);
    if(Error != BI_OK) BiErrorShow(Board0,Error);

    fprintf(logfid,"Done with BiBufferFree Board0\n"); fflush (logfid);

    // Close Board0
    Error = BiBrdClose(Board0);
    if(Error != BI_OK) BiErrorShow(Board0,Error);
    fprintf(logfid,"Done with BiBrdClose Board0\n"); fflush (logfid);

    // Clean up Board1
    Error = BiCircCleanUp(Board1, pBuff1);
    if(Error != BI_OK) {
        fprintf(logfid,"Error from BiCircCleanUp Board1\n"); fflush (logfid);
        BiErrorShow(Board1,Error);
    }
    fprintf(logfid,"Done with BiCircCleanUp Board1\n"); fflush (logfid);

    // Free memory Board1
    Error = BiBufferFree(Board1, pBuff1);
    if(Error != BI_OK) BiErrorShow(Board1,Error);
    fprintf(logfid,"Done with BiBufferFree Board1\n"); fflush (logfid);

    // Close Board1
    Error = BiBrdClose(Board1);
    if(Error != BI_OK) BiErrorShow(Board1,Error);
    fprintf(logfid,"Done with BiBrdClose Board1\n"); fflush (logfid);


    CamProgram       = P_NONE;
    CamProgramStatus = P_CLOSED;
