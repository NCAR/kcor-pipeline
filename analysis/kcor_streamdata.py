# This is a very quick program to look through the kcor raw binary
# stream images.
#
# Edit this code for your special case.
# orginal code to read binary data from 
# Alice Lecinski 2012 Jan 25
#
# Modified: Burkepile

# added code to eliminate outliers

import os.path
import time

import matplotlib.pyplot as plt
import numpy as np
#import dask.array as da


# location of raw data
RAW_DIR = "/hao/sunrise/Data/KCor/raw/2018/20181203/stream_data/184832raw"

do_display = False


if __name__ == "__main__":
    t0 = time.time()
    clist = 'imlist'

    nx       = 1024
    ny       = 1024
    n_frames = 495  

    states   = np.zeros((nx, ny, n_frames, 4), dtype=np.float32)

    with open(os.path.join(RAW_DIR, clist), "r") as f:
        filenames = [line.rstrip() for line in f.readlines()]

    n_states = 4
    for f in range(n_frames):
        for s in range(n_states):
            with open(os.path.join(RAW_DIR, filenames[n_states * f + s]), "r") as bf:
                im = np.fromfile(bf, dtype=np.int16).reshape((nx, ny))
                states[:, :, f, s] = im.astype(np.float32)

    t1 = time.time()
    print(f"file IO: {t1 - t0:0.1f} sec")


    t0 = time.time()

    states_mean = np.mean(states, axis=2)
    states_median = np.median(states, axis=2)

    t1 = time.time()
    print(f"mean/medians: {t1 - t0:0.1f} sec")

    if do_display:
        size = 8
        cmap = "Greys"
        #cmap = "viridis"
        d_min = 0.0
        d_max = 5.0
        d_exp = 0.5
    
        f, (ax1, ax2) = plt.subplots(1, 2, figsize=(2*size, size))

        corona_mean = np.sqrt((states_mean[:, :, 0] - states_mean[:, :, 3])**2
                                  + (states_mean[:, :, 1] - states_mean[:, :, 2])**2)

        ax1.imshow(corona_mean**d_exp, vmin=d_min, vmax=d_max, cmap=cmap, origin="lower")
        ax1.set_title("mean")

        corona_mean = np.sqrt((states_mean[:, :, 0] - states_mean[:, :, 3])**2
                                  + (states_mean[:, :, 1] - states_mean[:, :, 2])**2)
        ax2.imshow(corona_median**d_exp, vmin=d_min, vmax=d_max, cmap=cmap, origin="lower")
        ax2.set_title("median")


    # use median value to find signa 
    # select pixels inside sigma 

    t0 = time.time()

    newstates = np.zeros((nx, ny, 4), dtype=np.float32)
    masks = np.zeros((nx, ny, 4), dtype=np.int32)

    # find the outliers 

    # this uses 4 sigma, 
    # 4sigma = 4./44., where 44e- is the camera gain per photon
    # this can be made larger or smaller 
    # 4 seems to be a reasonable number considering that some pixels are noisy

    ss = 4.0 / 44.0

    # if more than 10% of the frames are rejected, the code does not do anything,
    # i.e. makes an average over all frames
    # this may be too conservative for days with a lot of aerosols
    # I tried to use 5% and was not removing all aerosols
    # Hopefully we do not need to make the % of pixels rejected bigger or thr smaller 

    threshold = n_frames * 0.90

    for j in range(nx):
        for i in range(ny):
            for s in range(n_states):
                indices = np.where(np.abs(states[i, j, :, s] - states_median[i, j, s]) < ss * np.sqrt(states_median[i, j, s] * 44.0))
                n = indices[0].size
                if n > threshold:
                    newstates[i, j, s] = np.mean(states[i, j, indices, s])
                else:
                    newstates[i, j, s] = states_mean[i, j, s]
                masks[i, j, s] = n

    t1 = time.time()
    print(f"main processing: {t1 - t0:0.1f} sec")


    #need to add logic to retain CMEs
    #if pick# has more than 4 consecutive indices do not through those indices away
    #assume assume an aersols is visible in less than 5 frames

    if do_display:
        size = 8
        cmap = "Greys"
        #cmap = "viridis"
    
        f, (ax1, ax2) = plt.subplots(1, 2, figsize=(2*size, size))
    
        corona_mean = np.sqrt((states_mean[:, :, 0] - states_mean[:, :, 3])**2
                                  + (states_mean[:, :, 2] - states_mean[:, :, 1])**2)
        ax1.imshow(corona_mean**d_exp, vmin=d_min, vmax=d_max, cmap=cmap, origin="lower")
        ax1.set_title("mean")

        corona_new  = np.sqrt((newstates[:, :, 0] - newstates[:, :, 3])**2
                                  + (newstates[:, :, 2] - newstates[:, :, 1])**2)
        ax2.imshow(corona_new**d_exp, vmin=d_min, vmax=d_max, cmap=cmap, origin="lower")
        ax2.set_title("new")

#print, 'all done' 

    if do_display:
        size = 4
        cmap = "Greys"
        #cmap = "viridis"                                                                        
        f, axes = plt.subplots(1, 4, figsize=(4*size, size))
        for p, ax in enumerate(axes):
            ax.imshow(masks[:, :, p], cmap=cmap, origin="lower")
            ax.set_title(f"state={p}")
