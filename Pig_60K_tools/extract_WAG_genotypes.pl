#!/usr/bin/perl -w
#===============================================================================
#
#         FILE:  extract_WAG_genotypes.pl
#
#        USAGE:  ./extract_WAG_genotypes.pl  
#
#  DESCRIPTION:  a
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  YOUR NAME (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  05/20/2011 01:49:35 PM
#     REVISION:  ---
#===============================================================================
use strict;
use warnings;
use Getopt::Std;
my $countsamples=0;
my $countgenotypes=0;
my %opts = ();
getopt('f', \%opts);
my $file = $opts{f};
my $outfile=$file."_genotypes_rn";
open (OUT, ">$outfile");
open(FILE, $file) or die "can not open $file $!\n";
my %wagsamples=();
while (<FILE>){
	my $line = $_;
	chomp $line;
	my @int = split("\t",$line);
	$wagsamples{$int[0]}=$int[6];
	print "$int[0] = $int[6]\n";
	++$countsamples;
}
close(FILE);
my $firstline=<>;
my @firstint=split("\t",$firstline);
print "$firstint[0]\t$firstint[1]\ttopallele1\ttopallele2\t$firstint[2]\t$firstint[3]\t$firstint[4]\n";
print OUT "$firstint[0]\t$firstint[1]\ttopallele1\ttopallele2\t$firstint[2]\t$firstint[3]\t$firstint[4]\n";
while (<>){
	my $line = $_;
    chomp $line;
    my @int = split("\t",$line);

	if (exists $wagsamples{$int[1]}){ 
		print OUT "$int[0]\t$wagsamples{$int[1]}\t-\t-\t$int[2]\t$int[3]\t$int[4]\n"; 
		++$countgenotypes;
	}
}
my $numpersample = $countgenotypes/$countsamples;
print "$countsamples\t$countgenotypes\t$numpersample\n";
close(OUT);
exit;
