import glob
import os

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


def quicklook(root, datetime):
    """Calculate simple averaged quicklook image from a file location and
    date/time.
    """
    frames, numsum = read_time(root, datetime)
    average_image = np.sum(frames.astype(np.float32), axis=0)
    return([corona(average_image[cam, :, :, :])
              for cam in np.arange(N_CAMERAS, dtype=np.int16)])


if __name__ == "__main__":
    root = "/hao/sunset/Data/KCor/raw.aero/20200908"
    datetime = "20200908_172438"
    q = quicklook(root, datetime)
    display_image(q[0])
    display_image(q[1])
