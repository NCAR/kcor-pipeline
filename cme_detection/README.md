## Installation

The following environment variables can be set to for the KCor pipeline environment.

KCOR_DIR
  - top of archive directory tree, individual files will be in $KCOR_DIR/YYYY/MM/DD

KCOR_HPR_DIR
  - directory to store images converted to HPR coordinates

KCOR_HPR_DIFF_DIR
  - directory to store running difference maps in HPR coordinates

Run the CME detection code with:

    IDL> kcor_cme_detection
