"""Test to see if K-Cor VSO connection works through SunPy.
"""

import astropy.units as u
from sunpy.net import Fido, attrs as a
from sunpy.map import Map


if __name__ == "__main__":
    time = a.Time("2017-08-18T00:00:00", "2017-08-22T00:00:00")
    kcor = a.Instrument("K-Cor")
    results = Fido.search(time, kcor)
    print(results)
