// GetImgAndApplyLut0.h   grabs the image from the board and applies the LUT
//                        for Cam0
// Alice 20120207


            pAvg = pAvgSpace;

            // Loop through each Modulator Quad State
            for(iiQ=0;iiQ<4;iiQ++) {

                // Wait until something happens:  stop, abort or pause.
                Error = BiCirWaitDoneFrame(Board_0,pBuff_0,INFINITE,&CirHandle);

                // Get the status of what happened.
                BiControlStatusGet(Board_0,pBuff_0,
                    &Start,&Stop,&Abort,&Pause,&Cleanup);

                BiBufferQueueSize (Board_0, pBuff_0, &NumFrames);
                if(NumFrames!=0) {
                    *pBuffQSz += NumFrames;
                    #ifdef DEBUG_DO_PRINT_STATEMENTS  // {
                    fprintf(stderr,"Board_0 fell behind %d frames.\n",
                        NumFrames);
                    #endif //}
                }

                if(!Cleanup) {

                    // if BI_OK, the buffer is full, i.e. an image is complete
                    if(Error == BI_OK) {

                        // Grab a pointer to the image
                        // CirHandle.pBufData is PBFU32
                        Sbuf  = (unsigned short *)CirHandle.pBufData;

                        #ifdef  DO_LUT0 // defined in socketcam.c
                        // Apply LUT (lookup table)
                        // plut0_0 is cam0, quad0
                        // plut0_1 is cam0, quad1, etc
                        for(jj=0;jj<impixlut;jj++) {
                            *pAvg++ += *(plut0_0 + *Sbuf++);
                            *pAvg++ += *(plut0_1 + *Sbuf++);
                            *pAvg++ += *(plut0_2 + *Sbuf++);
                            *pAvg++ += *(plut0_3 + *Sbuf++);
                        }
                        #else
                        for(jj=0;jj<impixlut;jj++) {
                            *pAvg++ += *Sbuf++;
                            *pAvg++ += *Sbuf++;
                            *pAvg++ += *Sbuf++;
                            *pAvg++ += *Sbuf++;
                        }
                        #endif

                        // Mark the buffer available
                        BiCirStatusSet(Board_0,pBuff_0,CirHandle,BIAVAILABLE);

                        // Get Cleanup status
                        BiControlStatusGet(Board_0,pBuff_0,
                            &Start,&Stop,&Abort,&Pause,&Cleanup);

                    } // End if Error == BI_OK
                    else { // Catch other possible messages
                        if     (Error == BI_CIR_ABORTED)
                            sprintf(myInfo,"Acquisition has been aborted\n");
                        else if(Error == BI_CIR_STOPPED)
                            sprintf(myInfo,"Acquisition has been stopped\n");
                        else if(Error == BI_ERROR_CIR_WAIT_TIMEOUT)
                            sprintf(myInfo,"BiSeqWaitDone has timed out\n");
                        else if(Error == BI_ERROR_CIR_WAIT_FAILED)
                            sprintf(myInfo,"wait in BiSeqWaitDone Failed\n");
                        else if(Error == BI_ERROR_QEMPTY)
                            sprintf(myInfo,"The queue was empty\n");

                        fprintf(stderr,myInfo);
                        fprintf(logfid,myInfo);

                        // In all of the above cases, re-initialize to 0
                        // the current avging buffer.
                        // Since the Cam0 thread does the reinitialization,
                        // do not make the Cam1 thread do it too.
                        pAvg = pAvgSpace;
                        for (ll=0;ll<impixavg;ll++) *pAvg++ = 0;

                        // Set iiN high to break out of the iiN loop.
                        iiN = NumIntegrations;
                        iiQ = 4;   // break out of the iiQ, quad loop

                    }
                }     // End of if !cleaned up
            }   // End of iiQ loop

