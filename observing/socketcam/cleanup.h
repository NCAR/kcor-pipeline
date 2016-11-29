// cleanup.h   cleans up, frees memory and closes the boards.
// Alice 20120103

    // cleanup after a Board0 or Board1 error
        BiCircCleanUp(Board0, pBuff0);
        BiCircCleanUp(Board1, pBuff1);
        BiBufferFree (Board0, pBuff0);
        BiBufferFree (Board1, pBuff1);
        BiBrdClose   (Board0);
        BiBrdClose   (Board1);
