#!/bin/env python

"""
https://docs.sunpy.org/projects/sunkit-image/en/stable/generated/gallery/multiscale_gaussian_normalization.html
"""

import argparse
import warnings

import matplotlib.image
from sunpy.map import Map
from astropy import units as u
from astropy.io import fits
from astropy.utils.exceptions import AstropyUserWarning
import warnings
warnings.simplefilter("ignore", category=AstropyUserWarning)

import sunkit_image.enhance as enhance
import sunkit_image.radial as radial
from sunkit_image.utils import equally_spaced_bins


if __name__ == "__main__":
    name = "KCor filtering utility"
    parser = argparse.ArgumentParser(description=name)

    parser.add_argument("-f", "--filter", metavar="FILTER_NAME",
        help="filter name: MGN, NRGF, VNRGF", default="MGN")
    parser.add_argument("-o", "--output", help="Output filename",
        default="kcor-filtered.png")
    parser.add_argument("filename", help="KCor level 2 FITS filename")

    args = parser.parse_args()

    input_map = Map(args.filename)

    if args.filter.lower() == "mgn":
        filter_name = "Multi-scale Gaussian Normalization filter"
        filtered_data = enhance.mgn(input_map.data)
    elif args.filter.lower() == "nrgf":
        filter_name = "Normalizing Radial Graded Filter (NRGF)"
        radial_bin_edges = equally_spaced_bins()
        radial_bin_edges *= u.R_sun
        filtered_map = radial.nrgf(input_map, radial_bin_edges)
        filtered_data = filtered_map.data
    elif args.filter.lower() == "fnrgf":
        filter_name = "Fourier Normalizing Radial Graded Filter"
        radial_bin_edges = equally_spaced_bins()
        radial_bin_edges *= u.R_sun
        order = 20
        attenuation_coefficients = radial.set_attenuation_coefficients(order)
        filtered_map = radial.fnrgf(input_map, radial_bin_edges, order, attenuation_coefficients)
        filtered_data = filtered_map.data
    else:
        parser.error(f"unknown filter \"{args.filter}\"")

    print(f"{filter_name} -> min: {filtered_data.min():0.3f} max: {filtered_data.max():0.3f}")
    matplotlib.image.imsave(args.output, filtered_data, origin="lower", cmap="Greys_r")
