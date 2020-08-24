#!/usr/bin/env python
# coding=utf-8

import sys
import os

def walklevel(some_dir, level=1):
    some_dir = some_dir.rstrip(os.path.sep)
    assert os.path.isdir(some_dir)
    num_sep = some_dir.count(os.path.sep)
    for root, dirs, files in os.walk(some_dir):
        num_sep_this = root.count(os.path.sep)
        if num_sep + level <= num_sep_this:
            return
        yield (root, dirs, files)

# e.g., home/eduardo/proj/DBN/data/raw/ADNI
data_dir = sys.argv[1]
# e.g., home/eduardo/poj/DBN/data/raw/ADNI/subjects.txt
out_file = sys.argv[2]

# x = (root, dirs, files)
IDList = [x[1] for x in walklevel(data_dir, level=1)]
# Flattening the list of IDs
IDList = [x for ID in IDList for x in ID]
IDList.sort()
if not os.path.exists(out_file):
    with open(out_file, 'w+') as outFile:
        outFile.writelines("%s\n" % ID for ID in IDList)
