©2013 Michael Bach, michael.bach@uni-freiburg.de, michaelbach.de


EP2013
======

The next big project -- stimulation and simultaneous data acquisition + display + averaging for recording visual evoked potentials. 
Successor to the highly successful EP2000 <http://michaelbach.de/ep2000/index.html>

 

To set up
---------
*	For easiest compilation, you need to set up a folder relation like so: /…/EP2013, and /…/objectiveC_Library. In the library folder you need
	* AbsoluteTimeUtils
	* Camera2
	* EDGInfoPanel
	* EDGSerial
	* NIDAQ
	* Oscilloscope2OGL
	* Oscilloscope3
	


Some details
------------
* "mach_absolute_time" is supposedly currently the most precise timer
* the test program allows to check long-time of many deltas