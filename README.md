Kinpira by System Verilog
==================================================

This is the ported version of "Kinpira" project.

Kinpira consists of three major modules: gobou, renkon, ninjin.
Gobou is a coprocessor for computing fully-connected layer.
Renkon is a coprocessor for computing 2D-convolution layer.
Ninjin is a interface with AXI4 protocol for connecting to other systems.

Requirements
==================================================

Kinsys is tested on Debian 8.7 and CentOS 6.8.
Each modules and scripts are run using the tools listed below.

* Modelsim >= 10.4c
* Vivado >= 2016.4
* Design Compiler >= L-2016.03-SP4
* gcc >= 4.9.2
* ruby >= 2.3.1

Documentation
==================================================

We have documentations in `doc` directory.
Documentations are written using Sphinx,
so you can build the HTML version of documentations by running:
```
cd doc
make html
```
or by running similar commands for other format
(you can confirm which formats are available by running `make`).

TODOs
==================================================

* Gobou (1D-Coprocessor)
  - Bypass relu module for last layer.
    + usually with identity or softmax
  - Use another mechanism for caching weights.
    + we have just a little BRAM today

* Renkon (2D-Coprocessor)
  - Implement the padding option for conv module.
  - Implement the universal filter-size conv module.
    + with 1 MAC for each module
  - Bypass pool module.
  - Implement the stride option for pool module.
  - Implement the universal filter-size pool module.

* Ninjin (AXI4-Interface)
  - Use DRAM for image memory with Central-DMA.
  - Use memory-mapped AXI4.

* Other parts
  - Provide sufficient documents
    + include in-code comments
  - Synthesis API with simple syntax like major DL frameworks.
    + simple module / pe definition DSL.
    + like MapReduce
  - Integrate DL frameworks
    + weight dumping script (utils/kinpira.py (dump))
    + define API for synthesizable layers

License
==================================================

MIT License (see `LICENSE` file).
