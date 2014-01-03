#!/usr/bin/perl -w
use strict;
use warnings;
my %hash=();
my $dna = 'ACGTNacgtn';
my @dnaarray = split('',$dna);
foreach my $d (@dnaarray){
	$hash{$d}=0;
}
foreach my $key (keys %hash){
	print "$key\t$hash{$key}\n";
}
open(IN, $ARGV[0]);
while(<IN>){
	my $line = $_;
	chomp $line;
	my @array = split('',$line);
	
	foreach my $base (keys %hash){
		$hash{$base}+= grep /$base/, @array;
	}
	#$hash{$_} +=1 for @array if ($dna ~= m/$_/);
}
close(IN);
foreach my $key (keys %hash){
	print "$key\t$hash{$key}\n";
}
exit;
