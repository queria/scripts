#!/usr/bin/env python2
from __future__ import print_function
import json
import os
import pprint
import subprocess
import sys
import time
import yaml

# DESCRIPTION:
# get list of all_open := changes in <project>
# get all my_open := changes in <project> owned by <owner>
# ... from the <server>:<port> gerrit
#
# for each of my_open
# - try rebase if:
#   - change was not touched in <lately_days>
#   - change does not depends on any other in all_open
#   - change NOT is:mergeable
#   - change has no CR-1
# - add <the_reviewer> as reviewer
#   - if there is no <the_reviewer> already
#
# when <debug> is not False/false/...  or when --debug
# is used, all ssh commands and info about decisions being made
# will be printed to stdout
#
# when <debug_change> contains change number (short int), my_open will
# contain only this change, and should_be_rebased will
# filter any other change out too
#
# aside --debug, --force may be used to skip few checks
# (negative-review, touched-lately, depends-on)


# config file loaded from ~/.autorebase.yaml
config = {
    'debug': False,
    'debug_change': '',
    'server': 'someone@review.example.org',
    'port': '29418',
    'project': 'someones/something',
    'owner': 'your-nick-or-mail',
    'branch': 'master',
    'lately_days': 1,
    'the_reviewer': '',
}


def printX(something):
    print(json.dumps(something,
          sort_keys=True,
          indent=4,
          separators=(',', ':')))


def debug(*args, **kwargs):
    if not config['debug']:
        return

    fmt = '%s'
    if 'color' in kwargs:
        colors = {'gray': '01;30'}
        clr = colors[kwargs.pop('color')]
        if sys.stdout.isatty():
            fmt = '\033['+clr+'m%s\033[0m'

    print(fmt % ' '.join(args))
    if kwargs:
        print(fmt % pprint.pformat(kwargs))


def change2num(change):
    return ','.join(change['currentPatchSet']['ref'].split('/')[-2:])


def ssh_gerrit(action):
    cmd = ("ssh -p{port} {server} gerrit ").format(**config)
    cmd += action
    debug('>>>', cmd, color='gray')
    return subprocess.check_output(cmd, shell=True)


def rebase_change(change_info):
    ssh_gerrit('review --rebase %s' % change2num(change))


def list_changes(query_filter=None):
    if query_filter is None:
        query_filter = 'status:open'
        if config['debug_change']:
            query_filter = 'change:%s' % config['debug_change']
        if config['owner']:
            query_filter = '%s owner:%s' % (query_filter, config['owner'])
        if config['branch']:
            query_filter = '%s branch:%s' % (query_filter, config['branch'])

    changes_str = ssh_gerrit(
        ("query 'project:%s %s'"
         " --current-patch-set"
         " --dependencies"
         " --all-reviewers"
         " --format json") % (
             config['project'], query_filter))

    changes = []
    for line in changes_str.split('\n'):
        line = line.strip()
        if not line:
            continue
        change = json.loads(line)
        if change.get('type', '') == 'stats':
            continue
        if change.get('type', '') == 'error':
            raise Exception('Got gerrit error: %s'
                            % change['message'])
        changes.append(change)
    return changes


def add_reviewer(change, reviewer_mail):
    ssh_gerrit(('set-reviewers'
                ' --add %s'
                ' --project %s'
                ' %s') % (
                    reviewer_mail,
                    config['project'],
                    change['number']))


def has_reviewer(change, reviewer_mail):
    for person in change['allReviewers']:
        if person['email'] == reviewer_mail:
            return True
    return False


def touched_lately(change):
    day_ago = int(time.time() - (float(config['lately_days'])*24*60*60))
    return int(change['lastUpdated']) > day_ago


def depends_on_any(change, changes):
    all_ids = [ch['id'] for ch in changes]
    for dep in change.get('dependsOn', []):
        if dep['id'] in all_ids:
            return True
    return False


def is_mergeable(change):
    return 1 <= len(list_changes(
        'is:mergeable change:%s' % change['number']))


def has_negative_cr(change):
    for vote in change['currentPatchSet'].get('approvals', []):
        if vote['type'] == 'Code-Review' and int(vote['value']) < 0:
            return True
    return False


def should_be_rebased(change, force=False):
    if config['debug_change']:
        # info already in 'change' and config
        if str(change.get('number', '')) != str(config['debug_change']):
            debug('- is NOT THE DEBUG change')
            return False

    if not force and has_negative_cr(change):
        # info already in 'change'
        debug('- has negative review')
        return False

    if not force and depends_on_any(change, all_open):
        # info already in 'change' and 'all_open'
        debug('- has open dependency')
        return False

    if not force and touched_lately(change):
        # info already in 'change'
        debug('- was touched lately')
        return False

    if force:
        debug('- forced so negative_cr, depends and touched_lately'
              ' checks were skipped')

    if is_mergeable(change):
        # requires additional ssh query, so last
        debug('- is mergeable')
        return False

    return True


def load_config(path):
    with open(os.path.expanduser(path)) as cfg_file:
        config.update(yaml.load(cfg_file))
    if config['debug'] in ('False', 'false', 'no', '0', 0):
        config['debug'] = False
    if '--debug' in sys.argv:
        config['debug'] = True

if __name__ == '__main__':
    load_config('~/.autorebase.yaml')

    all_open = list_changes('status:open')
    my_open = list_changes()

    for change in my_open:
        try:
            debug('[%s] %s' % (change['url'], change['subject']))
            if should_be_rebased(change, '--force' in sys.argv):
                debug('- should be rebased')
                try:
                    rebase_change(change)
                except subprocess.CalledProcessError:
                    debug('- rebase FAILED! maybe there is REAL CONFLICT?')
            if (config['the_reviewer']
                    and not has_reviewer(change, config['the_reviewer'])):
                debug('- is missing the reviewer')
                add_reviewer(change, config['the_reviewer'])
        except Exception as exc:
            config['debug'] = True
            debug('Exception %s with change %s' % (exc, change))
            raise
