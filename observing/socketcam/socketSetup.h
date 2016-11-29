// socketSetup.h   defines the socket variables and defines
//                 the socket (tcp/ip) read threads:
//                     ServerThread
//                     RecvSignalsThread
//                 and the socket write to Client function:
//                     SendSignals
// Alice 20120103


// Socket variables.
#define MY__BYTES    80
#define FOREVER      TRUE
int            IsConnected;
int            my_Clientlen;
SOCKET         ServerSocket;
SOCKET         ClientSocket;
unsigned short my_Port  ;
char           my_BufferOut[MY__BYTES];
char           my_BufferIn [MY__BYTES];
WSADATA        my_wsaData;
struct  sockaddr_in my_Server;
struct  sockaddr_in my_Client;
char    my_Name[80];
char    my_Cmd [80];
char    my_Res [80];

// Socket threads and functions.
void SendSignals      (char *myC) ;
void RecvSignalsThread(void *dummy);

void ServerThread     (void *dummy) {

    HANDLE  hRecvSignalsThread;
    DWORD   dwRecvSignalsThread;

    fprintf(logfid,"\t%s Starting ServerThread\n",my_Name );

    my_Clientlen = (int)sizeof(my_Client);

    if ( WSAStartup(0x101, &my_wsaData) ){
        fprintf(logfid,"\t%s Unable to initialize winsock library\n",my_Name);
        fprintf(stderr,"\t%s Unable to initialize winsock library\n",my_Name);
        return;
    }


    /* Create a socket. */
    ServerSocket = socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);
    if (ServerSocket == INVALID_SOCKET ) {
        fprintf(logfid,"\t%s Cannot create ServerSocket\n", my_Name);
        fprintf(stderr,"\t%s Cannot create ServerSocket\n", my_Name);
        WSACleanup();
        return;
    }
    fprintf(stderr,"\t%s ServerSocket = %d\n",my_Name, ServerSocket );
    fprintf(logfid,"\t%s ServerSocket = %d\n",my_Name, ServerSocket );

    /* Fill in the sockaddr_in structure. */
    my_Server.sin_family      = AF_INET;
    my_Server.sin_addr.s_addr = INADDR_ANY; /* wild card IP address */
    my_Server.sin_port        = htons(my_Port);


    /* bind links the socket with the sockaddr_in  */
    /* structure.  It connects the socket with     */
    /* the local address and a specified port.     */
    if ( bind(ServerSocket, (struct sockaddr *)&my_Server,
                                    (int)sizeof(my_Server)) == -1 )
    {
        fprintf(logfid,"\t%s Could not bind \n",my_Name );
        fprintf(stderr,"\t%s Could not bind \n",my_Name );
        closesocket( ServerSocket );
        WSACleanup();
        exit(-1);
    }


    while (KeepRunning == TRUE ) {

        fprintf(logfid,"\t%s listening for a client...\n",my_Name );
        fprintf(stderr,"\t%s listening for a client...\n",my_Name );
        if ( listen(ServerSocket, 1) == -1 ) {
            fprintf(logfid,"%s could not listen\n",my_Name );
            fprintf(stderr,"%s could not listen\n",my_Name );
            closesocket(ServerSocket);
            WSACleanup();
            break;
        }
        else {
            ClientSocket = accept(ServerSocket,
                                  (struct sockaddr *)&my_Client,
                                  &my_Clientlen);
            IsConnected = TRUE;
            fprintf(logfid,
                    "\t%s ClientSocket %d connected to %s \n",
                    my_Name,ClientSocket, inet_ntoa(my_Client.sin_addr));
            fprintf(stderr,
                    "\t%s ClientSocket %d connected to %s \n",
                    my_Name,ClientSocket, inet_ntoa(my_Client.sin_addr));

            //_beginthread( RecvSignalsThread, 0 , (void *)ClientSocket );
            // Create RecvSignalsThread
            hRecvSignalsThread = CreateThread
                            (BFNULL,0,(LPTHREAD_START_ROUTINE)RecvSignalsThread,
                             (void *)ClientSocket, 0, &dwRecvSignalsThread);
            if (hRecvSignalsThread == BFNULL) {
                // Cleanup and Shutdown
                fprintf(logfid,"Couldn't create RecvSignalsThread\n");
                fprintf(stderr,"Couldn't create RecvSignalsThread\n");
                return;
            }
            SetThreadPriority(hRecvSignalsThread, THREAD_PRIORITY_NORMAL);
        }
    }

    fprintf(logfid,"\t%s Exiting  ServerThread\n",my_Name );
    fprintf(stderr,"\t%s Exiting  ServerThread\n",my_Name );
}


