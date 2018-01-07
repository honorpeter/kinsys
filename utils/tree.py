#!/usr/bin/env python3
"""Making Tree diagram
Input: Number of Leaves (corresponds to the number of multipliers)
Output: the least height binary tree that covers all leaves given
        (corresponds to the tree multiply-add unit.)

Practically, useful for generate verilog description.

Written by Takayuki Ujiie
"""

import sys

class Tree:
    def __init__(self, out, add, mul):
        self.out = out
        self.add = add
        self.mul = mul
        self.define = ""
        self.assign = ""
        self.generated = False

    def __call__(self, num):
        if not self.generated:
            self.gen(num)
            self.generated = True

        return self.define, self.assign

    def root(self, target, ope_a):
        pass

    def node(self, target, ope_a, ope_b):
        pass

    def gen(self, num_leaf, depth_rem=0, rank=0):
        """tree
        """
        out = self.out
        add = self.add
        mul = self.mul
        has_rem = depth_rem != 0

        # Boundary
        if num_leaf == 1 and not has_rem:
            if rank == 0:
                self.root(out, f"{mul}[0]")
            else:
                self.root(out, f"{add}{rank-1}_0")
            return

        # Recursive
        if num_leaf % 2 == 0:
            if has_rem:
                num_node = num_leaf // 2
                if rank == 0:
                    for i in range(num_node):
                        self.node(f"{add}{rank}_{i}",
                                  f"{mul}[{2*i}]",
                                  f"{mul}[{2*i+1}]")
                else:
                    for i in range(num_node):
                        self.node(f"{add}{rank}_{i}",
                                  f"{add}{rank-1}_{2*i}",
                                  f"{add}{rank-1}_{2*i+1}")
                self.gen(num_node, depth_rem+1, rank+1)
            else:
                num_node = num_leaf // 2
                if rank == 0:
                    for i in range(num_node):
                        self.node(f"{add}{rank}_{i}",
                                  f"{mul}[{2*i}]",
                                  f"{mul}[{2*i+1}]")
                else:
                    for i in range(num_node):
                        self.node(f"{add}{rank}_{i}",
                                  f"{add}{rank-1}_{2*i}",
                                  f"{add}{rank-1}_{2*i+1}")
                self.gen(num_node, 0, rank+1)
        else:
            if has_rem:
                num_node = num_leaf // 2 + 1
                if depth_rem == rank:
                    for i in range(num_node-1):
                        self.node(f"{add}{rank}_{i}",
                                  f"{add}{rank-1}_{2*i}",
                                  f"{add}{rank-1}_{2*i+1}")
                    self.node(f"{add}{rank}_{num_node-1}",
                              f"{add}{rank-1}_{2*(num_node-1)}",
                              f"{mul}[{2*num_leaf*(2**(rank-1))}]")
                else:
                    for i in range(num_node-1):
                        self.node(f"{add}{rank}_{i}",
                                  f"{add}{rank-1}_{2*i}",
                                  f"{add}{rank-1}_{2*i+1}")
                    self.node(f"{add}{rank}_{num_node-1}",
                              f"{add}{rank-1}_{2*(num_node-1)}",
                  f"{add}{rank-1-depth_rem}_{2*num_leaf*(2**(depth_rem-1))}")
                self.gen(num_node, 0, rank+1)
            else:
                num_node = num_leaf // 2
                if rank == 0:
                    for i in range(num_node):
                        self.node(f"{add}{rank}_{i}",
                                  f"{mul}[{2*i}]",
                                  f"{mul}[{2*i+1}]")
                else:
                    for i in range(num_node):
                        self.node(f"{add}{rank}_{i}",
                                  f"{add}{rank-1}_{2*i}",
                                  f"{add}{rank-1}_{2*i+1}")
                self.gen(num_node, depth_rem+1, rank+1)

class MulAddTree(Tree):
    def root(self, target, ope_a):
        """root
        """
        self.define += f"  wire signed [DWIDTH-1:0] {target};\n"
        self.assign += f"  assign {target} = {ope_a};\n"

    def node(self, target, ope_a, ope_b):
        """node
        """
        self.define += f"  wire signed [DWIDTH-1:0] {target};\n"
        self.assign += f"  assign {target} = {ope_a} + {ope_b};\n"

class MaxPoolTree(Tree):
    def root(self, target, ope_a):
        """root
        """
        self.define += f"  wire signed [DWIDTH-1:0] {target};\n"
        self.assign += f"  assign {target} = {ope_a};\n"

    def node(self, target, ope_a, ope_b):
        """node
        """
        self.define += f"  wire signed [DWIDTH-1:0] {target};\n"
        self.assign += f"  assign {target} = ({ope_a} > {ope_b}) ? {ope_a} : {ope_b};\n"

if __name__ == "__main__":
    pool = True
    if pool:
        tree = MaxPoolTree("pmap", "max", "pixel$")
    else:
        tree = MulAddTree("fmap", "sum", "pro_short")

    define, assign = tree(int(sys.argv[1]))

    print(define)
    print(assign)
