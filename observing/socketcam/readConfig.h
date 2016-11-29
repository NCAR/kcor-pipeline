// readConfig.h  reads in the kco Config file,
//               c:\\kco\\kcoconfig.ini
//               and then
//               reads in the luts from the files specified in the
//               Config file.
// Alice 20120103

int   fii, fjj;
FILE *infid, *lutfid;
char PathNFile [80];
char lutname   [80];
char ss        [80];
char *pc;

size_t  lutbsz;        // size in bytes
size_t  lutbread;
LUT_TYPE *plut;



// initialize all of the lut's to 1
plut = (LUT_TYPE *)&lut[0][0];
for(fjj=0;fjj<LUTSZ*8;fjj++) { *plut++ = 1; }


// assign pointers to the luts
plut0_0 = (LUT_TYPE *)&lut[0][0];
plut0_1 = (LUT_TYPE *)&lut[1][0];
plut0_2 = (LUT_TYPE *)&lut[2][0];
plut0_3 = (LUT_TYPE *)&lut[3][0];
plut1_0 = (LUT_TYPE *)&lut[4][0];
plut1_1 = (LUT_TYPE *)&lut[5][0];
plut1_2 = (LUT_TYPE *)&lut[6][0];
plut1_3 = (LUT_TYPE *)&lut[7][0];



lutbsz = LUTSZ * (size_t)sizeof(LUT_TYPE);

sprintf(PathNFile,"c:\\kcor\\kcoConfig.ini");

if ((infid = fopen(PathNFile,"r")) == NULL){
    fprintf(logfid,"\tCould not find \t %s",PathNFile);
    fprintf(stderr,"\tCould not find \t %s",PathNFile);
    fflush(logfid);
    return(1);
}


fjj=fscanf(infid,"%s",ss);
if (fjj!=1){
    fprintf(stderr,"\tCould not find any text in %s\n",PathNFile);
    fclose(infid);
    return(1);
}


// Look for the ascii string LUT_Names
while(strcmp(ss,"LUT_Names") != 0 ) {
    fjj=fscanf(infid,"%s",ss);
    if (fjj!=1){
        fprintf(logfid,"\tCould not find LUT_Names\n"); fflush(logfid);
        fprintf(stderr,"\tCould not find LUT_Names\n");
        fclose(infid);
        return(1);
    }
}

// need to grab the newline
pc=(char *)&lutname[0];
fscanf(infid,"%c",pc);

for (fii=0;fii<8;fii++) {
    pc=(char *)&lutname[0];
    fscanf(infid,"%c",pc);
    while(*pc != '\n') { pc++; fscanf(infid,"%c",pc);}
    *pc = '\0';
    fprintf(stderr,"readConfig %d found \'%s\'\n",fii,lutname);
    fprintf(logfid,"readConfig %d found \'%s\'\n",fii,lutname);

    if ( ( lutfid = fopen(lutname,"rb") ) == NULL ) {
        fprintf(stderr,"Error opening %s for reading.\n",lutname);
    }
    else {
        if((lutbread=fread(&lut[fii][0], 1, lutbsz ,lutfid)) != lutbsz ) {
            fprintf(stderr,"Image read error:\n\
            Only read %d bytes to %s\nExpected %d", lutbread,lutname,lutbsz);
            fclose(lutfid);
        }
        fclose(lutfid);
    }
}
fclose(infid);
