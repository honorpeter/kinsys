#!/usr/bin/env python3
'''
Spec note for lenet_bare on kinpira

This code works on the baremetal environment.
(other example applications may assume kinpira to
be set up on the linux environment.)

You could set up the design by running `make all` on vivado/ sub-directory.
That is, the default configuration of kinpira follows
requirements of this application.
'''

"""
shape of weights
"""
conv0 = (16, 1, 5, 5)
conv1 = (32, 16, 5, 5)
full2 = (128, 512)
full3 = (10, 128)

dwidth         = 16
imgsize        = 16
renkon_core    = 8
renkon_netsize = 11
gobou_core     = 16
gobou_netsize  = 13


"""
total amount of parameters for each coprocessor,
number of parameter entries for each processing elements,
words provided from weight memory on processing elements.
"""
params_renkon = conv0[0] * (conv0[1] * conv0[2] * conv0[3] + 1) \
              + conv1[0] * (conv1[1] * conv1[2] * conv1[3] + 1)
params_gobou  = full2[0] * (full2[1] + 1) \
              + full3[0] * (full3[1] + 1)
print("params_renkon", params_renkon)
print("params_gobou", params_gobou)

entry_renkon = params_renkon / renkon_core
entry_gobou  = params_gobou / gobou_core
print("entry_renkon", entry_renkon)
print("entry_gobou", entry_gobou)

words_renkon = 2 ** renkon_netsize
words_gobou  = 2 ** gobou_netsize
print("words_renkon", words_renkon)
print("words_gobou", words_gobou)

"""
total bit amounts
(This value have to be low than total amount of BRAM on FPGA you target)
"""
total_mem = dwidth * words_renkon * renkon_core \
          + dwidth * words_gobou * gobou_core \
          + 2 ** imgsize
print("total_mem", total_mem/2**20, "[Mb]")

