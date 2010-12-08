#!/usr/bin/perl

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

print "To exit send EOF(^d) or INT(^c).\n";

while ( <> ) { 
	chomp($_);
	print " => ", md5_hex($_), "\n";
}

