// cameraSetup.h   defines the variables and threads for the cameras
//                 and camera boards.
// Alice 20120103

// Camera variables
BFU32  NumBuffers0=0, NumBuffers1=0;
Bd     Board0, Board1;
BIBA   Buff0,  Buff1;
BFU32  BufferQueueSize0;
BFU32  FramesCaptured0=0, FramesMissed0=0;
BFU32  FramesCaptured1=0, FramesMissed1=0;
PBFU32  *pBufferArray0, *pBufferArray1;

BFU32  BufferQueueSize1;
BFU32  *pNumBuffers0, *pNumBuffers1;
BIBA   *pBuff0,  *pBuff1;
BFU32  *pFramesCaptured0, *pFramesMissed0;
BFU32  *pFramesCaptured1, *pFramesMissed1;

BFU32  StartFrame   = 0; // Start tif write on frame 0
BFU32  WriteOptions = 0; // No write options

BFU32  FramesToWrite0;
BFU32  FramesToWrite1;

BIRC    Error;
BIRC    WaitReturn = 1;
BFU32   ErrorCheck = 1;
BFU32   ErrorMode  = CirErStop;

BFU32   CirSetupOptions = BiAqEngJ|NoResetOnError;

// Camera Thread variables
HANDLE   hErrThread0,    hAcqThread0;
DWORD   dwErrThreadId0, dwAcqThreadId0;
HANDLE   hErrThread1,    hAcqThread1;
DWORD   dwErrThreadId1, dwAcqThreadId1;


// Camera Thread function defines
UINT (*pProgramCam0   )(LPVOID lpdwParam) = NULL;
UINT (*pProgramCam1   )(LPVOID lpdwParam) = NULL;
UINT AvgingProgramCam0(LPVOID lpdwParam);
UINT AvgingProgramCam1(LPVOID lpdwParam);
UINT StreamProgramCam0(LPVOID lpdwParam);
UINT StreamProgramCam1(LPVOID lpdwParam);
UINT ErrorThread0     (LPVOID lpdwParam);
UINT ErrorThread1     (LPVOID lpdwParam);


HANDLE   hRestartThread;
DWORD   dwRestartThreadId;
void      RestartThread(LPVOID lpdwParam);
