    // createwritethread.h   starts the co-avg write threads
    //
    //             There is a write thread to capture and write the X buffer
    //             and   a separate thread to capture and write the Y buffer
    // Alice 20120103

    #ifdef DEBUG_DO_PRINT_STATEMENTS  // {
    fprintf(stderr,"\n\t\t ***********************createwritethread.h\n\n");
    #endif // DEBUG_DO_PRINT_STATEMENTS }

    // for the X buffer
    hWrtXThread = CreateThread(
                        BFNULL,0,
                        (LPTHREAD_START_ROUTINE)WriteCoAvgDataToDisk_X,
                        NULL, 0, &dwWrtXThread);
    if (hWrtXThread == BFNULL) {
        // Cleanup and Shutdown
        fprintf(logfid,"Couldn't create hWrtXThread\n"); fclose (logfid);
        fprintf(stderr,"Couldn't create hWrtXThread\n");
        KeepRunning = 0;
    }
    else {
        SetThreadPriority(hWrtXThread, THREAD_PRIORITY_NORMAL);

        // for the Y buffer
        hWrtYThread = CreateThread(
                             BFNULL,0,
                             (LPTHREAD_START_ROUTINE)WriteCoAvgDataToDisk_Y,
                             NULL, 0, &dwWrtYThread);
        if (hWrtYThread == BFNULL) {
            // Cleanup and Shutdown
            fprintf(logfid,"Couldn't create hWrtYThread\n"); fclose (logfid);
            fprintf(stderr,"Couldn't create hWrtYThread\n");
            KeepRunning = 0;
        }
        else {
            SetThreadPriority(hWrtYThread, THREAD_PRIORITY_NORMAL);
        }
    }


