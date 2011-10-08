#! /usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import sys
from datetime import datetime

use_log = False

def find_next_log_name():
    fname_template = "/tmp/args_test-{:04d}.log"
    num = 0
    while os.path.exists(fname_template.format(num)):
        num += 1
    return fname_template.format(num)

def print_args(log):
    log.write(str(datetime.now()))
    log.write("\n------------------\n\n")
    for opt in sys.argv:
        log.write(opt)
        log.write("\n")

if use_log:
    fname = find_next_log_name()
    print(fname)
    with open(fname, 'w', encoding='utf-8') as log:
        print_args(log)
else:
    print_args(sys.stdout)

input('Press Enter')


