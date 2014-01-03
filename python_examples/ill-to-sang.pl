#!/usr/bin/perl -w
use strict;
use warnings;

# Convert from Illumina fq to Sanger fq
# input is stdin, output stdout
# usage: gunzip myfile-illumina.fq | ill-to-sang.pl >myfile-sanger.fq
# H.J. Megens, last modified 01062010

while(<>){
	my $line = $_;
	if ($line and $line =~ m/^@/){
		print $line;
		my $line2 = <>;
		print $line2;
		my $line3 = <>;
		print $line3;
		my $line4 = <>;
		chomp $line4;
		my @illqs = split('',$line4);
		my $Q = '';
		$Q .= chr( ord($_) - 31) for @illqs;
		print $Q . "\n";
	}
}
exit;


