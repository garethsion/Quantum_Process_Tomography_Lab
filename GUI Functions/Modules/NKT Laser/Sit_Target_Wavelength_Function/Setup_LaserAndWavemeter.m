L=L78Class();
L.connect
WS7 = WS7Class;
WS7.connect
L.child_mods{1} = WS7;
L.calibrate_Offset

wavelength = 1078.27;
%L.set_laser_wavelength_PID(wavelength)