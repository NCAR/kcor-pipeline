#!/bin/env python

import sunpy_soar
from sunpy.net import Fido

from sunpy.net.attrs import Instrument, Level, Time
from sunpy_soar.attrs import Identifier

# Create search attributes
start_date = "2022-03-01"
end_date = "2022-06-01"
instrument = Instrument("EPD")
time = Time(start_date, end_date)
level = Level(2)

# Do search
result = Fido.search(instrument, time, level)
print(result)

# Download files
files = Fido.fetch(result)
print(f"{len(files)} files from {start_date} to {end_date}")
