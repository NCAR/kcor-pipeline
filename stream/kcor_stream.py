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


Task = namedtuple("Task", ["datetime", "stream_dir", "raw_dir", "output_dir"])


def aerosol_median(stream_dir, datetime, numsum, camera):
    # TODO: call C code to find separate median of files of the form
    # f"{task.datetime}_{n}_{cam}_kcor.fts" where n=0..numsnum for
    # cam=[0, 1]
    pass


def write_median(output_dir, datetime, header, median_0, median_1):
    """Combine the header with the median_0 and median_1 arrays.
    """
    data = np.stack([median_0, median_1], axis=0)
    output_filename = os.path.join(output_dir, f"{datetime}_kcor_median.fts")

    primary_hdu = astropy.io.fits.PrimaryHDU(data)
    primary_hdu.header = header
    with warnings.catch_warnings():
        warnings.simplefilter('ignore', AstropyUserWarning)
        primary_hdu.writeto(output_filename, output_verify="ignore")


def process_time(task):
    """Combine the mean FITS file matching `task.datetime` in `task.raw_dir` and
    the binary files matching `task.datetime` in `task.streamdir` into a median
    FITS file in `task.output_dir`.
    """
    # get original mean header and extract NUMSUM
    raw_filename = os.path.join(task.raw_dir, f"{task.datetime}_kcor.fts.gz")
    with astropy.io.fits.open(raw_filename) as f:
        header = f[0].header

        # TODO: temporary median solution
        median_0 = f[0].data[0, :, :, :]
        median_1 = f[0].data[1, :, :, :]

    numsum = header['NUMSUM']

    # create a separate clean image for each camera
    #median_0 = aerosol_median(task.stream_dir, task.datetime, numsum, 0)
    #median_1 = aerosol_median(task.stream_dir, task.datetime, numsum, 1)

    # combine median 0 and 1 with the original header (making sure to modify
    # for NUMSUM) and write to task.output_dir
    write_median(task.output_dir, task.datetime, header, median_0, median_1)


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
