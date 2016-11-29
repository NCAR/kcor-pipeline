/*
    socketcam runs the camera data acquisistion code for K-coronagraph.
    It communicates via sockets with the LabView code, which runs
    all the mechanical pieces parts, and tells socketcam what
    to do.

    socketcam runs both a "stream images to disk" mode,
    and the standard integration mode "avgeraging" mode of data collection.

    Commands to socketcam are very limited:
        stream start
        stream stop
        avging start  512  0  0
i.e
        avging start FramesToSumPerQuadState StartingQuadState DoAvgImageDump
        avging stop

    socketcam also accepts "quit", which will stop the program.

    The final "avging" images are actually a sum of all of the frames
    per quad state.   The sum is placed into a 32 unsigned HERE!!!


    Stream data is written to:
        e:/YYYYMMDD/hhmmssraw/YYYYMMDDhhmmsscam?_imgNo.raw

    Avging data is written to:
        e:/YYYYMMDD/avg/YYYYMMDDhhmmss.bin

    If AvgImageDump is set to TRUE, the individual images are written to:
        e:/YYYYMMDD/avg/YYYYMMDDhhmmsscam?_imgNo.raw

    Alice Lecinski 2012 01 05
*/
#include <stdio.h>
#include <ansi_c.h>
#include <winsock.h>

// For setting the stdio window properties.
#include <utility.h>

#define DEBUG_DO_PRINT_STATEMENTS
#undef  DEBUG_DO_PRINT_STATEMENTS

// If DoAvgImageDump==TRUE the last 1024 individual images
// taken during averaging will be dumped to disk.
// The images will only be written after receiving a "stop"
// The labview client can set this to TRUE (1) or FALSE (0)
// in the 'avging start' commands, i.e.
// avging start 512 0 1
int DoAvgImageDump=FALSE;


// If DO_LUT[01] are defined the lookuptable is applied
// to avging mode.
// LUT's are only applied to the avg images.
// LUT's are NOT applied to the raw images during avging.
// If DoAvgImageDump=TRUE, these raw images will be written to disk.
// Use those raw images to test LUT application.
#define DO_LUT0
#define DO_LUT1

// If DO_LUT[01]_STREAM are defined the lookuptable is applied
// to stream mode.
#undef  DO_LUT0_STREAM
#undef  DO_LUT1_STREAM

// Camera includes
#include "bitflow.h"
#include "BFIODef.h"
#include "BFIOApi.h"

//For ByteSwapping
//#include "byteswap.h"


/*
 Be sure to add these bitflow libraries to the project...
 /c/kcor/lib/bitflow/BFD.lib
 /c/kcor/lib/bitflow/BFDiskIO.lib
 /c/kcor/lib/bitflow/BFEr.lib
 /c/kcor/lib/bitflow/Bid.lib
 /c/kcor/lib/bitflow/Cid.lib

 And also add the socket library:
 /c/program files (x86)/national instruments/cvi2010/sdk/lib/msvc64/WSock32.Lib
*/

// These will capture and report and missed (lagged) images.
BFU32 BuffQSzX0, BuffQSzX1;
BFU32 BuffQSzY0, BuffQSzY1;

#include "cameraSetup.h" // Camera Board variables and threads.


int NotYet;
FILE *fid;
time_t  TimeStamp;    // For stream to disk
time_t  TimeStampX;   // For avgeraging into the X buffer
time_t  TimeStampY;   // For avgeraging into the Y buffer
struct tm *TS;
char mydir [120];
char filenm[120];
int writetif=0;  // If this is 1, tif images will be written to disk.
int writebin=1;
int imgNo;
long impix, impixlut, impixavg, xsz, ysz;
size_t imsz16, imsz32, avgimsz32, hdsz, imwrote;
size_t                 avgimsz16;
unsigned char *Abuf;

// Arguments to avging start
// avging start numI qI DoAvgImageDump
// avging start 512   0 0
int NumIntegrations;     // Number of Integrations per Quad state, or aka
                         // FramesToSumPerQuadState...
int qIndxStart;          // The initial modulator state at the first image.
                         // The labview client knows the correct value.

// Avging Buffers:
// There are two averaging buffers, X and Y
// X holds the first  group of 8 images from cam 0 *and* cam1
// Y holds the second group of 8 images from cam 0 *and* cam1
// These swap back and forth so that buffer X can accumulate images
// while buffer Y is written out, and then vise versa.
BFU32 *pAvgSpaceX;   // malloc'ed to hold 8 images.
BFU32 *pAvgSpaceY;   // malloc'ed to hold 8 images.

BFU32 *pAvgSpaceX1;  // Indexes for cam1 into the
BFU32 *pAvgSpaceY1;  // second halves of the above buffers.

short *pAvgSpace16;  // The 32-bit unsigned avg images will 
                     // have the lowest 16 bits stripped
                     // then 32768 subtracted to fit in a 16bit short.
                     // i.e.
                     // pAvg16 = short((pAvg >> 16) - 0xffff)



// Log file handle
FILE *logfid;


// Global parameter allowing the termination of all threads.
static int KeepRunning;
static int KeepRunningCam;

