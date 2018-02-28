#!/usr/bin/env python3
"""
TODO: include training
"""

import argparse

import os
from os.path import join, exists
import sys
import textwrap

import numpy as np

sys.path.append("../../utils")

import save

BASE_DIR = "/home/work/takau/2.mlearn/models_chainer"
INPUT_DIR = join(BASE_DIR, "mnist", "test")
PARAM_DIR = join(BASE_DIR, "lenet")
DIST_DIR = join("src", "data")

def bin_of_float(path):
    floatfile = np.loadtxt(path).astype(np.float) * 256
    fixed = np.around(floatfile).astype(np.int) & 0xffffffff
    return list(map("  0b{:032b},".format, fixed))

def bin_of_hex(path):
    hexfile = np.loadtxt(path, dtype=np.int,
                         converters={0: lambda s: int(s, 16)})
    fixed = hexfile & 0xffffffff
    print(path)
    print(fixed)
    return list(map("  0b{:032b},".format, fixed))

def gen_image(args):
    image_path = join(INPUT_DIR, args.input_label, f"img{args.input_name}.dat")
    image = bin_of_float(image_path)
    with open(join(DIST_DIR, "image.h"), "w") as f:
        f.write(textwrap.dedent(f"""
            #ifndef _IMAGE_H_
            #define _IMAGE_H_

            // PATH: {image_path}
            static s32 image[{len(image)}] = {{
        """).strip()+"\n")
        f.write(f"{os.linesep.join(image)}"+"\n")
        f.write(textwrap.dedent(f"""
            }};

            #endif
        """).strip()+"\n")

def gen_param(args):
    for layer in os.listdir(PARAM_DIR):
        with open(join(DIST_DIR, f"{layer}.h"), "w") as f:
            f.write(textwrap.dedent(f"""
                #ifndef _{layer.upper()}_H_
                #define _{layer.upper()}_H_

            """).strip()+"\n\n")
            for Type in ["W", "b"]:
                param_path = join(PARAM_DIR, layer, f"{Type}.dat")
                param = bin_of_float(param_path)
                f.write(textwrap.dedent(f"""
                    // PATH: {param_path}
                    static s32 {Type}_{layer}[{len(param)}] = {{
                """).strip()+"\n")
                f.write(f"{os.linesep.join(param)}"+"\n")
                f.write(textwrap.dedent(f"""
                    }};

                """).strip()+"\n\n")
            f.write(textwrap.dedent(f"""

                #endif
            """).strip()+"\n")

def gen_debug(args):
    for layer in os.listdir(PARAM_DIR):
        tru_path = join("..", "..", "data", "common", f"{layer}_tru.dat")
        tru = bin_of_hex(tru_path)
        with open(join(DIST_DIR, f"{layer}_tru.h"), "w") as f:
            f.write(textwrap.dedent(f"""
                #ifndef _{layer.upper()}_TRU_H_
                #define _{layer.upper()}_TRU_H_

                static s32 {layer}_tru[{len(tru)}] = {{
            """).strip()+"\n")
            f.write(f"{os.linesep.join(tru)}"+"\n")
            f.write(textwrap.dedent(f"""
                }};

                #endif
            """).strip()+"\n")

def optparse():
    parser = argparse.ArgumentParser(description="dump parameters for lenet")

    parser.add_argument("input_label")
    parser.add_argument("input_name")

    return parser.parse_args()

def main():
    args = optparse()

    if not exists(DIST_DIR):
        os.makedirs(DIST_DIR)

    gen_image(args)
    gen_param(args)
    gen_debug(args)

if __name__ == "__main__":
    main()
