#!/usr/bin/perl -w
use strict;
use warnings;

my $dna = 'AGCAGTAACACACACACACATTAGACATGCCC';
while ($dna =~ m/([AGT])AC/g){
	my $pos = pos $dna;
	print "$pos $1\n";
}
exit;

