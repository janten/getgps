getgps
======
Command line utility to read data from GPS Loggers such as PhotoMate 887 Lite in Mac OS X.

Usage
=====
Simply run `getgps` without any arguments to start the default operation. The application will
  1. Search for a device named `cu.usbmodem*` in `/dev/` and connect to the first device it finds
  2. Disable GPS logging on the device
  3. Download all available logs and save them to a file named `$date.gps`
  4. Format the device memory. Do *not* disconnect your device during this step, you may damage your GPS device. 
  5. Enable GPS logging
  6. Stay around until the device is disconnected.

You can also send custom commands to the device with `getgps command`, e.g. to configure your GPS logger.

Data Format
===========
The *.gps files created by getgps are basically just memory dumps of the GPS device's memory.
You can convert them to the popular GPX format with [gps2gpx](http://github.com/janten/gps2gpx).
