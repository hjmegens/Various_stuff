#!/usr/bin/perl -w
use strict;
use warnings;
use Getopt::Std;
my %opts = ();

$opts{f}='infile';
$opts{b}='100000';
$opts{t}='100';
getopt('fbt', \%opts);
my $infile = $opts{f};
my $binsize=$opts{b};
my $threshold=$opts{t};
my $oldchrom = 'NA';
#open (PRO, "$infile") or die "No such file! $!\n";
#open (VAR, ">sv-binvars_$infile");
#open(EXON,"genefile_$infile.csv");
#open(EXONINFO,">bininfofile_$infile");
my $bin=$binsize;
my $count=0;
#print FAS ">Sus_verrucosus_MT\n";
my $totgroup1=0;
my $totgroup2=0;
my $allpos=0;
my $ratio=1;
my $group1avgfreq=0;
my $group2avgfreq=0;
my $totfst=0;
my $fstavg=0;

while (<>){
	my $line = $_;
	chomp $line;
	my @elements = split("\t",$line);
	my $chrom = $elements[0];
	my $refpos = $elements[1];
	my $refbase = $elements[3];
	my $nonref = $elements[4];
	my $info = $elements[5];
	@elements = split(" ",$info);
	my $ancstate=$elements[0];
	my $group1freq = $elements[2];
	my $group2freq = $elements[3];
	my $fst = $elements[4];
	$ancstate =~ s/anc://;
	$group1freq =~ s/group1://;
	$group2freq =~ s/group2://;
	$fst =~ s/gr1vs2fst://;
	
	#print "$chrom $refpos $refbase $nonref $ancstate $group1freq $group2freq $fst\n";
	if ($oldchrom eq 'NA'){
		$oldchrom = $chrom;
	}
	if ($oldchrom ne $chrom){
		if ($count>$threshold){
                        $group1avgfreq = $totgroup1/$count;
                        $group2avgfreq = $totgroup2/$count;
			$fstavg=$totfst/$allpos;
                        $ratio=$group1avgfreq/$group2avgfreq;
                }
                else {
                        $group1avgfreq = 0;
                        $group2avgfreq = 0;
			$fstavg=0;
                        $ratio=1;
                }

		print "$oldchrom\t$bin\t$group1avgfreq\t$group2avgfreq\t$ratio\t$count\t$fstavg\t$allpos\n";
		$oldchrom = $chrom;
		$bin=$binsize;
		$count=0;
		$allpos=0;
		$totgroup1=0;
		$totgroup2=0;
		$totfst=0;
	}
	if ($refpos > $bin){
		if ($count>$threshold){
			$group1avgfreq = $totgroup1/$count;
                	$group2avgfreq = $totgroup2/$count;
                	$ratio=$group1avgfreq/$group2avgfreq;
			$fstavg = $totfst/$allpos;
		}
		else {
			$group1avgfreq = 0;
                        $group2avgfreq = 0;
			$fstavg=0;
                        $ratio=1;
		}

                print "$chrom\t$bin\t$group1avgfreq\t$group2avgfreq\t$ratio\t$count\t$fstavg\t$allpos\n";
		$bin = $bin + $binsize;
		$count=0;
		$allpos=0;
		$totgroup1=0;
		$totgroup2=0;
		$totfst=0;

	}
	if ($ancstate =~ /[ACGT]/){
		++$count;
		$totgroup1=$totgroup1+$group1freq;
		$totgroup2=$totgroup2+$group2freq;
		
	}
	unless ($fst eq 'ND'){
		++$allpos;
		$totfst=$totfst+$fst;
	}
}
#print "$count\t$countgoodread\n";
#close(PRO);
#close(VAR);
#close(EXON);
#close(EXONINFO);
exit;

