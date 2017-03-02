# KCor Pipeline

## Requirements

* IDL
* python 2.7+ (including 3.x) in order to run the simulators, the production pipeline does not require python
* MySql developer installation


## Installation

To build the KCor pipeline code, your system must have IDL, the MySQL client development package, and CMake 3.1.3 or later. Make sure these are installed on your system before continuing.

### Configuring your system

To configure the KCor pipeline for your system, do the following from the top-level of the pipeline source code (change the location of your IDL installation and the location where you want the pipeline to your needs):

    mkdir build
    cmake \
      -DCMAKE_INSTALL_PREFIX:PATH=~/software/kcor-pipeline \
      -DIDL_ROOT_DIR:PATH=/opt/share/idl8.5/idl85 \
    ..

There are example configuration scripts, `linux_configure.sh` and `mac_configure.sh`, in the pipeline source code.

### Build and install

Next, run:

    cd build
    make install


## Run the KCor pipeline


## Code for KCor pipeline

### Config file

The options of the pipeline are specified via a configuration file. See the example file `kcor.user.machine.flags.cfg` in the `config` directory of the distribution for all the options and their documentation. The filename of the config file must match the pattern given by the example, i.e., replace "user" with your username, "machine" with the name of the machine the pipeline will run on, and "flags" with a memorable name such as "production", "latest", or "geometry-fix".

All files with the `cfg` extension in the `config` directory will be copied into the installation during a `make install`.


### Run the simulator

To test the pipeline, use the `kcor_simulate` routine in the `bin` directory of the installation. For example,

    $ kcor-simulate 20161127 latest

to run the pipeline on the data from 20171127 using the config file with filename where flags is "latest".


## Directories

* bin: scripts
* config: configuration files
* gen: non-KCor-specific MLSO IDL routines used in the KCor pipeline
* lib: 3rd party IDL routines used in KCor pipeline
* observing: KCor-related observing code
* resources: data files such as color tables used in KCor pipeline
* src: KCor pipeline IDL code
* ssw: SSW IDL routines used in KCor pipeline
