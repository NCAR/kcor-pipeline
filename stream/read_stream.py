import glob
import os

import astropy.io.fits
import numpy as np
import matplotlib.pyplot as plt


N_CAMERAS = 2
N_STATES = 4
HEIGHT = 1024
WIDTH = 1024
N_IMAGES_PER_FILE = 2


def read_raw_stream(raw_filename):
    """Read raw stream data file.
    """
    with open(raw_filename) as raw_file:
        im = np.fromfile(raw_file, dtype=np.uint16)
        im = im.reshape(N_IMAGES_PER_FILE, N_STATES, HEIGHT, WIDTH)

    return(im)


def display_image(im, dpi=80):
    """Display an image with no axes at full resolution.
    """
    height, width = im.shape
    figsize = width / float(dpi), height / float(dpi)

    fig = plt.figure(figsize=figsize)
    ax = fig.add_axes([0, 0, 1, 1])
    ax.axis("off")
    ax.imshow(im, cmap="Greys_r", origin="lower")
    plt.show()


def read_time(root, datetime):
    """Read all the files corresponding to a date/time in a given directory, and
    place into an array with shape `(numsum, n_cameras, n_states, height, width)`.
    """
    # find files in root that begin with datetime by camera
    all_files = [glob.glob(os.path.join(root, f"{datetime}_kcor_cam{cam}_????.raw")) for cam in [0, 1]]
    numsum = len(all_files[0]) * N_IMAGES_PER_FILE
    # TODO: should check that len(all_files[i]) is the same for all i

    shape = (numsum, N_CAMERAS, N_STATES, HEIGHT, WIDTH)
    frames = np.empty(shape, dtype=np.uint16)

    for c, cam_files in enumerate(all_files):
        for i, f in enumerate(cam_files):
            frames[i * N_IMAGES_PER_FILE:(i + 1) * N_IMAGES_PER_FILE, c, :, :, :] \
              = read_raw_stream(f)

    return(frames, numsum)


def corona(im):
    """Calculate the corona from a `(n_states, height, width)` shaped float array.
    """
    return(np.sqrt((im[0, :, :] - im[3, :, :])**2 + (im[1, :, :] - im[2, :, :])**2))


def naive_sum(frames):
    """Naively sum the frames (no aerosol removal). `frames` is a `uint16` array
    of shape `numsum, N_CAMERAS, N_STATES, HEIGHT, WIDTH`.
    """
    return(np.sum(frames.astype(np.float32), axis=0))


def remove_aerosol(frames):
    """Remove aerosols from frames. `frames` is a `uint16` array of shape
    `numsum, N_CAMERAS, N_STATES, HEIGHT, WIDTH`.
    """
    frames_mean = np.median(frames, axis=0).astype(np.uint16)
    frames_median = np.median(frames, axis=0).astype(np.uint16)

    numsum = frames.shape[0]
    ss = 4.0 / 44.0 / np.sqrt(44.0)
    threshold = numsum * 0.90

    corrected = np.empty((N_CAMERAS, N_STATES, HEIGHT, WIDTH), dtype=np.uint16)

    for c in range(N_CAMERAS):
        for s in range(N_STATES):
            for h in range(HEIGHT):
                for w in range(WIDTH):
                    ind = np.where(np.abs(frames[:, c, s, h, w] - frames_median[c, s, h, w]) < ss * np.sqrt(frames_median[c, s, h, w]))
                    if ind[0].size > threshold:
                        corrected[c, s, h, w] = np.mean(frames[ind, c, s, h, w])
                    else:
                        corrected[c, s, h, w] = frames_mean[c, s, h, w]
    return(corrected)


def quicklook(stream_root, datetime):
    """Calculate simple averaged quicklook image from a file location and
    date/time.
    """
    frames, numsum = read_time(stream_root, datetime)
    #average_image = naive_sum(frames)
    average_image = remove_aerosol(frames)
    return([corona(average_image[cam, :, :, :])
              for cam in np.arange(N_CAMERAS, dtype=np.int16)])


if __name__ == "__main__":
    stream_root = "/hao/dawn/Data/KCor/stream.aero/20200908"
    raw_root = "/hao/dawn/Data/KCor/raw.aero/20200908"
    output_root = "/hao/dawn/Data/KCor/raw.aero-removed/20200908"

    #datetimes = ["20200908_172438"]
    #datetimes = ["20200908_172438", "20200908_172453"]
    all_raw_files = glob.glob(os.path.join(raw_root, "*_kcor.fts.gz"))
    datetimes =  [os.path.basename(f)[0:15] for f in all_raw_files]
    for dt in datetimes:
        print(f"Reading {dt}...")
        frames, numsum = read_time(stream_root, dt)

        print(f"Summing {dt}...")
        #average_image = (naive_sum(frames) / 2**5).astype(np.uint16)
        average_image = remove_aerosol(frames).astype(np.uint16)

        metadata_filename = glob.glob(os.path.join(raw_root, f"{dt}*.fts.gz"))[0]
        output_basename = os.path.basename(metadata_filename)
        output_filename = os.path.join(os.path.join(output_root, output_basename))

        print(f"Writing {dt}...")
        metadata_hdulist = astropy.io.fits.open(metadata_filename)
        metadata_hdulist[0].data = average_image
        metadata_hdulist.writeto(output_filename, output_verify="ignore") 
