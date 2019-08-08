.PHONY: clean

stream.cpython-36m-x86_64-linux-gnu.so: stream.pyx
	cythonize -a -i stream.pyx

clean:
	rm -f stream.c stream.cpython-*.so stream.html
