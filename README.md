# recirculating-loop
This repository contains a set of MATLAB scripts,
needed to manage a recirculating loop based on
two acousto-optic modulators (AOM), controlled by two
SRS DG535 digital delay generators.

The [RecirculatingLoop.m](RecirculatingLoop.m) file contains
a very simple (but working) code to manage a simple recirculating loop,
written in object-oriented MATLAB.

[initialize_loop.m](initialize_loop.m) is an example program that
instances an RecirculatingLoop object to run a simple experiment.

## Other programs
This code also contain other programs that can be useful
to manage an optical recirculating loop experiment.

 * **Attenuator.m** is a Class that can be used to manage an
 Agilent N7764A Attenuator
 * **OSA.m** is a Class that can be used to manage an
 HP 86142A Optical Spectrum Analyzer
 * **set_amplifiers.m** and **set_launch_power.m** are scripts
 useful to manage Keopsys EDFA amplifiers.

## License
All the code is released under a [MIT License](LICENSE).
