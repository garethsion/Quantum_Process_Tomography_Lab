# Interfacing with a Bruker ELEXSYS spectrometer


## Connect goniometer

Connect the power supply to the black jack. Connect the stepper motor
with the colored 4-wire cable to the green jack. Connect the IO4 bricklet
with the black 10-wire cable to the bottom side of the brick. 
Connect the brick to the computer via USB.


## Angular dependend CW aquisition

To use the goniometer for a 2D CW experiment, it unfortunately can't be
triggered by the spectrometer but the spectrometer has to be triggered by
the goniometer. The reason is simply that Xepr can't send a pulse after
each of several aquisitions.


### Spectrometer side 

Set up a 2D CW experiment in Xepr. As 2nd axis use a suitable dummy variable
If you're not using ENDOR, use "RF (ENDOR)" as second axis which has proven
to work well.

In the parameter panel on the tab 'Signal Channel' -> 'Signal I/O' check 
'External Trigger'. On the tab '2: Radio Frequency' (resp. what ever you chose
as dummy variable) set the Number of point to the number of angular positions
you want to examine.

Make any other settings you need and click on play. The spectrometer now waits
for an external trigger to begin the first aquisition.


### Goniometer side/Laptop

To get the spectrometer triggered in CW mode locate the external trigger
input labeled EXT. TRIG on the panel labeled SIGNAL CHANNEL SCT/H. Connect
this port to the pin 1 (TRIG OUT) of the IO4 bricklet. 

Run goinometer with the -t, -w and -n option. 

  * -t (--trigger-mode) switches to sending triggers to the spectrometer
    instead of receiving them. 
  * -w specifies the time to wait between each trigger in seconds; choose
    this parameter to be slightly longer than your aquisition time (the
    spectrometer needs some seconds to get ready again)
  * -n specifies how many aquisitions the spectrometer is waiting for
  * use -a, -g, -s etc to specify the step width before each trigger

For example use

    goniometer.exe -t -w360 -n19 -a10 -g3


## Angular dependent pulsed EPR
Angular dependent pulsed EPR was not automated, the orientation was rather choosen by letting the stepper motor advance (a+[Enter]) or revert(A+[Enter]) a certain number of steps. For the data analysis, the produced log file can be used. The software should be extended at some point to allow changing the step width while the program is running. This way, the stepper motor is not powered down and looses position slightly (if its not at a full step) when restarting the program to change the step width.

In principle, angular studies can be automated using PulseSpel and an external trigger as described above or by triggering the motor from PulseSpel which is not possible for CW.  