// Global parameters for handling which program is running.
#define P_UNKNOWN    (0)  // Same as CLOSED
#define P_CLOSED     (0)  // Same as UNKNOWN
#define P_OPENED     (1)
#define P_RUNNING    (2)
#define P_STOPPED    (3) // Stops avging and stream modes immediately.
#define P_GENTLESTOP (4) // Stops averaging at the end of an average.
                         // Stops stream mode immedaiately.
#define P_NONE       (0)
#define P_STREAM     (1)
#define P_AVGING     (2)
static int CamProgram              = P_NONE;
static int CamProgramStatus        = P_UNKNOWN;
static int CamProgramDesired       = P_NONE;
static int CamProgramDesiredStatus = P_UNKNOWN;



#include "socketSetup.h" // This sets up variables and threads.


// Set up the mutexes and semaphores for toggling from one
// accumulation buffer to the next.

#define USE_X (0)
#define USE_Y (1)
HANDLE hBufferX0ReadyEvent;
HANDLE hBufferX1ReadyEvent;
HANDLE hBufferXMutex;
HANDLE hBufferY0ReadyEvent;
HANDLE hBufferY1ReadyEvent;
HANDLE hBufferYMutex;

// These are the threads to write out the X and Y co-average buffers.
void WriteCoAvgDataToDisk_X (void *dummy);
void WriteCoAvgDataToDisk_Y (void *dummy);


// global LookUpTable arrays
#define LUTSZ  (4096)
#define USE_32BIT_LUT
#ifdef  USE_32BIT_LUT
    typedef BFU32          LUT_TYPE;
#else
    typedef unsigned short LUT_TYPE;
#endif
LUT_TYPE lut[8][LUTSZ];
LUT_TYPE *plut0_0, *plut0_1, *plut0_2, *plut0_3,
         *plut1_0, *plut1_1, *plut1_2, *plut1_3;


