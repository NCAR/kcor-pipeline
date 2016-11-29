// writeAvg16.h   writes out 16-bit avg image data.
// Alice 20131112

    // create the 16-bit signed avg data from the 32-bit unsigned avg data.
    // Procedure:
    //     drop the lowest 16 bits by doing the bit shift >> 16
    //         This creates an unsigned 16-bit integer.
    //         To make the unsigned 16-bit be a signed 16-bit 
    //         and *not lose* any information,
    //     next we subtract 32768 (0x8000). (2^15)

  //pAv   = pAvgSpaceX;  done in WriteCoAvgDataToDisk_X (threadsforwriting.h)
  //pAv   = pAvgSpaceY;  done in WriteCoAvgDataToDisk_Y (threadsforwriting.h)
    pAv16 = pAvgSpace16;
    for(ll=0;ll<impixavg;ll++){
        *pAv16++ = (short)((*pAv++ >> 16) - 0x8000);
    }
    pAv16 = pAvgSpace16;


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
        if((imwrote=fwrite(pAv16, 1, hdsz ,afid)) != hdsz ) {
            fprintf(logfid,"Image write error:\n\
            Only wrote %d bytes to %s\nExpected %d", imwrote,afilenm,hdsz);
            fprintf(stderr,"Image write error:\n\
            Only wrote %d bytes to %s\nExpected %d", imwrote,afilenm,hdsz);
            fclose(afid);
        }
        if((imwrote=fwrite(pAv16, 1, avgimsz16 ,afid)) != avgimsz16 ) {
            fprintf(logfid,"Image write error:\n\
            Only wrote %d bytes to %s\nExpected %d", imwrote,afilenm,avgimsz16);
            fprintf(stderr,"Image write error:\n\
            Only wrote %d bytes to %s\nExpected %d", imwrote,afilenm,avgimsz16);
            fclose(afid);
        }
        fclose(afid);
    }
