import numpy as np
import matplotlib.pyplot as plt


N_STATES = 4
N_IMAGES_PER_FILE = 2


def read_raw(raw_filename):
    with open(raw_filename) as raw_file:
        im = np.fromfile(raw_file, dtype=np.uint16)
        im = im.reshape(N_STATES * N_IMAGES_PER_FILE, 1024, 1024)

    return(im)


def display_image(im, dpi=80):
    height, width = im.shape
    figsize = width / float(dpi), height / float(dpi)

    fig = plt.figure(figsize=figsize)
    ax = fig.add_axes([0, 0, 1, 1])
    ax.axis("off")
    ax.imshow(im, cmap="Greys_r", origin="lower")
    plt.show()
