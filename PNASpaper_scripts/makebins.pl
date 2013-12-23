#!/usr/bin/perl -w
use strict;
use warnings;
use Getopt::Std;
my %opts = ();

$opts{b}='100000';
$opts{f}='infile';
getopt('fb', \%opts);
my $file = $opts{f};
my $binsize=$opts{b};
my $outfile=$file."_bins";
open (OUT, ">$outfile");
open(FILE, $file) or die "can not open $file $!\n";
my $chrom;
my $bin =$binsize;
my $value =0;
my $count=0;
while (<FILE>){
	my $line = $_;
	chomp $line;
	my @int = split("\t",$line);
	my $refchrom = $int[0];
	unless ($chrom){
		$chrom = $refchrom;
	}
	my $refpos = $int[1];
	my $plusmin = $int[5];
	++$count;
	$value = $value + $plusmin;
	if ($refpos > $bin){
		my $average = ($value-$plusmin)/($count-1);
		print OUT "$chrom\t$bin\t$count\t$average\n";
		$bin = $bin + $binsize;
		$value=$plusmin;
		$count=1;
	}
	elsif ($refchrom ne $chrom) {
		my $average = ($value-$plusmin)/($count-1);
		print OUT "$chrom\t$bin\t$count\t$average\n";
		$bin = $bin + $binsize;
		$value=$plusmin;
		$count=1;
		$chrom = $refchrom;
		$bin =$binsize;
	}
}
my $average = $value/$count;
print OUT "$chrom\t$bin\t$count\t$average\n";
close(FILE);
close(OUT);
exit;
