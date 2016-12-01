# General information
This is a simple script that is intended to be used with the [tinkerforge][1]
[stepper brick][2] and the [IO4 bricklet][3].

  Purpose of the setup is to let a stepper motor advance a certain amount
of steps everytime a TTL pulse is registered at pin 0 of the IO4 bricklet.
In addition to that the current position is registered as No. of steps and
angle (using a specified gear ratio) that way one can set and return
to a "home" position.

  This (and some mechanical parts) form an automatic goinometer for an EPR-
spectrometer.


## Usage
Be sure to have installed and started brickd as described below. Connect the
brick/bricklet to a free USB port of the computer and start the programm by
running:

    ./goniometer [OPTIONS]

It will then listen for interrupts on the IO4 bricklets or key presses on
the computer. Available options are:

    -a,  --angle       Angle by wich motor advances on interrupt (default: 5)
    -g,  --gear-ratio  Gear ratio between motor and sample rod (default: 2)
    -s,  --steps-per-revolution Number of full-width steps needed for one revolution of the motor rod (default:200)
    -m,  --step-mode   Perform 1/n steps. Note 1/1 steps give the biggest torque. (n = (1,2,4,8); default: 1)
    -d,  --dynamic     Dynamic mode: --angle is ignored and instead TTL pulse length is used. 10ms = 0.1deg
    -r,  --no-record   Do not keep a logfile that records every angle
    -t,  --trigger     Trigger spectrometer instead of being triggered by it (for CW measurements)
    -w,  --sweep-time  Time spectrometer needs for field sweep and to ready for the next one (with -t)
    -n,  --n-aquisitions  Number of field sweeps/aquisitions (with -t)

For now the Brick/Bricklet UID needs to be specified in the C-code and thus
you need to recompile it for every new step.

### Usage example
Imagine the motor has a gear with 50 teeth fitted to its rod. This gear
meshes with a gear with 100 teeth at the sample rod of the spectrometer.
For this configuration the gear ratio is 2. The motor has to turn twice to
make the sample rod turn once thus increasing the delivered torque as well
as the precision.

  You use a motor with 200 steps per revolution (1.8° per step) and want to
operate with 1/8 steps which will cause the least vibration but will also
deliver only a small torque.

The motor shall advance by 5° after every TTL pulse. Note: This will not 
be possible with the 200 steps per revolution motor. Instead you will get
a 4.95deg step (with 1/8 steps) and 5.4 (with full steps). A better choice
would be e.g. a 9deg step size.

Connect the stepper per USB and to the spectrometer and run

    goniometer -g 2 -s 200 -a 5 -m 8


The length of the TTL pulse does not play a role in the above example. If
you want to specify the angle to advance after the TTL pulse use

    goniometer -g 2 -s 200 -m 8 -d

This activates the "dynamic mode" where the angle to advance by is given by 
(pulse length[ms])/100 [°]. So for again a 5 deg step the pulse needs to be
500ms long.


## Compilation and Prerequisites
The programm depends only on pthread on POSIX systems and Winsock2 on
Windows systems. Use of [MinGW][4] for compilation on windows is
recommended and the provided makefile will work for this environment and
unix like systems (including Mac OS/X) as long as gcc is installed. So executing 

    make

will compile and link the code and place the binary in the bin/ directory.
Precompiled binarys that work on Windows 7 Professional (64bit) can be found
in bin/.

For manual compilation see the excellent [tinkerforge API documentation][6].

The programm connects to the brick deamon. Its available for most common
operating systems. It needs to be downloaded and installed from the
[tinkerforge website's download section][5]. It will then run run as a
daemon in the background.

### Getting started with MinGW
The unexperienced MinGW user might find the following steps to set up and use
MinGW on Windows helpful:

  * Download the newest [installer for MinGW][7]
  * Execute the downloaded setup. Click yes, "I agree" and next until...
  * ... you can choose the components. Choose at least the C/C++ compiler
    and MSYS Basic System.  Finish the installer.
  * Launch the MinGW shell (You should find a shortcut in the start menu.)
  * Go to the folder where you downloaded the sourcecode to. Do this by
    typing `cd /C/User/.../goniometer`. Note that a normal slash
    ( ´/´ ) instead of a backslash ( ´\´ ) is used and that the drive C is
    denoted by ´/C/´ instead of ´C:\´. Hint: Hit TAB to autocomplete the
    folder.
  * Type `make` this will compile the code and put the binary in ./bin/
  * If you whish, you can execute the program right away from the
    commandline by typing ´bin/goniometer.exe`


## Link to docs
Further documentation can be found in the doc/ directory.


[1]: http://tinkerforge.com
[2]: http://www.tinkerforge.com/doc/Hardware/Bricks/Stepper_Brick.html
[3]: http://www.tinkerforge.com/doc/Hardware/Bricklets/IO4.html
[4]: http://mingw.org
[5]: http://www.tinkerforge.com/doc/Downloads.html
[6]: http://www.tinkerforge.com/doc/Software/API_Bindings.html#api-bindings-c
[7]: http://sourceforge.net/projects/mingw/files/Installer/mingw-get-inst/