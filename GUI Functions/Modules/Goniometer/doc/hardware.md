# Hardware description
## List of used hardware

  * Astrosyn [MY4001 - Stepper Motor:][1] 11Ncm max. torque; 24mm shaft length
  * Tinkerforge [Stepper Brick][2]
  * Tinkerforge [I04 Bricklet][3]
  * Used 12V laptop power supply

## Technical drawings for holder
  The holder was machined from aluminium in the student workshop of the Claredon
Laboratory at the University of Oxford. It was designed to fit to the tables of
a variety of Bruker spectrometers (ElexSys 560/580/680 were tested).

  Sliding parts (a 10x10mm cross section bar and a 10mm diameter rod) are made of
stainless steel in order to control abrasion and cut to the right length. 

  The blueprints can be found in ./img/blueprint.pdf and in an editable .dxf format
(created by qcad/libdxf) in the same directory. A picture of the mounted set-up is
available in this directory too. 

  The motor connects to the sample rod using two gears, on (lower number of teeth)
is mounted to the motors shaft (5mm diameter), the other is mounted to the sample 
rod (8mm diameter). Both are fixed using grub screws. This way, the gear ratio
helps achieve a higher torque (advantageous because you can tighten the O-ring
further) and higher precision. The gear ratio used in the set-up is 3 (75 to
25 teeth) which is also the default in the driver program and turned out to be a
reasonable choice. Mind that the sum of the gear radii needs to be bigger than 
(17.65+4)mm=21.65mm in order to clear the motor block and the holder.
  As mentioned above, the O-ring that provides the vacuum seal to the cryostat 
needs to be slightly loosened. The sample rod might slide in further by doing and
the sample rod gear will rest on the aluminium part which was never a problem.
It turned out, however, that with the described configuration one can tighten it
almost as hard as 'normally'. Still the motor can turn the rod and precision does
not suffer.


[1]: http://uk.farnell.com/astrosyn/my4001/stepper-motor-14-34-mm/dp/8425884
[2]: http://www.tinkerforge.com/doc/Hardware/Bricks/Stepper_Brick.html
[3]: http://www.tinkerforge.com/doc/Hardware/Bricklets/IO4.html