#!/usr/bin/perl -w
use strict;
use warnings;
use Getopt::Std;
my %opts = ();

$opts{f}='infile';
$opts{b}='100';
$opts{t}='100';
getopt('fbts', \%opts);
my $infile1 = $opts{f};
my $infile2 = $opts{s};
my $binsize=$opts{b};
open (PRO, "$infile1") or die "No such file! $!\n";
<PRO>;
while (<PRO>){
	my $line1 = $_;
        chomp $line1;
        my @elements1 = split("\t",$line1);
        my $chrom1 = $elements1[2];
	my $coord1 = $elements1[3];
	#print $line1."\n";
	#print "$chrom1\t$coord1\n";
	open (SL,"$infile2") or die "No such file $!\n";
	my $control = 0;
	while (<SL>){
		my $line2 = $_;
		if ($control < 2){
		#print $line2;
        		chomp $line2;
        		my @elements2 = split("\t",$line2);
        		my $chrom2 = $elements2[0];
			my $coord2 = $elements2[1];
			if (($chrom2 eq $chrom1) && ($coord2 < $coord1+$binsize) && ($coord2 > $coord1-$binsize)){
				print $line1."\t".$line2."\n";
				$control = 1;
			}
			elsif ($control > 0){
				$control = 2;
			}
		}
	}
	close(SL);
}
close(PRO);
exit;
