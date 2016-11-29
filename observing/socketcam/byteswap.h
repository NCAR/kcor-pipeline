	//btyeswapping function for converting little endian binary to big endian.
    // This is necessary for Kcor due to image processing on an Intel machine 
    // with the need to read images on FITS viewers
    // Brandon Larson 4-24-2013


long byteswap(long i){
		unsigned char c1, c2, c3, c4;
		
			c1 = i & 255;
			c2 = (i >>8) & 255;
			c3 = (i >> 16) & 255;
			c4 = (i >> 24) & 255;
			
			return ((long)c1 << 24) + ((long)c2 << 16) + ((long)c3 <<8) + c4;
			}
