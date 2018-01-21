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

BASE_DIR = "/home/work/takau/2.mlearn/fixednets/data/kitti"
PARAM_DIR = join(BASE_DIR, "Q_squeezeDet_01_scaled")
DIST_DIR = join("files", "data")

def gen_conv_quant(layer):
    with open(join(DIST_DIR, f"{layer}.hpp"), "w") as f:
        f.write(textwrap.dedent(f"""
            #ifndef _{layer.upper()}_HPP_
            #define _{layer.upper()}_HPP_

        """).strip()+"\n\n")
        for Type in ["W", "b"]:
            param_path = join(PARAM_DIR, layer, f"{Type}.txt")
            param_min_path = join(PARAM_DIR, layer, f"min_{Type}.txt")
            param_max_path = join(PARAM_DIR, layer, f"max_{Type}.txt")
            param = np.loadtxt(param_path, dtype=str)
            param_min = np.loadtxt(param_min_path, dtype=np.float)
            param_max = np.loadtxt(param_max_path, dtype=np.float)
            f.write(textwrap.dedent(f"""
                // PATH: {param_path}
                static u8 {Type}_{layer}[{len(param)}] = {{
            """).strip()+"\n")
            f.write(f"{(','+os.linesep).join(param)+os.linesep}")
            f.write(textwrap.dedent(f"""
                }};

                static float {Type}_{layer}_min = {param_min};
                static float {Type}_{layer}_max = {param_max};

            """).strip()+"\n\n")
        f.write(textwrap.dedent(f"""

            #endif
        """).strip()+"\n")

def gen_fire_quant(layer, subs = ["squeeze1x1", "expand1x1", "expand3x3"]):
    with open(join(DIST_DIR, f"{layer}.hpp"), "w") as f:
        f.write(textwrap.dedent(f"""
            #ifndef _{layer.upper()}_HPP_
            #define _{layer.upper()}_HPP_

        """).strip()+"\n\n")
        for Type in ["W", "b"]:
            for sub in subs:
                param_path = join(PARAM_DIR, layer, sub, f"{Type}.txt")
                param_min_path = join(PARAM_DIR, layer, sub, f"min_{Type}.txt")
                param_max_path = join(PARAM_DIR, layer, sub, f"max_{Type}.txt")
                param = np.loadtxt(param_path, dtype=str)
                param_min = np.loadtxt(param_min_path, dtype=np.float)
                param_max = np.loadtxt(param_max_path, dtype=np.float)
                f.write(textwrap.dedent(f"""
                    // PATH: {param_path}
                    static u8 {Type}_{layer}_{sub}[{len(param)}] = {{
                """).strip()+"\n")
                f.write(f"{(','+os.linesep).join(param)+os.linesep}")
                f.write(textwrap.dedent(f"""
                    }};

                    static float {Type}_{layer}_{sub}_min = {param_min};
                    static float {Type}_{layer}_{sub}_max = {param_max};

                """).strip()+"\n\n")
            param_subs = list(map(lambda s: f"{Type}_{layer}_{s}", subs))
            f.write(textwrap.dedent(f"""
                static std::vector<u8 *> {Type}_{layer} = {{
                {", ".join(param_subs)}
                }};

                static std::vector<float> {Type}_{layer}_min = {{
                {"_min, ".join(param_subs)+"_min"}
                }};

                static std::vector<float> {Type}_{layer}_max = {{
                {"_max, ".join(param_subs)+"_max"}
                }};

            """).strip()+"\n\n")
        f.write(textwrap.dedent(f"""

            #endif
        """).strip()+"\n")

def optparse():
    parser = argparse.ArgumentParser(
                description="dump parameters for squeezedet")

    return parser.parse_args()

def main():
    args = optparse()

    if not exists(DIST_DIR):
        os.makedirs(DIST_DIR)

    gen_conv_quant("conv1")
    gen_fire_quant("fire2")
    gen_fire_quant("fire3")
    gen_fire_quant("fire4")
    gen_fire_quant("fire5")
    gen_fire_quant("fire6")
    gen_fire_quant("fire7")
    gen_fire_quant("fire8")
    gen_fire_quant("fire9")
    gen_fire_quant("fire10")
    gen_fire_quant("fire11")
    gen_conv_quant("conv12")

if __name__ == "__main__":
    main()