main()
{
    HANDLE   hServerThread;
    DWORD   dwServerThread;

    HANDLE  hWrtXThread,  hWrtYThread;
    DWORD  dwWrtXThread, dwWrtYThread;

    char    lognm   [512];
    time_t  mytime;
    struct  tm *MT;
    int     jj;

    #define USE_PRIMATIVE_WINDOW
    #ifdef  USE_PRIMATIVE_WINDOW
    Cls();
    SetStdioPort           (HOST_SYSTEM_STDIO);
    SetStdioWindowOptions  ( 1000, 0, 0); // nlines, update, show line numbers
    SetStdioWindowSize     ( 200, 800);
    SetStdioWindowPosition (100, 50);   //default position was (1170, 1720) we wanted it visible top left at (100,50)
    SetStdioWindowVisibility (1);
    #endif

    hBufferX0ReadyEvent = CreateEvent(NULL,FALSE,FALSE,NULL);
    hBufferX1ReadyEvent = CreateEvent(NULL,FALSE,FALSE,NULL);
    hBufferY0ReadyEvent = CreateEvent(NULL,FALSE,FALSE,NULL);
    hBufferY1ReadyEvent = CreateEvent(NULL,FALSE,FALSE,NULL);
    hBufferXMutex       = CreateMutex(NULL,FALSE,NULL);
    hBufferYMutex       = CreateMutex(NULL,FALSE,NULL);

    ServerSocket =    -1;
    ClientSocket =    -1;
    my_Port      =  9028;
    KeepRunning  =     1;
    KeepRunningCam =   TRUE;
    IsConnected  = FALSE;
    sprintf(my_Name,"socketcam");

    time ( &mytime ) ;
  //MT  = gmtime ( &mytime ) ;
    MT  = localtime ( &mytime ) ;  // Use local time for the log name.


    // Check if the log directory exists, if not, make it.
    NotYet = CreateDirectory("E:/socketcamLogs",NULL);

    sprintf(lognm,"E:/socketcamLogs/%04d%02d%02dlog.txt",
        MT->tm_year+1900,MT->tm_mon+1,MT->tm_mday);

    logfid = fopen((char *)lognm,"a+");
    fprintf(logfid,"\nsocketcam\tlocaltime is %s\n",asctime(MT));


    // read in the config file and read in the lut's
    #include "readConfig.h"

    xsz=ysz=1024;
    impix   = xsz*ysz;
    impixlut= impix/4;
    impixavg= impix*8;
    imsz16  = (size_t)impix*(size_t)2;
    imsz32  = (size_t)impix*(size_t)4;
    avgimsz32 = imsz32 * (size_t)8;
    avgimsz16 = imsz16 * (size_t)8;
    //To change FITS header prepend you need to change hdsz in 1440 multiples
    hdsz      = (size_t)2880 * (size_t)2;
    
    // There is no need to add the hdsz to the avgimsz 20131112 alice
  //avgimsz32 = avgimsz32 + hdsz;

    // Allocate space for the 16-bit Avg image.
    pAvgSpace16 = (short *) malloc(avgimsz16);

    // Allocate space for the AveragingBuffers
    pAvgSpaceX = (BFU32 *) malloc(avgimsz32);
    pAvgSpaceY = (BFU32 *) malloc(avgimsz32);

    // Set up the indices for cam1 to point half way
    // through the X and Y buffers, allows faster access.
    pAvgSpaceX1 = pAvgSpaceX + impix*4;
    pAvgSpaceY1 = pAvgSpaceY + impix*4;

    // zero the Avg buffers out.
    long  lii;
    BFU32 *pAX,  *pAY;
    pAX = pAvgSpaceX;
    pAY = pAvgSpaceY;
    for(lii=0;lii<impixavg;lii++) {
        *pAX++ = 0L;
        *pAY++ = 0L;
    }

    NumBuffers0 = 10;
    NumBuffers1 = 10;

    pNumBuffers0     = &NumBuffers0;
    pNumBuffers1     = &NumBuffers1;
    pBuff0           = &Buff0;
    pBuff1           = &Buff1;
    pFramesCaptured0 = &FramesCaptured0;
    pFramesMissed0   = &FramesMissed0;
    pFramesCaptured1 = &FramesCaptured1;
    pFramesMissed1   = &FramesMissed1;

    // zero out the counters of the QueueSize,
    // i.e. lagged or missed frames
    BuffQSzX0 = BuffQSzX1 = 0;
    BuffQSzY0 = BuffQSzY1 = 0;

    NumIntegrations=512; qIndxStart=0; DoAvgImageDump =FALSE;

    // Create ServerThread to allow clients to communicate with this code.
    hServerThread = CreateThread
                          (BFNULL,0,
                          (LPTHREAD_START_ROUTINE)ServerThread,
                          NULL, 0, &dwServerThread);
    if (hServerThread == BFNULL) {
        // Cleanup and Shutdown
        fprintf(stderr,"Couldn't create ServerThread\n");
        fprintf(logfid,"Couldn't create ServerThread\n"); fclose (logfid);
        return 1;
    }
    SetThreadPriority(hServerThread, THREAD_PRIORITY_NORMAL);

    // Create the avging write threads.
    #include "createwritethread.h"


    // variables for parselogic.h below
    int kk, kcmp;  char my_Status[MY__BYTES];


    // Load the avging program.
    // It will be loaded, but won't start until an 'avging start'
    // is received.
    sprintf(my_BufferIn,"avging stop");
  //sprintf(my_BufferIn,"stream stop"); // for stream to disk testing
    #include "parselogic.h"

    // Look for commands from stdin
    while ( KeepRunning == TRUE ) {

        fprintf(stderr,"Enter a command (____ or quit): \n");

        fgets (my_Cmd, MY__BYTES, stdin);
        for(jj=0;jj<MY__BYTES-1;jj++) if(my_Cmd[jj]=='\n') my_Cmd[jj]='\0';

        #ifdef DEBUG_DO_PRINT_STATEMENTS  // {
        fprintf(stderr,"\t%s got %s\n",my_Name,my_Cmd);
        #endif // DEBUG_DO_PRINT_STATEMENTS }
        fprintf(logfid,"\t%s got %s\n",my_Name,my_Cmd);


        if     ( (jj = strncmp("quit",(const char *)my_Cmd,4)) == 0) {
            KeepRunning = FALSE;
        }
        else if( (jj = strncmp("exit",(const char *)my_Cmd,4)) == 0) {
            KeepRunning = FALSE;
        }
        else  {
            sprintf(my_BufferIn,"%s",my_Cmd);
            #include "parselogic.h"
        }
    }


    // Abort all the threads...
    KeepRunning = 0;

    // Signal/release mutexes and events (semaphores)
    SetEvent(hBufferX0ReadyEvent); SetEvent(hBufferX1ReadyEvent);
    SetEvent(hBufferY0ReadyEvent); SetEvent(hBufferY1ReadyEvent);
    ReleaseMutex(hBufferXMutex);   ReleaseMutex(hBufferYMutex);

    // Stop any currently running program
    if (CamProgram != P_NONE ) {
        // Send a stop...
        #include "brdstop.h"
        // Close the boards...
        #include "brdclse.h"
    }

    // Give them a few seconds to close...
    Sleep(3000);

    if (ClientSocket != -1 ) closesocket(ClientSocket);
    if (ServerSocket != -1 ) closesocket(ServerSocket);
    WSACleanup();

    // Close Mutexes and Events (semaphores)
    CloseHandle(hBufferX0ReadyEvent);
    CloseHandle(hBufferX1ReadyEvent);
    CloseHandle(hBufferY0ReadyEvent);
    CloseHandle(hBufferY1ReadyEvent);
    CloseHandle(hBufferXMutex);
    CloseHandle(hBufferYMutex);

    fprintf(stderr,"Sockets are closed.\n");
    fprintf(stderr,"All threads should be done.\n");
    fprintf(logfid,"Sockets are closed.\n");
    fprintf(logfid,"All threads should be done.\n"); fclose (logfid);


    return 0;
}


#include "threadsforstream.h"   // Streaming data acquisition.
#include "threadsforerrors.h"   // Camera board error handling.
#include "threadsforavging.h"   // Co-averaging data acquisition.
#include "threadsforwriting.h"  // Writes the X and Y co-average buffers.
