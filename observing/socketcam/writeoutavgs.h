    // writeoutavgs.h   writes out the last 1024 individual images
    //             captured during co-avging image acquisition.
    //             Since this raw data is just like the stream data,
    //             use writestrm[01].h or writestrmtif[01].h
    //             to write out the images.
    // Alice 20120103

    // Convert the time stamp to human readable terms
    TS = gmtime(&TimeStamp);

    // Set up the directory name based on timestamp
    sprintf(mydir,"e:/%4d%02d%02d",TS->tm_year+1900,TS->tm_mon+1,TS->tm_mday);

    // Check if the directory exists, if not, make it.
    NotYet = CreateDirectory((char *)mydir,NULL);


    if(writebin==1) {
        // Fully determine the directory
        sprintf(mydir,"%s/avg/",mydir);
        // Check if the directory exists, if not, make it.
        NotYet = CreateDirectory((char *)mydir,NULL);

        // Fully determine the filename
        sprintf(mydir,"%s/%4d%02d%02d_%02d%02d%02d",mydir,
                         TS->tm_year+1900,TS->tm_mon+1,TS->tm_mday,
                         TS->tm_hour,TS->tm_min,TS->tm_sec);

        // Write out binary images...
        for(imgNo=0;imgNo<FramesToWrite0;imgNo++) {
            Abuf = (unsigned char *)pBufferArray0[imgNo];
            #include "writestrm0.h"
        }
        for(imgNo=0;imgNo<FramesToWrite1;imgNo++) {
            Abuf = (unsigned char *)pBufferArray1[imgNo];
            #include "writestrm1.h"
        }
    }
    if(writetif==1) {
        // Fully determine the directory
        sprintf(mydir,"%s/%02d%02d%02dtifA/",mydir,
                       TS->tm_hour,TS->tm_min,TS->tm_sec);
        // Check if the directory exists, if not, make it.
        NotYet = CreateDirectory((char *)mydir,NULL);

        // Fully determine the filename
        sprintf(mydir,"%s/%4d%02d%02d_%02d%02d%02d",mydir,
                         TS->tm_year+1900,TS->tm_mon+1,TS->tm_mday,
                         TS->tm_hour,TS->tm_min,TS->tm_sec);

        // Write out tif images...
        #include "writestrmtif0.h"
        #include "writestrmtif1.h"
    }

    // Tell the client that the raw images have finished
    // writing to disk.
    sprintf(my_Res,"write avging done %d %d",FramesToWrite0,FramesToWrite1);
    SendSignals(my_Res);

    #ifdef DEBUG_DO_PRINT_STATEMENTS  // {
    fprintf(stderr,"Finished writeoutavgs.h\n");
    fprintf(logfid,"Finished writeoutavgs.h\n");;
    #endif // DEBUG_DO_PRINT_STATEMENTS  }
