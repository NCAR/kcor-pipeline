    // parselogic.h parses the command string passed to it
    //              from a client (labview) via tcp/ip sockets.
    //              If there is a problem with the string, the logic
    //              will default to a condition that will do nothing,
    //              and safely close if the boards were open.
    // Alice 20120103

CamProgramDesired       = P_NONE;
CamProgramDesiredStatus = P_CLOSED;

    // Determine the desired program
    if( (kcmp = strncmp("stream" ,(const char *)my_BufferIn,6)) == 0) {
        CamProgramDesired       = P_STREAM;
    }
    if( (kcmp = strncmp("avging" ,(const char *)my_BufferIn,6)) == 0) {
        CamProgramDesired       = P_AVGING;
    }

    // Determine the desired status
    kk = sscanf(my_BufferIn,"%*s %s %d %d %d",my_Status,
                                           &NumIntegrations,&qIndxStart,
                                           &DoAvgImageDump);
    if ( kk >= 1 ) {
        if( (kcmp = strncmp("start"  ,(const char *)my_Status,5)) == 0) {
            CamProgramDesiredStatus = P_RUNNING;

            if ( kk < 3 ) { // load some default values
                NumIntegrations=512; qIndxStart=0; DoAvgImageDump =FALSE;
            }
            if ( kk==3 ) DoAvgImageDump =FALSE;
        }
        else {
            if( (kcmp = strncmp("stop"   ,(const char *)my_Status,4)) == 0) {
                CamProgramDesiredStatus = P_STOPPED;
            }
            if( (kcmp = strncmp("gent"   ,(const char *)my_Status,4)) == 0) {
                CamProgramDesiredStatus = P_GENTLESTOP;
            }
        }
    }

    #ifdef DEBUG_DO_PRINT_STATEMENTS  // {
    fprintf(stderr,"Got %d %d\n",CamProgramDesired,CamProgramDesiredStatus);
    fprintf(stderr,"kk %d N qI Dump %d %d %d\n",kk,NumIntegrations,qIndxStart,
                                          DoAvgImageDump);
    fprintf(logfid,"Got %d %d\n",CamProgramDesired,CamProgramDesiredStatus);
    fprintf(logfid,"kk %d N qI Dump %d %d %d\n",kk,NumIntegrations,qIndxStart,
                                          DoAvgImageDump);
    #endif // DEBUG_DO_PRINT_STATEMENTS  }




    // Compare with the current status and take appropriate actions

    // Check if there is a change in program.
    if ( CamProgramDesired != CamProgram ) {
        // Stop any currently running program.
        if (CamProgram != P_NONE ) {
            fprintf(stderr,"parselogic CamProgram != P_NONE\n");
            fprintf(logfid,"parselogic CamProgram != P_NONE\n");
            // Send a stop...
            #include "brdstop.h"
            // Close the boards...
            #include "brdclse.h"
        }

        // Take appropriate action for the new program.
        switch (CamProgramDesired) {
            case P_STREAM:
                #ifdef DEBUG_DO_PRINT_STATEMENTS  // {
                fprintf(stderr,"Setting up for P_STREAM\n");
                fprintf(logfid,"Setting up for P_STREAM\n");
                #endif // DEBUG_DO_PRINT_STATEMENTS  }
                // Increase the number of buffers to accomodate 14 seconds
                // of stream data.
                NumBuffers0 = 1984;
                NumBuffers1 = 1984;
                // open the Boards
                #include "brdopen0.h"
                #include "brdopen1.h"
                SendSignals("cam ready stream");
                // Point to the proper program
                pProgramCam0 = &StreamProgramCam0;
                pProgramCam1 = &StreamProgramCam1;
                // create (but do not start) the acquisition threads
                #include "createthread0.h"
                #include "createthread1.h"
                CamProgram       = P_STREAM;
                CamProgramStatus = P_OPENED;

                if (CamProgramDesiredStatus==P_RUNNING) {
                    // get the time
                    time ( &TimeStamp ) ;
                    // start the acquisition threads
                    #include "brdstrt.h"
                }
                // Take no action for a new program asking for "stop"
                break;
            case P_AVGING:
                #ifdef DEBUG_DO_PRINT_STATEMENTS  // {
                fprintf(stderr,"Setting up for P_AVGING\n");
                fprintf(logfid,"Setting up for P_AVGING\n");
                #endif // DEBUG_DO_PRINT_STATEMENTS  }
                // Lower the number of buffers to accomodate
                // memory for averaging data.
                NumBuffers0 = 1032;  // evenly divisible by 8
                NumBuffers1 = 1032;  // evenly divisible by 8
                // open the Boards
                #include "brdopen0.h"
                #include "brdopen1.h"

                SendSignals("cam ready avging");
                KeepRunningCam=TRUE;  // Insure the avging threads can run
                // Point to the proper program
                pProgramCam0 = &AvgingProgramCam0;
                pProgramCam1 = &AvgingProgramCam1;
                // create (but do not start) the acquisition threads
                #include "createthread0.h"
                #include "createthread1.h"
                CamProgram       = P_AVGING;
                CamProgramStatus = P_OPENED;
                if (CamProgramDesiredStatus==P_RUNNING) {
                    // get the time
                    time ( &TimeStamp ) ;
                    // Start the acquisition threads
                    #include "brdstrt.h"
                }
                // Take no action for a new program asking for "stop"
                break;
            case P_NONE:
                // If something was running it should have been stopped above.
                // Check if we got a quit.
                // Just log the response.  Don't do anything with it.
                if( (kcmp = strncmp("quit",(const char *)my_BufferIn,4))==0) {
                    fprintf(stderr,"Got a \'quit\'. Client is going away.\n");
                    fprintf(logfid,"Got a \'quit\'. Client is going away.\n");
                }
                break;
            default:
                ;
        }
    }
    else { // The correct program is loaded, just need to match status
        if (CamProgramStatus != CamProgramDesiredStatus) {
            switch (CamProgramDesiredStatus) {
                case P_RUNNING:
                    KeepRunningCam=TRUE;  // Insure the avging threads can run
                    // get the time
                    time ( &TimeStamp ) ;
                    // start the acquisition threads
                    #include "brdstrt.h"
                    // The very first time avging is called,
                    // TimeStampX is already old,
                    // so try to keep it more timely by doing this.
                    // Recall TimeStampX is not used until the image
                    // is written out.
                    TimeStampX = TimeStamp;
                    TimeStampY = TimeStamp;
                    break;
                case P_STOPPED:
                    fprintf(stderr,"parselogic P_STOPPED\n");
                    fprintf(logfid,"parselogic P_STOPPED\n");
                    #include "brdstop.h"
                    KeepRunningCam=FALSE;  // Gently stop P_AVGING
                    if(CamProgram==P_STREAM)  {
                        #include "writeoutstrm.h"
                    }
                    // P_AVGING data is written out via the threads in
                    // threadsforwriting.h (WriteCoAvgDataToDisk_X or _Y)
                    //
                    // But if DoAvgImageDump==TRUE, the last 1024
                    // individual images will be written out
                    // with writeoutavgs.h below.
                    if((CamProgram==P_AVGING)&&(DoAvgImageDump==TRUE))  {
                        #include "writeoutavgs.h"
                    }
                    break;
                case P_GENTLESTOP:
                    fprintf(stderr,"parselogic P_GENTLESTOP\n");
                    fprintf(logfid,"parselogic P_GENTLESTOP\n");
                    KeepRunningCam=FALSE;  // Gently stop P_AVGING
                    CamProgramDesiredStatus = P_STOPPED;
                    // If P_AVGING, AvgingProgramCam0
                    // will call brdstop.h
                    if(CamProgram==P_STREAM)  {
                        #include "brdstop.h"
                        #include "writeoutstrm.h"
                    }
                    // P_AVGING data is written out via the threads in
                    // threadsforwriting.h (WriteCoAvgDataToDisk_X or _Y)
                    //
                    // If DoAvgImageDump==TRUE, the last 1024
                    // individual images will be written out in
                    // AvgingProgramCam0 with writeoutavgs.h
                    break;
                default:
                    ;
            }
        }
        else {
            fprintf(stderr,
                "parselogic program and status matches, nothing to do.\n");
            fprintf(logfid,
                "parselogic program and status matches, nothing to do.\n");
        }
    }
