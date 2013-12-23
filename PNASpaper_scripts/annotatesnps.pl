#!/usr/bin/perl -w
use strict;
use warnings;
use Getopt::Std;
my %opts = ();

$opts{b}='100000';
$opts{f}='infile';
$opts{s}='snpfile';
getopt('fbs12', \%opts);
my $file = $opts{f};
my $snpfile = $opts{s};
my $binsize=$opts{b};
open(FILE, $file) or die "can not open $file $!\n";
my %firstcodonpositions = ();
my %secondcodonpositions = ();
my %thirdcodonpositions = ();
my $linenumber=0;
while (<FILE>){
	my $line = $_;
	++$linenumber;
	#print "$linenumber\n";
	chomp $line;
	my @elements = split("\t",$line);
	my $chrom = $elements[0];
	my $start = $elements[3];
	my $end = $elements[4];
	my $phase = $elements[7];
	my $comments = $elements[8];
	for (my $i=$start; $i<($end+1); ++$i){
		if ($phase ==0 ){
			$firstcodonpositions{'Ssc10_2_'.$chrom."_".$i}=$comments; 
			$phase=1;
		}
		elsif ($phase ==1 ){
			$secondcodonpositions{'Ssc10_2_'.$chrom."_".$i}=$comments;
			$phase=2;
		}
		elsif ($phase ==2 ){
			$thirdcodonpositions{'Ssc10_2_'.$chrom."_".$i}=$comments;
			$phase=0;
		}
	}
}
close(FILE);
open(FILE,$snpfile) or die "no such file $!\n";
while(<FILE>){
	my $line = $_;
	chomp $line;
	my @elements = split("\t",$line);
	my $chrom = $elements[0];
        my $coord = $elements[1];
	if (exists $firstcodonpositions{$chrom."_".$coord}){
		print $line."\t".$firstcodonpositions{$chrom."_".$coord}."\tfirstcodon\n";
	}
	if (exists $secondcodonpositions{$chrom."_".$coord}){
                print $line."\t".$secondcodonpositions{$chrom."_".$coord}."\tsecondcodon\n";
        }
	if (exists $thirdcodonpositions{$chrom."_".$coord}){
                print $line."\t".$thirdcodonpositions{$chrom."_".$coord}."\tthirdcodon\n";
        }
}
close(FILE);
print "done\n";
exit;


