#!/usr/bin/env python

import argparse
from collections import namedtuple
import configparser
import datetime
import glob
import os
import multiprocessing
import time
import warnings

import astropy.io.fits
from astropy.utils.exceptions import AstropyUserWarning
import numpy as np

import stream

N_STATES = 4
NX = 1024
NY = 1024

Task = namedtuple("Task", ["datetime", "stream_dir", "raw_dir", "output_dir"])


def read_raw(stream_dir, datetime, numsum, camera):
    """Read all the states for `numsum` images for camera `camera` at
    `datetime`.
    """
    states = np.empty((N_STATES, NX, NY, numsum), dtype=np.uint16)
    for n in range(numsum):
        for s in range(N_STATES):
            i = N_STATES * s + n
            raw_filename = os.path.join(stream_dir, f"{datetime}cam{camera}_{i:04d}.raw")
            with open(raw_filename, "r") as bf:
                states[s, :, :, n] = np.fromfile(bf, dtype=np.uint16).reshape(1024, 1024)
    return states


def remove_aerosols(stream_dir, dt, numsum, camera):
    """Compute the aerosol filtered median for a given `datetime` and `camera`.
    """
    t0 = time.time()

    # states is N_STATES x NX x NY x numsum
    states = read_raw(stream_dir, dt, numsum, camera)

    t1 = time.time()

    states_mean = np.median(states, axis=3).astype(np.uint16)
    states_median = np.median(states, axis=3).astype(np.uint16)

    t2 = time.time()

    ss = 4.0 / 44.0 / np.sqrt(44.0)
    threshold = numsum * 0.90

    use_cython = False
    if use_cython:
        corrected = stream.filter(states, states_mean, states_median, threshold, ss)
    else:
        corrected = np.empty((4, 1024, 1024), dtype=np.uint16)
        for s in range(N_STATES):
            for i in range(NX):
                for j in range(NY):
                    ind = np.where(np.abs(states[s, i, j, :] - states_median[s, i, j]) < ss * np.sqrt(states_median[s, i, j]))
                    n = ind[0].size
                    if n > threshold:
                        corrected[s, i, j] = np.mean(states[s, i, j, ind])
                    else:
                        corrected[s, i, j] = states_mean[s, i, j]

    t3 = time.time()

    delta1 = datetime.timedelta(seconds=t1 - t0)
    print(f"reading time {camera} : {delta1}")
    delta2 = datetime.timedelta(seconds=t2 - t1)
    print(f"median time {camera}  : {delta2}")
    delta2 = datetime.timedelta(seconds=t3 - t2)
    print(f"proc time {camera}    : {delta2}")

    return corrected


def write_corrected(output_dir, dt, header, cam_0, cam_1):
    """Combine the header with the cam_0 and cam_1 arrays.
    """
    data = np.stack([cam_0, cam_1], axis=0)
    output_filename = os.path.join(output_dir, f"{dt}_kcor_median.fts")

    primary_hdu = astropy.io.fits.PrimaryHDU(data)
    primary_hdu.header = header
    with warnings.catch_warnings():
        warnings.simplefilter('ignore', AstropyUserWarning)
        primary_hdu.writeto(output_filename, output_verify="ignore", overwrite=True)


def process_time(task):
    """Combine the mean FITS file matching `task.datetime` in `task.raw_dir` and
    the binary files matching `task.datetime` in `task.streamdir` into a median
    FITS file in `task.output_dir`.
    """
    # get original mean header and extract NUMSUM
    raw_filename = os.path.join(task.raw_dir, f"{task.datetime}_kcor.fts.gz")
    with astropy.io.fits.open(raw_filename) as f:
        header = f[0].header

    numsum = header['NUMSUM']

    # create a separate clean image for each camera
    cam_0 = remove_aerosols(task.stream_dir, task.datetime, numsum, 0)
    cam_1 = remove_aerosols(task.stream_dir, task.datetime, numsum, 1)

    # combine median 0 and 1 with the original header (making sure to modify
    # for NUMSUM) and write to task.output_dir
    write_corrected(task.output_dir, task.datetime, header, cam_0, cam_1)


def process_stream(date, stream_dir, raw_dir, output_dir, n_cores):
    """Finds all the standard mean FITS files, creates a pool of size `n_cores`,
    and sends the work to create the median FITS files to the pool.
    """
    print(f"date           : {date}")
    print(f"stream dir     : {stream_dir}")
    print(f"raw dir        : {raw_dir}")
    print(f"output dir     : {output_dir}")
    print(f"# of cores     : {n_cores}")

    raw_filenames = glob.glob(os.path.join(raw_dir, "*_kcor.fts.gz"))
    print(f"# of raw files : {len(raw_filenames)}")

    tasks = [Task(os.path.basename(f)[0:15], stream_dir, raw_dir, output_dir)
             for f in raw_filenames]

    with multiprocessing.Pool(n_cores) as pool:
        pool.map(process_time, tasks)


def main():
    parser = argparse.ArgumentParser(description="KCor stream parser")

    flags_help = """FLAGS section of the config filename, i.e., file in config/
                    directory matching kcor.FLAGS.cfg"""
    parser.add_argument("-f", "--flags", type=str, help=flags_help)
    parser.add_argument("-c", "--cores", type=int,
                        help="number of cores to use", default=1)
    parser.add_argument("date", type=str, help="date to run for")

    args = parser.parse_args()

    config_basename = f"kcor.{args.flags}.cfg"
    src_path = os.path.dirname(os.path.realpath(__file__))
    config_filename = os.path.join(src_path, "..", "config", config_basename)

    config = configparser.ConfigParser()
    config.read(config_filename)

    stream_basedir = config.get("stream", "basedir")
    raw_basedir = config.get("stream", "raw_basedir")
    output_basedir = config.get("stream", "output_basedir")

    stream_dir = os.path.join(stream_basedir, args.date)
    raw_dir = os.path.join(raw_basedir, args.date, "level0")
    output_dir = os.path.join(output_basedir, args.date)

    if not os.path.isdir(output_dir):
        os.makedirs(output_dir)

    t0 = time.time()
    process_stream(args.date, stream_dir, raw_dir, output_dir, args.cores)
    t1 = time.time()
    delta = datetime.timedelta(seconds=t1 - t0)
    print(f"elapsed time   : {delta}")


if __name__ == "__main__":
    main()
