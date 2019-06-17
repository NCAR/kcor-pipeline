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

import matplotlib.pyplot as plt
import numpy as np


# location of raw data
RAW_DIR = "/hao/sunrise/Data/KCor/raw/2018/20181203/stream_data/184832raw"

do_display = False

#tic

#cd, '/hao/sunrise/Data/KCor/raw/2018/20181203/stream_data/184832raw'

clist = 'imlist'

nx       = 1024
ny       = 1024
n_frames = 495  

states   = np.zeros((nx, ny, n_frames, 4), dtype=np.float32)

avgall   = np.zeros((nx, ny), dtype=np.float64)

with open(os.path.join(RAW_DIR, clist), "r") as f:
    filenames = [line.rstrip() for line in f.readlines()]

n_states = 4
for f in range(n_frames):
    for s in range(n_states):
        with open(os.path.join(RAW_DIR, filenames[n_states * f + s]), "r") as bf:
            im = np.fromfile(bf, dtype=np.int16).reshape((nx, ny))
        states[:, :, f, s] = im.astype(np.float32)

singleimg = np.sqrt((states[:, :, :, 0] - states[:, :, :, 3]) ** 2
                        + (states[:, :, :, 1] - states[:, :, :, 2]) ** 2)

#print, toc(), format='(%"file IO: %0.1f sec")'


#tic

state00a = np.mean(states[:, :, :, 0], axis=2)
state11a = np.mean(states[:, :, :, 1], axis=2)
state22a = np.mean(states[:, :, :, 2], axis=2)
state33a = np.mean(states[:, :, :, 3], axis=2)

state00 = np.median(states[:, :, :, 0], axis=2)
state11 = np.median(states[:, :, :, 1], axis=2)
state22 = np.median(states[:, :, :, 2], axis=2)
state33 = np.median(states[:, :, :, 3], axis=2)


#print, toc(), format='(%"mean/medians: %0.1f sec")'


if do_display:
    size = 8
    cmap = "Greys"
    #cmap = "viridis"
    d_min = 0.0
    d_max = 5.0
    d_exp = 0.5
    
    f, (ax1, ax2) = plt.subplots(1, 2, figsize=(2*size, size))
    
    corona_mean = np.sqrt((state00a - state33a)**2 + (state22a - state11a)**2)
    ax1.imshow(corona_mean**d_exp, vmin=d_min, vmax=d_max, cmap=cmap, origin="lower")
    ax1.set_title("mean")
    
    corona_median = np.sqrt((state00 - state33)**2 + (state22 - state11)**2)
    ax2.imshow(corona_median**d_exp, vmin=d_min, vmax=d_max, cmap=cmap, origin="lower")
    ax2.set_title("median")


#dark =readfits('/hao/mlsodata1/Data/KCor/raw/20181204/level0/20181204_192310_kcor.fts.gz',hdr)
#dark =float(dark)
#dark= (reform(dark(*,*,0,0))+ reform(dark(*,*,1,0))+reform(dark(*,*,2,0))+ reform(dark(*,*,3,0)))*.250

#image= readfits('/hao/mlsodata1/Data/KCor/raw/20181203/level0/20181203_175353_kcor.fts.gz', hdu1)
#image=float(image)
#image=reform(image(*,*,0,0))

#image_dark = image-dark

#image_ave = state00a*16.
#image_ave_dark = image_ave -dark*490./512.

#window, 2, retain=2
#!p.multi=[0,1,2]
#plot, image(50:150, 512), psym=10
#oplot, image_ave(50:150, 512), psym=10, color=90

#plot, image_dark(50:150, 512), psym=10
#plot, image_ave_dark(50:150, 512), psym=10


#stop

# use median value to find signa 
# select pixels inside sigma 

#tic

newstates = np.zeros((nx, ny, 4), dtype=np.float32)

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

thr = n_frames * 0.90

for j in range(nx):
    for i in range(ny):
        for s in range(n_states):
            indices = np.where(np.abs(states[i, j, :, s] - state00[i, j]) < ss * np.sqrt(state00[i, j] * 44.0))
            if len(indices) > thr:
                newstates[i, j, s] = np.mean(states[i, j, indices, s])
            else:
                newstates[i, j, s] = state00a[i, j]


#print, toc(), format='(%"main processing: %0.1f sec")'


#need to add logic to retain CMEs
#if pick# has more than 4 consecutive indices do not through those indices away
#assume assume an aersols is visible in less than 5 frames

if do_display:
    size = 8
    cmap = "Greys"
    #cmap = "viridis"
    
    f, (ax1, ax2) = plt.subplots(1, 2, figsize=(2*size, size))
    
    corona_mean = np.sqrt((state00a - state33a)**2 + (state22a - state11a)**2)
    ax1.imshow(corona_mean**d_exp, vmin=d_min, vmax=d_max, cmap=cmap, origin="lower")
    ax1.set_title("mean")
    
    corona_new  = np.sqrt((newstates[:, :, 0] - newstates[:, :, 3])**2 + (newstates[:, :, 2] - newstates[:, :, 1])**2)
    ax2.imshow(corona_new**d_exp, vmin=d_min, vmax=d_max, cmap=cmap, origin="lower")
    ax2.set_title("new")

#print, 'all done' 

#FOR DEBUG
#display pixels where outliers where not eliminated:
#this includes the inner annulus around the occulter and a few very
#noisy pixels

#test = fltarr(nx, ny)
#pixel_unchanged = where(mask00 lt thr or mask11 lt thr or mask22 lt thr or mask33 lt thr)
#test[pixel_unchanged] = 1
#tvscl, test

