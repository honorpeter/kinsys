Overview of Kinpira
==================================================

Kinpira is the hardware accelerator, or platform for neural networks.
This project aims for the flexibility and the performance
for various network structures.


Overall architecture
----------------------------------------

Kinpira's overall architecture is summarized in Figure 1.
The hardware consists of three major modules: gobou, renkon, ninjin.
Gobou is a coprocessor for computing fully-connected layer.
Renkon is a coprocessor for computing 2D-convolution layer.
Ninjin is a interface with AXI4 protocol for connecting to other systems.
Each module interacts with the image memory to fetch input images and to
emit output results.

To use kinpira from external processors,
users first have to send parameters of the network.
In current implementation, network parameters are saved in
distributed memories or registers in each module.
The distributing scheme is formulated and implemented in the library.
Operations for Gobou and Renkon are issued from Ninjin by req signal
accompanying network hyper-parameters (number of units, filter size, etc...),
and then ack signal comes back if the operation get finished.

.. figure:: figure/kinpira.svg
  :width: 50%
  :align: center

  Figure 1: Overview of Kinpira architecture


Directory Tree
----------------------------------------

This project contains several subdirectories for each independent parts.
The contents of each directory is summarized as below:

* data

  - Contains various type of data.

  - Target data is not commited on the repository on default,
    use generation codes for data generation.

* doc

  - Contains documentations for the project.

* rtl

  - Contains main rtl modules for the hardware accelerator.

  - Mainly written by SystemVerilog 2012

  - Divided into several subproject by the major functionality.

    + gobou

    + renkon

    + ninjin

    + common

* sim

  - Contains simulation sources for emulating rtl modules.

  - Mainly written by C++ 14

* syn

  - Contains scripts for synthesizing the design using Design Compiler.

  - TODO: Performance could be evaluated using tcl scripts for PrimeTime.

* (icc)

  - TODO: Contains scripts for routing and placing netlists from the design
    using IC Compiler.

* tests

  - Contains testbench modules for each module in ``rtl``.

  - Mainly written by SystemVerilog 2012

* utils

  - Contains auxiliary scripts for design assistance

    + Random test-pattern generation script

    + tree-based module generation support script

    + TODO: weight serializer from DL frameworks

* vivado

  - Contains general scripts for synthesizing and implementing the design
    using Vivado.

* zedboard

  - Contains the implemented design or/and tcl scripts
    for Avnet ZedBoard using Vivado.

  - Not commited on the repository currently.

* zcu102

  - Contains the implemented design or/and tcl scripts
    for Xilinx Zynq UltraScale+ MPSoC ZCU102 using Vivado.

  - Not commited on the repository currently.