void RecvSignalsThread(void *dummy) {

    int kk, kcmp;
    char my_Status[20];

    SOCKET RSocket = (SOCKET)(dummy);

    #ifdef DEBUG_DO_PRINT_STATEMENTS  // {
    fprintf(logfid,"\t%s Starting RecvSignalsThread %d\n",my_Name,KeepRunning );
    fprintf(stderr,"\t%s Starting RecvSignalsThread %d\n",my_Name,KeepRunning );
    #endif // DEBUG_DO_PRINT_STATEMENTS  }

    while (KeepRunning==TRUE) {
        // Insure at least 1 character is received.
        if (recv(RSocket,(char *)my_BufferIn ,MY__BYTES,0) < 1) {
            fprintf(logfid,"\t%s recv error\n",my_Name);
            fprintf(stderr,"\t%s recv error\n",my_Name);
            IsConnected  = FALSE;
            break;
        }
        #ifdef DEBUG_DO_PRINT_STATEMENTS  // {
        fprintf(logfid,"\t%s received \'%s\'\n",my_Name,my_BufferIn);
        fprintf(stderr,"\t%s received \'%s\'\n",my_Name,my_BufferIn);
        #endif // DEBUG_DO_PRINT_STATEMENTS  }

        sprintf(my_Res,"cam %s",my_BufferIn);
        SendSignals(my_Res);
        // parselogic intelligently parses the string.
        // It will default to a condition that will do nothing,
        // and safely stop.
        #include "parselogic.h"
    }
    fprintf(logfid,"\t%s RecvSignalsThread ending\n",my_Name);
    fprintf(stderr,"\t%s RecvSignalsThread ending\n",my_Name);
    closesocket(RSocket);
    RSocket = -1;
}


void SendSignals(char *myC) {

    SOCKET SSocket = ClientSocket;

    #ifdef DEBUG_DO_PRINT_STATEMENTS  // {
    #endif // DEBUG_DO_PRINT_STATEMENTS  }
    fprintf(stderr,"  %s sending  \'%s\'\n",my_Name,myC);
    fprintf(logfid,"  %s sending  \'%s\'\n",my_Name,myC);

    if(IsConnected == FALSE) {
      //fprintf(logfid,"\t%s *not* connected, can\'t send anything\n",my_Name);
      //fprintf(stderr,"\t%s *not* connected, can\'t send anything\n",my_Name);
        return;
    }

    if (SSocket != -1 ) {
        sprintf(my_BufferOut,"%s",myC);
        if (send(SSocket,(char *)my_BufferOut,MY__BYTES,0)
            != MY__BYTES) {
            fprintf(logfid,"\t%s send error\n",my_Name);
            fprintf(stderr,"\t%s send error\n",my_Name);
            closesocket(SSocket);
        }
        #ifdef DEBUG_DO_PRINT_STATEMENTS  // {
        fprintf(stderr,"\t%s sent        \'%s\'\n",my_Name,my_BufferOut);
        fprintf(logfid,"\t%s sent        \'%s\'\n",my_Name,my_BufferOut);
        #endif // DEBUG_DO_PRINT_STATEMENTS  }
    }
}
