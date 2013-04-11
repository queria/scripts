#!/usr/bin/env python

# example usage:
#  ./presta-trans-extract.py /path/to/presta/modules/cashondelivery/

import os
import re
import subprocess as subp
import sys
import hashlib

def find_trans(path):
    if not os.path.isdir(path):
        raise ValueError('{0} is not a directory!'.format(path))
    found_out = subp.Popen(
        ['grep','-R','\->l(\|{l ',path],
        stdout=subp.PIPE).communicate()[0]
    return found_out.split('\n')

def find_strings(found_lines):
    matches = []
    tpl_str = re.compile('\ss=(?P<del>[\'"])(?P<cont>.+?[^\\\])(?P=del)')
    php_str = re.compile('->l\((?P<del>[\'"])(?P<cont>.+?[^\\\])(?P=del)\)')
    for line in found_lines:
        tpl_m = tpl_str.findall(line)
        php_m = php_str.findall(line)
        for line_matches in [tpl_m, php_m]:
            if line_matches:
                for str_match in line_matches:
                    matches.append(str_match[1])
    return sorted(list(set(matches)))

def calculate_hashed(tr_list):
    return [ (hashlib.md5(tr).hexdigest(), tr)
            for tr in tr_list]

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('Specify path where to look for translatable strings.')
        sys.exit(1)

    lines = find_trans(sys.argv[1])
    trans = find_strings(lines)
    tr_pairs = calculate_hashed(trans)

    print("===== Translatable strings found: {0} =====".format(len(tr_pairs)))
    for trp in tr_pairs:
        print('{0} =>\t\t{1}'.format(trp[0],trp[1]))
    print('\n\n\n')
    print("===== Matching translatable lines in source code: {0} =====".format(
        len(lines)))
    for l in lines:
        print(re.sub('^{0}'.format(re.escape(sys.argv[1])),'',l))
