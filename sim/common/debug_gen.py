#!/usr/bin/env python3

import argparse

import os
from os.path import join, exists

import numpy as np

BASE_DIR = "/home/work/takau/2.mlearn/models_chainer"
_BASE_DIR = "../../data/common"
PARAM_DIR = join(BASE_DIR, "lenet")
INPUT_DIR = join(BASE_DIR, "mnist", "test")

def hex_of_float(path):
    floatfile = np.loadtxt(path).astype(np.float) * 256
    fixed = np.around(floatfile).astype(np.int) & 0xffff
    return list(map("{:04x}".format, fixed))

def make(src, dst):
    param = hex_of_float(src)
    with open(dst, "w") as f:
        f.write("\n".join(param)+"\n")

def optparse():
    parser = argparse.ArgumentParser(description="dump parameters for lenet")

    parser.add_argument("input_label")
    parser.add_argument("input_name")

    return parser.parse_args()

def main():
    args = optparse()

    if not exists(_BASE_DIR):
        os.makedirs(_BASE_DIR)

    make(join(INPUT_DIR, args.input_label, f"img{args.input_name}.dat"),
         join(_BASE_DIR, f"{args.input_label}_img{args.input_name}.dat"))

    for layer in os.listdir(PARAM_DIR):
        for Type in ["W", "b"]:
            make(join(PARAM_DIR, layer, f"{Type}.dat"),
                 join(_BASE_DIR, f"{Type}_{layer}.dat"))

if __name__ == "__main__":
    main()

