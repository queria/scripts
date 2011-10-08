#!/usr/bin/python3
"""copy-case-insensitive.py
Copies contents of source directory to target directory recursively.
Overwriting target files/directories which names are compared
case-insensitively.

For example:
    $ copy-case-insensitive.py /tmp/source /tmp/target
    === CCIN will process /tmp/source into /tmp/target ===
    /tmp/source/druhy --> /tmp/target/DRUHY: [dir exists]
    /tmp/source/druhy/Dalsi --> /tmp/target/DRUHY/Dalsi: [copy/overwrite]
    /tmp/source/druhy/Nejaky.CC --> /tmp/target/DRUHY/nejaky.cc: [copy/overwrite]
    /tmp/source/pRvni --> /tmp/target/pRvni: [dir exists]
    /tmp/source/pRvni/FKf --> /tmp/target/pRvni/fkf: [copy/overwrite]
    /tmp/source/pRvni/f4fvv --> /tmp/target/pRvni/F4FVV: [copy/overwrite]
    /tmp/source/ahoj.txt --> /tmp/target/ahoj.txt: [copy/overwrite]
    /tmp/source/mOje.txt --> /tmp/target/moje.txt: [copy/overwrite]
    === done ===

Warning:
    It only handles cases of nested files/directories.
    Path to source/target dir will be taken exactly as is.
    So it will depend on character cases.
    So if args are: src=/my/dir/ tgt=/other/dir/
    and some /OTHER/DIR/ exist,
    it will NOT be touched by this script,
    and instead new /other/dir/ will be created!
"""

import sys
import os
import shutil

def get_lowercase_hash(items_list):
    lowers = {}
    for item in items_list:
        lowers[ item.lower() ] = item
    return lowers

def do_copy(source, target):
    print('{0} --> {1}: '.format(source, target), end='')
    if os.path.isdir(source):
        if os.path.exists(target) and not os.path.isdir(target):
            os.unlink(target)
        if not os.path.exists(target):
            print('[mkdir]')
            os.mkdir(target)
        else:
            print('[dir exists]')
    else:
        if os.path.isdir(target):
            shutil.rmtree(target)
        print('[copy/overwrite]')
        shutil.copyfile(source, target)

def process_dir(source, target):
    target_items = get_lowercase_hash(os.listdir(target))
    for item in os.listdir(source):
        target_name = item
        if item.lower() in target_items:
            target_name = target_items[item.lower()]
        source_path = os.path.join(source, item)
        target_path = os.path.join(target, target_name)
        do_copy(source_path, target_path)
        if os.path.isdir(source_path):
            process_dir(source_path, target_path)

if __name__ == '__main__':
    source_dir = ''
    target_dir = ''

    try:
        source_dir = sys.argv[1]
        target_dir = sys.argv[2]
    except IndexError:
        print('You have to specify source and target directory respectively.')
        sys.exit(1)

    if not os.path.isdir(source_dir):
        print('Directory '+source_dir+' have to exists ' +
                'and be readable by this script (your user).')
        sys.exit(1)

    if not os.path.isdir(target_dir) and not os.makedirs(target_dir):
        print('Directory '+target_dir+' needs to be ' +
                'writable (or creatable) by this script.')
        sys.exit(1)

    print('=== CCIN will process {0} into {1} ==='.format(
            source_dir,
            target_dir))
    process_dir(source_dir, target_dir)
    print('=== done ===')

