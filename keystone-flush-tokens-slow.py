#!/usr/bin/env python
"""Clean expired tokens from keystone database (very) slowly.

When token table grows so much, keystone-manage token_flush <..>
maybe not be able to clean it up (too long for locking + reindexing).

Probably best way is, when small downtime is acceptable,
to export valid tokens, truncate, import back, while keystone is stopped::

    $ cat clean-tokens.sh
    #!/bin/bash
    set -x
    service openstack-keystone stop;

    time mysql -ukeystone_admin -pYourPassHERE -hYourHostHERE <<EOF
    use keystone;
    drop table if exists maint_token_valid;
    create table maint_token_valid
        as (select * from token where expires >= NOW());
    select count(*) from maint_token_valid;
    truncate table token;
    insert into token select * from maint_token_valid;
    drop table maint_token_valid;
    EOF

    service openstack-keystone start;

If you don't want to take service down or
try running without keys for a while :) this script
may help you little bit as it will 'slow down' keystone responses
little bit, but mostly (without heavy load) keep services working.
"""
from __future__ import print_function
from datetime import datetime, timedelta
import sys
import getpass
import MySQLdb


def get_conn():
    if len(sys.argv) < 4:
        print('Usage:\n  %s <host> <username> <db> [password]' % sys.argv[0])
        sys.exit(1)

    host = sys.argv[1]
    user = sys.argv[2]
    db_name = sys.argv[3]
    if len(sys.argv) > 4:
        pwd = sys.argv[4]
    else:
        pwd = getpass.getpass(prompt='MySQL password for %s@%s:'
                              % (user, host))

    con = MySQLdb.connect(host=host, user=user, passwd=pwd, db=db_name)
    return con


def get_oldest_date(con):
    cur = con.cursor()
    cur.execute("select expires from token order by expires asc limit 1")
    oldest = cur.fetchone()[0]
    cur.close()
    return datetime(year=oldest.year, month=oldest.month, day=oldest.day)


def dt2mysql(dtime):
    return dtime.strftime('%Y-%m-%d %H:%M:%S')


def clean_tokens(con, first_day, last_day, step=None):
    """Clean token table where expires is in [first..last].

    Do remove all tokens from token table where expires field
    is in the first_day <= expires <= last_day.
    And do it by batches determined by step (defaults to one hour).

    con ... MySQLdb connection
    first/last_day ... datetime.datetime
    step ... datetime.timedelta
    """
    if step is None:
        step = timedelta(seconds=(60 * 60))
    clean_till_day = first_day
    while clean_till_day <= last_day:
        till_str = dt2mysql(clean_till_day)
        start = datetime.utcnow()

        print('[%s] Cleaning till %s ...  ' % (start, till_str), end='')
        sys.stdout.flush()

        cur = con.cursor()
        try:
            cur.execute("delete from token where expires <= '%s'"
                        % till_str)
        except KeyboardInterrupt:
            print('interrupted!')
            sys.stdout.flush()
            con.commit()
            cur.close()
            raise
        except Exception:
            print('rolling back!')
            sys.stdout.flush()
            con.rollback()
            cur.close()
            raise
        print('cleaned %s rows in %s seconds'
              % (con.affected_rows(),
                 (datetime.utcnow() - start).seconds))
        sys.stdout.flush()
        try:
            con.commit()
        except KeyboardInterrupt:
            con.commit()
            cur.close()
            raise
        cur.close()
        clean_till_day += step


if __name__ == '__main__':
    con = get_conn()

    one_step = timedelta(seconds=(60 * 60))
    oldest = get_oldest_date(con)
    newest = datetime.utcnow() - one_step

    clean_tokens(con, oldest, newest, one_step)
