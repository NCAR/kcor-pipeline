    // writestrm0.h   writes out either raw avging or strm image data.
    //
    // Alice 20120103

    sprintf(filenm,"%scam0_%04d.raw",mydir,imgNo);
  //fprintf(stderr,"%s\n",filenm);
    if ( ( fid = fopen(filenm,"wb") ) == NULL ) {
        fprintf(logfid,"Error opening %s for writing.\n",filenm);
        fprintf(stderr,"Error opening %s for writing.\n",filenm);
    }
    else {
        if((imwrote=fwrite(Abuf, 1, imsz16 ,fid)) != imsz16 ) {
            fprintf(logfid,"Image write error:\n\
            Only wrote %d bytes to %s\nExpected %d", imwrote,filenm,imsz16);
            fprintf(stderr,"Image write error:\n\
            Only wrote %d bytes to %s\nExpected %d", imwrote,filenm,imsz16);
            fclose(fid);
        }
        fclose(fid);
    }
