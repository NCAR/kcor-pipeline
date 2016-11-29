// threadsforwriting.h
//
// This thread will write the co-avgeraged data to disk.
//
// It waits for a semaphore that an average image cube
// is ready to write out.
// It writes out the data, re-initializes (zeros out) the avging buffer,
// and sends a message back to the client with information on lagging
// ie. missed frames.
//
// There is a thread for the X buffer and a separate thread for the Y buffer.
//
// Alice 20120123


void WriteCoAvgDataToDisk_X (void *dummy) {

    BFU32 *pAv;
    short *pAv16;
    long  ll;
    FILE  *afid;
    char afilenm[120];
    char sfilenm[120];
    char aStr[MY__BYTES];
    struct tm *aTS, mylocalTS, *lTS;

    lTS = &mylocalTS;


    fprintf(logfid,"\tStarting WriteCoAvgDataToDisk_X\n");

    while (KeepRunning == TRUE ) {
        // wait for semaphore from BufferX, cam0 and cam1
        WaitForSingleObject(hBufferX0ReadyEvent, INFINITE);
        WaitForSingleObject(hBufferX1ReadyEvent, INFINITE);

      //fprintf(stderr,"hBufferX0ReadyEvent \n");

        // See if there is an image to write or if
        // this routine was killed from main.
        if (KeepRunning == TRUE ) {
            // mutex the avg image TimeStamp and buffer too?
            // may not need a mutex ??? TODO
            // WaitForSingleObject(hBufferXMutex,INFINITE);

            // Put NumIntegrations and starting quad state into the image.
            pAv    = pAvgSpaceX;
          //*pAv++ = NumIntegrations;
          //*pAv++ = qIndxStart;

            // Convert the time stamp to human readable terms
            // localtime and gmtime overwrite the same memory,
            // regardless of the pointer name.
            // So, need to copy the string to our own location
            // in memory.
            aTS = localtime(&TimeStampX);
            *lTS = *aTS;
            aTS = gmtime(&TimeStampX);

            // write the avg image cube
            pAv = pAvgSpaceX;
          //#include "writeAvg.h"
            #include "writeAvg16.h"

            // zero out the avging buffer.
            pAv = pAvgSpaceX;
            for(ll=0;ll<impixavg;ll++){
                *pAv++=0;
            }
            // ReleaseMutex(hBufferXMutex);

            // send a message back to the client with lagging
            // ie. missed frames
            BufferQueueSize0 = BuffQSzX0;
            BufferQueueSize1 = BuffQSzX1;
            sprintf(aStr,"img %s laggedX %d %d",
                afilenm,BufferQueueSize0,BufferQueueSize1);
            SendSignals(aStr);
            BuffQSzX0 = BuffQSzX1 = 0;
        }
    }
    #ifdef DEBUG_DO_PRINT_STATEMENTS  // {
    fprintf(logfid,"\tExiting  WriteCoAvgDataToDisk_X\n");
    fprintf(stderr,"\tExiting  WriteCoAvgDataToDisk_X\n");
    #endif // DEBUG_DO_PRINT_STATEMENTS }


}


void WriteCoAvgDataToDisk_Y (void *dummy) {

    BFU32 *pAv;
    short *pAv16;
    long  ll;
    FILE  *afid;
    char afilenm[120];
    char sfilenm[120];
    char aStr[MY__BYTES];
    struct tm *aTS, mylocalTS, *lTS;

    lTS = &mylocalTS;

    fprintf(logfid,"\tStarting WriteCoAvgDataToDisk_Y\n");

    while (KeepRunning == TRUE ) {
        // wait for semaphore from BufferY, cam0 and cam1
        WaitForSingleObject(hBufferY0ReadyEvent, INFINITE);
        WaitForSingleObject(hBufferY1ReadyEvent, INFINITE);

      //fprintf(stderr,"hBufferY0ReadyEvent \n");

        // See if there is an image to write or if
        // this routine was killed from main.
        if (KeepRunning == TRUE ) {
            // mutex the avg image TimeStamp and buffer too?
            // may not need a mutex ??? TODO
            // WaitForSingleObject(hBufferYMutex,INFINITE);

            // Put NumIntegrations and starting quad state into the image.
            pAv    = pAvgSpaceY;
          //*pAv++ = NumIntegrations;
          //*pAv++ = qIndxStart;

            // Convert the time stamp to human readable terms
            // localtime and gmtime overwrite the same memory,
            // regardless of the pointer name.
            // So, need to copy the string to our own location
            // in memory.
            aTS = localtime(&TimeStampY);
            *lTS = *aTS;
            aTS = gmtime(&TimeStampY);

            // write the avg image cube
            pAv = pAvgSpaceY;
          //#include "writeAvg.h"
            #include "writeAvg16.h"

            // zero out the avging buffer.
            pAv = pAvgSpaceY;
            for(ll=0;ll<impixavg;ll++){
                *pAv++=0;
            }
            //ReleaseMutex(hBufferYMutex);

            // send a message back to the client with lagging
            // ie. missed frames
            BufferQueueSize0 = BuffQSzY0;
            BufferQueueSize1 = BuffQSzY1;
            sprintf(aStr,"img %s laggedY %d %d",
                afilenm,BufferQueueSize0,BufferQueueSize1);
            SendSignals(aStr);
            BuffQSzY0 = BuffQSzY1 = 0;
        }
    }
    #ifdef DEBUG_DO_PRINT_STATEMENTS  // {
    fprintf(logfid,"\tExiting  WriteCoAvgDataToDisk_Y\n");
    fprintf(stderr,"\tExiting  WriteCoAvgDataToDisk_Y\n");
    #endif // DEBUG_DO_PRINT_STATEMENTS }


}
