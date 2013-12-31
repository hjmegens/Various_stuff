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
open (EXONS, $file) or die "no such infile: $file $!\n";

open(RES, ">$resfile") or die "can not open file $!\n";
print RES "Ensembl_Gene_id\tEnsembl_Exon_id\tchrom_b9\texon_start_b9\texon_end_b9\tstrand_b9\texon_in_gene_b9\tgene_description\tgene_name\tgene_start_b9\tgene_end_b9\tchrom_b10\texon_start_b10\texon_end_b10\tstrand_b10\tlength_diff\n";
my $name = <EXONS>;
my $seq = '';
chomp $name;
while (<EXONS>){
	my $line = $_;
	chomp $line;
	if ($line =~ m/>/){
		do_blast($name,$seq,$blastdb);
		$name = $line;
		$seq = '';
	}
	else {
		$seq = $seq . $line;
	}
}
do_blast($name,$seq);
close(RES);
exit;

sub do_blast {
	my ($name, $seq,$blastdb) = @_;
	open (OUT, ">tempfasta.fa");
	print OUT "$name\n$seq";
	close(OUT);
	`blastn -query tempfasta.fa -db $blastdb -outfmt=6 -num_threads=40 -perc_identity=95 >tempout.txt`;
	open(OUT, "tempout.txt");
	my @lines = <OUT>;
	close(OUT);
	my $rename = $name;
	$rename =~ s/>//;
	$rename =~ s/\|/\t/g;
	if (@lines){
		foreach my $line (@lines){
			chomp $line;
			resolve_match($rename,$seq,$line);
		}
	}
	else {
		print RES "$rename\tno match\n";
	}
}
sub resolve_match {
	my ($rename,$seq,$line) = @_;
	my $length = length $seq;
        my @int = split("\t",$line);
        my $seqname = $int[0];
        my $chrom10 = $int[1];
        my $match = $int[2];
        my $matchstart = $int[6];
        my $matchend = $int[7];
        my $matchlength = $matchend - $matchstart + 1;
        my $matchstart10 = $int[8];
        my $matchend10 = $int[9];

        my $matchdif =  $length-$matchlength;
        print "$name\t$line\n";
        if ($matchdif <2 && $match >99){
             my $start10=$matchstart10;
             my $end10=$matchend10;
             my $strand10=1;

             if ($matchstart10 > $matchend10){
                    $start10 = $matchend10;
                    $end10 = $matchstart10;
                    $strand10=-1;
             }

             print RES "$rename\t$chrom10\t$start10\t$end10\t$strand10\t$matchdif\t$match\t$matchlength\n";
        }
        else {
             print RES "$rename\tnot a good match: $matchdif;$match\n";
        }
}
