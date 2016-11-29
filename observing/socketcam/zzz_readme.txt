
This code "socketcam" runs the k-coronagraph camera
control code.

It can run the "stream to disk Program"
and the normal observing "averaging Program"

This code can be tested with "socketlbv",
which is the labview simulator.

"socketcam" expects to receive commands via sockets.
Commands are:
    stream start
    stream stop
    avging start 512 0 0
    avging stop

To kill the program gracefully, type:
    quit
into its stderr window.

--Alice 2011-12-29
