Kinpira by System Verilog
==================================================

This is the ported version of "Kinpira" project.

Kinpira consists of three major modules: gobou, renkon, ninjin.
Gobou is a coprocessor for computing fully-connected layer.
Renkon is a coprocessor for computing 2D-convolution layer.
Ninjin is a interface with AXI4 protocol for connecting to other systems.

TODOs
==================================================

* Gobou
  - Bypass relu module for last layer.
    + usually with identity or softmax
  - Use another mechanism for caching weights.
    + we have just a little BRAM today

* Renkon
  - Implement the padding option for conv module.
  - Implement the universal filter-size conv module.
    + with 1 MAC for each module
  - Bypass pool module.
  - Implement the stride option for pool module.
  - Implement the universal filter-size pool module.

* Ninjin
  - Use DRAM for image memory with Central-DMA.
  - Use memory-mapped AXI4.

* Other parts
  - Synthesis API with simple syntax like major DL frameworks.
  - simple module definition DSL.

