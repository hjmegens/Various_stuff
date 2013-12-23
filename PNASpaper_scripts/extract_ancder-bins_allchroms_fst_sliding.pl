#!/usr/bin/perl -w
use strict;
use warnings;
use Getopt::Std;
my %opts = ();

$opts{f}='infile';
$opts{b}='100';
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
my @inbin=();

while (<>){
	my $line = $_;
	chomp $line;
	my @elements1 = split("\t",$line);
       	my $chrom = $elements1[0];
	#print "$chrom $refpos $refbase $nonref $ancstate $group1freq $group2freq $fst\n";
	if ($oldchrom ne $chrom){	
		@inbin=();
		$oldchrom=$chrom;
	}
	if (scalar @inbin < $binsize){
		
		push(@inbin,$line)
	}
	else {	
		my $count=0;
		my $totgroup1=0;
		my $totgroup2=0;
		my $allpos=0;
		my $ratio=1;
		my $group1avgfreq=0;
		my $group2avgfreq=0;
		my $totfst=0;
		my $fstavg=0;
		push(@inbin,$line);
		my $countinbin=0;
		my $half=abs $binsize/2;
		foreach my $element (@inbin){
			++$countinbin;
			#print "$element\n";
		        my @elements = split("\t",$element);
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
			if ($countinbin == $half){
				$bin=$refpos;
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
		if ($count>0){
			$group1avgfreq = $totgroup1/$count;
	        	$group2avgfreq = $totgroup2/$count;
			if ($group2avgfreq==0){
				$ratio="Inf";
			}
			else {
	        		$ratio=$group1avgfreq/$group2avgfreq;
			}
		}
		else {
			$group1avgfreq="NA";
			$group2avgfreq="NA";
			$ratio = "NA";
		}
		if ($allpos>0){
			$fstavg = $totfst/$allpos;
		}
		else {
			$fstavg="NA";
		}
                print "$chrom\t$bin\t$group1avgfreq\t$group2avgfreq\t$ratio\t$count\t$fstavg\t$allpos\n";
		shift(@inbin);
	}
}
#print "$count\t$countgoodread\n";
#close(PRO);
#close(VAR);
#close(EXON);
#close(EXONINFO);
exit;

