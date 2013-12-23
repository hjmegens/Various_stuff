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
my $outfile = $one.'to'.$two.'and'.$three;
my $outfilebins=$outfile."_bins";
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
unless($one && $two && $three){
	die "You did not provide three names. Exiting.\n";
}
foreach my $element (@firstelements){
	$element =~ s/_mx//;
	if ($element eq $one){
		$onecount = $count;
		++$testcount;
	}
	if ($element eq $two){
		$twocount = $count;
		++$testcount;
	}
	if ($element eq $three){
		$threecount = $count;
		++$testcount;
	}
	++$count;
}
if ($testcount<3){
	die "you did not provide three valid names. Exiting.\n";
}
open(FILE, $file) or die "can not open $file $!\n";
$firstline = <FILE>;
my @check = split("\t",$firstline);
print "check: $check[$onecount]\t$check[$twocount]\t$check[$threecount]\n";
my $outfiletmp = 'tmp'.$outfile;
open(OUT, ">$outfiletmp");
while (<FILE>){
	my $line = $_;
	chomp $line;
	my @int = split("\t",$line);
	my $firstallele = $int[$onecount];
	my $secondallele = $int[$twocount];
	my $thirdallele = $int[$threecount];
	if ($firstallele =~ /[ACGT]/ && $secondallele =~ /[ACGT]/ && $thirdallele =~ /[ACGT]/){
		unless ($firstallele eq $secondallele && $firstallele eq $thirdallele){
			if ($firstallele eq $thirdallele){
				print OUT "$int[0]\t$int[1]\t$firstallele\t$secondallele\t$thirdallele\t-1\n";
			}
			elsif ($firstallele eq $secondallele){
				print OUT "$int[0]\t$int[1]\t$firstallele\t$secondallele\t$thirdallele\t1\n";
			}
			else {
				print OUT "$int[0]\t$int[1]\t$firstallele\t$secondallele\t$thirdallele\t0\n";
			}
		}
	}
}
close(FILE);
close(OUT);

`cat $outfiletmp | sed 's/Sscrofa10_X/Sscrofa10_19/' | sed 's/Sscrofa10_Y/Sscrofa10_20/' | sed 's/Sscrofa9_MT/Sscrofa10_21/' | sed 's/Sscrofa10_//' | sort -k1 -n -k2 -n  >$outfile.txt`;
`rm $outfiletmp`;
my $newfile = $outfile.'.txt';
open(FILE, $newfile) or die "can not open $newfile $!\n";
open(OUT,">$outfilebins") or die "can not open $outfilebins : $!\n";
my $chrom;
my $bin =$binsize;
my $value =0;
$count=0;
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
`rm $newfile`;
open(RIN, ">Rin$outfile.txt");
print RIN 'chroms <- c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19)'."\n";
print RIN 'sschroms <- c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,"X")'."\n";
print RIN 'LW2 <- read.table("'.$outfilebins.'")'."\n";
print RIN 'jpeg("'.$outfile.'.jpg",height=1500,width=1500)'."\n";
print RIN 'par(mfrow=c(4,5))'."\n";
print RIN 'for (i in chroms) {plot(LW2$V2[LW2$V1==i],LW2$V4[LW2$V1==i],type="h",main = paste("'.$one.' Sscrofa10",sschroms[i],sep="_"),ylab = "'.$three.' <--> '.$two.'",xlab = "pos. in chrom.", cex.main=2, cex.lab =1.5, col = "dark red",ylim=c(-1,1))}'."\n";
print RIN 'dev.off()'."\n";
print RIN 'q()'."\n";
close(RIN);
`R --no-save <Rin$outfile.txt >Rout_$outfile`;
`rm Rout_$outfile`;
`rm Rin$outfile.txt`; 
exit;
