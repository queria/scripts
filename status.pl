#!/usr/bin/perl

use strict;
use warnings;

my $max_cnt = 1;
my $sleeptime = 2;

$| = 1; # no out buffer

open(my $loadavg, '<', "/proc/loadavg") || die("unable to open /proc/loadavg");

my $r_avg = qr/(([0-9\.]+ ?){2}) .*$/;
my $r_cmd = qr/(\d) /;

my $cnt = 0;
for (;;) {
	my $load = <$loadavg>;
	seek( $loadavg, 0, 0);
	chomp($load);
	$load =~ s/$r_avg/$1/;

	my $topcmd = `ps -eo pcpu,comm | sort -n -k 1 -r | head -1`;
	chomp($topcmd);
	$topcmd =~ s/$r_cmd/$1% /;

	if($max_cnt > 1){
		printf "\r";
		printf "%s: %s                ", $load, $topcmd;
	} else {
		printf "%s: %s", $load, $topcmd;
	}
	$cnt++;
	last if $max_cnt > 0 and $cnt >= $max_cnt;
	sleep($sleeptime);
}

printf "\n";

