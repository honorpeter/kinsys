#!/usr/bin/env python3
"""Generate random sequence"""

import sys
import random

LENGTH = int(sys.argv[1])
WIDTH = 256
MASK = 0xffff

random.seed(None)
for i in range(LENGTH):
    randval = random.randrange(-WIDTH, WIDTH) & MASK
    # randval = random.randrange(-WIDTH, WIDTH)
    print("{:04x}".format(randval))
    # print("{}".format(randval))
