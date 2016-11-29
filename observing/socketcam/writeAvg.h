// writeAvg.h   writes out avg image data.
// Alice 20120206


    // Set up the directory name based on localtime timestamp
    sprintf(mydir,"e:/%4d%02d%02d",
        lTS->tm_year+1900,lTS->tm_mon+1,lTS->tm_mday);

    // Check if the directory exists, if not, make it.
    NotYet = CreateDirectory((char *)mydir,NULL);

    // Fully determine the directory
    sprintf(mydir,"%s/avg/",mydir);

    // Check if that directory exists, if not, make it.
    NotYet = CreateDirectory((char *)mydir,NULL);

    // Fully determine the filename based on UTC
    sprintf(sfilenm,"%4d%02d%02d_%02d%02d%02d_kcor.bin",
                     aTS->tm_year+1900,aTS->tm_mon+1,aTS->tm_mday,
                     aTS->tm_hour,aTS->tm_min,aTS->tm_sec);
    sprintf(afilenm,"%s%s",mydir,sfilenm);

  //fprintf(stderr,"%s\n",afilenm);
    if ( ( afid = fopen(afilenm,"wb") ) == NULL ) {
        fprintf(logfid,"Error opening %s for writing.\n",afilenm);
        fprintf(stderr,"Error opening %s for writing.\n",afilenm);
    }
    else {
        // Write 2880*2 empty bytes at the beginning of the file
        // to accommodate the fits header.
        if((imwrote=fwrite(pAv, 1, hdsz ,afid)) != hdsz ) {
            fprintf(logfid,"Image write error:\n\
            Only wrote %d bytes to %s\nExpected %d", imwrote,afilenm,hdsz);
            fprintf(stderr,"Image write error:\n\
            Only wrote %d bytes to %s\nExpected %d", imwrote,afilenm,hdsz);
            fclose(afid);
        }
        if((imwrote=fwrite(pAv, 1, avgimsz32 ,afid)) != avgimsz32 ) {
            fprintf(logfid,"Image write error:\n\
            Only wrote %d bytes to %s\nExpected %d", imwrote,afilenm,avgimsz32);
            fprintf(stderr,"Image write error:\n\
            Only wrote %d bytes to %s\nExpected %d", imwrote,afilenm,avgimsz32);
            fclose(afid);
        }
        fclose(afid);
    }
