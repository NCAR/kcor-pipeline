# KCor Pipeline

The COronal Solar Magnetism Observatory (COSMO) K-coronagraph (K-Cor) is one of three proposed instruments in the COSMO facility suite. It is specifically designed to study the formation and dynamics of coronal mass ejections and the evolution of the density structure of the low corona. The K-Cor records the polarization brightness (pB) formed by Thomson scattering of photospheric light by coronal free electrons. The National Center for Atmospheric Research (NCAR), via the National Science Foundation (NSF), provided full funding for the COSMO K-Cor, which was deployed to the Mauna Loa Solar Observatory (MLSO) in Hawaii in September 2013, replacing the aging MLSO Mk4 K-coronameter.

This pipeline produces level 1 and level 2 data products from the raw data from the instrument. The level 1 product contains polarization brightness (pB) images of the corona and sky, pB of the sky only, and total intensity, while the level 2 product contains pB images with sky polarization removed.

There is a near real-time component of the pipeline which produces fully calibrated level 2 pB images along with an end-of-day component which produces averages, differences, and many engineering products.


## Requirements

* IDL 8 or later
* cmake 3.1.3 or later
* MySQL developer installation
* Python 2.7+ (including 3.x) in order to run command line utility script including the simulators, the production pipeline does not strictly require Python


## Installation

To build the KCor pipeline code, your system must have IDL, the MySQL client development package, and CMake 3.1.3 or later. Make sure these are installed on your system before continuing.

These instructions will work on Linux and Mac systems. It should be possible to install the KCor pipeline on Windows systems, but it is not described here.

### Configuring for your system

To configure the KCor pipeline for your system, do the following from the top-level of the pipeline source code (change the location of your IDL installation and the location where you want the pipeline to your needs):

    cd kcor-pipeline
    mkdir build
    cmake \
      -DCMAKE_INSTALL_PREFIX:PATH=~/software/kcor-pipeline \
      -DIDL_ROOT_DIR:PATH=/opt/share/idl8.5/idl85 \
    ..

There are example configuration scripts, `linux_configure.sh` and `mac_configure.sh`, in the pipeline source code that are more detailed examples of the above configuration command.

### Build and install

Next, to build and install the KCor pipeline, run:

    cd build
    make install


## Run the KCor pipeline

### Config file

The options of the pipeline are specified via a configuration file. See the configuration specification file `kcor.spec.cfg` in the `config` directory of the distribution for all the options and their documentation. The filename of the config file must match the pattern `kcor.[NAME].cfg` with a name such as "production", "latest", or "geometry-fix". These configuration files must be placed in the `config/` directory.

All files with the `cfg` extension in the `config` directory will be copied into the installation during a `make install`.

### Process a day

For example, to process the data from 20220712 with the `kcor.latest.cfg` configuration file use the `kcor` utility script in the `bin/` directory of the installation:

    kcor process -f latest 20220712

Creating the configuration file, in this case `kcor.latest.cfg`, is the main work in running the pipeline.


## Code for KCor pipeline

### Directories

* *analysis* for routines to perform various analyses of KCor data
* *bin* for shell and Python scripts
* *cmake* for CMake modules
* *cme_detection* for code for the automated CME detection pipeline
* *config* for configuration files
* *gen* for non-KCor-specific MLSO IDL routines used in the KCor pipeline
* *hv* for helioviewer specific IDL code
* *lib* for 3rd party IDL routines used in KCor pipeline
* *observing* for KCor-related observing code
* *resources* for data files such as color tables used in KCor pipeline
* *scripts* for various scripts to be run on processed data
* *src* for KCor pipeline IDL code
* *ssw* for SSW IDL routines used in KCor pipeline
* *stream* for code to remove aerosols in real-time from stream data
* *unit* for unit tests
