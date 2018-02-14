Kinpira by System Verilog
==================================================

This is the ported version of "Kinpira" project.

Kinpira is the hardware accelerator, or platform for neural networks.
This project aims for the flexibility and the performance
for various network structures.

Requirements
==================================================

Kinsys is tested on Debian 8.7 and CentOS 6.8.
Each modules and scripts are run using the tools listed below.

* Modelsim >= 10.4c
* Vivado >= 2016.4
* Design Compiler >= L-2016.03-SP4
* clang >= 3.5.0
* ruby >= 2.3.1
* Python >= 3.6.0
* bash >= 4.3.30

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
  - Use another mechanism for caching weights.
    + we have just a little BRAM today

* Renkon (2D-Coprocessor)
  - Implement the universal filter-size conv module.
    + with 1 MAC for each module
  - Implement the stride option for pool module.
  - Implement the universal filter-size pool module.

* Other parts
  - Provide sufficient documents
    + include in-code comments

License
==================================================

GPLv2 License (see `LICENSE` file).
