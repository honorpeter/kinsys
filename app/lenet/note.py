#!/usr/bin/env python3
'''
Spec note for lenet on kinpira
'''

import math

def conv_param(l):
    return l[0] * (l[1] * l[2] * l[3] + 1)

def full_param(l):
    return l[0] * (l[1] + 1)

def clog2(entry):
    if entry == 0:
        return 0
    else:
        return math.ceil(math.log2(entry))

dwidth         = 16
renkon_core    = 8 # 220 // 25
gobou_core     = 16
print("renkon_core", renkon_core)
print("gobou_core", gobou_core)

conv0 = (16, 1, 5, 5)
conv1 = (32, 16, 5, 5)
full2 = (128, 512)
full3 = (10, 128)

params_renkon = conv_param(conv0) + conv_param(conv1)
params_gobou  = full_param(full2) + full_param(full3)
print("params_renkon", params_renkon)
print("params_gobou", params_gobou)

entry_renkon = params_renkon / renkon_core
entry_gobou  = params_gobou / gobou_core
print("entry_renkon", entry_renkon)
print("entry_gobou", entry_gobou)

renkon_netsize = clog2(entry_renkon)
gobou_netsize  = clog2(entry_gobou)
words_renkon = 2 ** renkon_netsize
words_gobou  = 2 ** gobou_netsize
print("words_renkon", words_renkon)
print("words_gobou", words_gobou)

total_mem = dwidth * words_renkon * renkon_core \
          + dwidth * words_gobou * gobou_core
print("total_mem", total_mem/2**20, "[Mb]")
print("total_mem", total_mem/(8*2**20), "[MB]")

