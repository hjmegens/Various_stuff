#!/usr/bin/perl -w
use strict;
use warnings;
use Getopt::Std;
my %opts = ();
$opts{f}='infile';
$opts{r}='results.txt';
$opts{b}='myblastdb';
getopt('frb', \%opts);
my $file = $opts{f};
my $resfile = $opts{r};
my $blastdb = $opts{b};
if ($blastdb eq 'myblastdb'){ 
	die "no blastdb defined!\n";
}
open (SNPS, $file) or die "no such infile: $file $!\n";

open(RES, ">$resfile") or die "can not open file $!\n";
my $name = <SNPS>;
my $seq = '';
chomp $name;
while (<SNPS>){
	my $line = $_;
	chomp $line;
	my @int = split("\t", $line);
	my $seq = $int[4];
	$seq =~ s/^N+//g;
	$seq =~ s/N+$//g;
	my ($seq1,$seq2)=split(/\[.+\]/,$seq);
	#print "$seq1\t$seq2\n"
	do_blast($line,$seq1,$seq2,$blastdb);
}
#do_blast($name,$seq);
close(RES);
exit;

sub do_blast {
	my ($info,$seq1,$seq2,$blastdb) = @_;
	my $seq = $seq1.'N'.$seq2;
	open (OUT, ">tempfasta.fa");
	print OUT ">seq\n$seq";
	close(OUT);
	`blastn -query tempfasta.fa -db $blastdb -outfmt=6 -num_threads=40 -perc_identity=97 >tempout.txt`;
	open(OUT, "tempout.txt");
	my @lines = <OUT>;
	close(OUT);
	if (@lines){
		my $goodmatch = 'no';
		foreach my $line (@lines){
			chomp $line;
			$goodmatch = resolve_match($info,$seq1,$seq2,$line,$goodmatch);
		}
	}
	else {
		print RES "$info\tno match\n";
	}
}
sub resolve_match {
	my ($rename,$seq1,$seq2,$line,$goodmatch) = @_;
	my $length1 = length $seq1;
	my $length2 = length $seq2;
	my $length = $length1 + $length2 + 1;
        my @int = split("\t",$line);
        my $seqname = $int[0];
        my $chrom = $int[1];
        my $match = $int[2];
        my $matchstartq = $int[6];
        my $matchendq = $int[7];
        my $matchlength = $matchendq - $matchstartq + 1;
        my $matchstartref = $int[8];
        my $matchendref = $int[9];

        my $matchdif =  $length-$matchlength;
        if ($matchdif <2 && $match >97){
	     $goodmatch = 'yes';
             print "$rename\t$line\n";
             my $startref=$matchstartref;
             my $endref=$matchendref;
             my $strandref=1;

             if ($matchstartref > $matchendref){
                    $startref = $matchendref;
                    $endref = $matchstartref;
                    $strandref=-1;
             }
	  my $pos =0;
	  if ($strandref==-1){
	  	$pos = $matchstartref - $length1 + $matchstartq - 1;
	  }
	  else {
	  	$pos = $matchstartref + $length1 - $matchstartq + 1;
	  }
		
          print RES "$rename\t$matchstartq\t$matchendq\t$chrom\t$startref\t$endref\t$strandref\t$matchdif\t$match\t$matchlength\t$pos\n";
        }
        elsif ($goodmatch eq 'no') {
             print RES "$rename\tnot a good match: $chrom;$matchstartref;$matchendref;$matchdif;$match\n";
	     $goodmatch = 'yes';
        }
	return $goodmatch;
}
