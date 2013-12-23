#!/usr/bin/perl -w
use strict;
use warnings;
use Getopt::Std;
my %opts = ();

$opts{b}='100000';
$opts{f}='infile';
getopt('fb123', \%opts);
my $file = $opts{f};
my $binsize=$opts{b};
my $one = $opts{1};
my $two = $opts{2};
my $three = $opts{3};
open(FILE, $file) or die "can not open $file $!\n";
my $firstline = <FILE>;
chomp $firstline;
close(FILE);
my @firstelements = split("\t",$firstline);
my $count = 0;
my $onecount = '';
my $twocount = '';
my $threecount = '';
my $testcount=0;
my $snpfixed=0;
my $snphet=0;
my $refcount=0;
my @pigarray=();
my @hetarray=();
my @fixarray=();

foreach my $element (@firstelements){
	if ($element =~ /_mx/){
		$element =~ s/_mx//;
		push(@pigarray,$element);
		push(@hetarray,'0');
		push(@fixarray,'0');
		$onecount = $count;
		++$testcount;
	}
	 if ($element eq 'ref'){
                $refcount = $count;
                ++$testcount;
        }

	++$count;
}
my $teller=0;
print "num pigs: ".scalar @pigarray."\n";
open(FILE, $file) or die "can not open $file $!\n";
$firstline = <FILE>;
my @check = split("\t",$firstline);
print "check: $check[$onecount]\t";
while (<FILE>){
	my $line = $_;
	chomp $line;
	my @int = split("\t",$line);
	$teller=0;
	for my $pig (@pigarray){
	
		my $firstallele = $int[$teller+2];
		my $refallele = $int[$refcount];

		if ($firstallele =~ /[ACGT]/ && $refallele ne $firstallele){

			++$fixarray[$teller];
			#print "fxd: $snpfixed\n";
		}
		if ($firstallele =~ /[SWMKRY]/){ 
	
	                ++$hetarray[$teller]; 
			#print "het: $snphet\n";
	        }
		++$teller;
	}
}
$teller=0;
foreach my $pig (@pigarray){
	print "$pig $pigarray[$teller]\t$fixarray[$teller]\t$hetarray[$teller]\t\n";
	++$teller;
}

	
close(FILE);
exit;
