#!/usr/bin/perl
use strict;
use warnings;
my $tempdir = $ARGV[0];
chomp $tempdir;
open(STDERR, ">$tempdir/errorlog/myprogram2.error") or die "cannot open error file: myprogram.error:$!\n";
use DBI;
open(LARGE, ">$tempdir/temp/seq_large_from46.txt"); 
open(SMALL, ">$tempdir/temp/seq_small_from46.txt");
#open(CONTROLE, ">>controle.txt");
# ensembl modules
#my $path = "C:/Program Files/DevKvl";
use lib "/usr/bin/kvl_lib/EnsEMBL46";
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
my $reg_conf46 = "/usr/bin/kvl_lib/ensembl_init_46";

open (TO_46, "$tempdir/temp/to_46.txt");
my @input = <TO_46>;

close (TO_46);
my $species = $input[0];
my $transcript_id  = $input[1];
my $chromosome = $input[2];
my $mirna_start = $input[3];
my $mirna_end = $input[4];

chomp $species;
chomp $transcript_id;
chomp $chromosome;
chomp $mirna_start;
chomp $mirna_end;

#print "$chromosome\n$mirna_start\n$mirna_end\n";

Bio::EnsEMBL::Registry->load_all($reg_conf46);
#print "gaat het hier al mis?\n";
my $slice_adaptor46 = Bio::EnsEMBL::Registry->get_adaptor($species,'core','Slice');
my $transcript_adaptor46 = Bio::EnsEMBL::Registry->get_adaptor($species,'core','Transcript');
my $transcript = $transcript_adaptor46->fetch_by_stable_id($transcript_id);
#print "of misschien hier?\n$chromosome\n";


my $slice46 = $slice_adaptor46->fetch_by_region('chromosome', $chromosome, ($mirna_start-100), ($mirna_end+100));
my $sequence_large = $slice46 ->seq();

# print "hier in elk geval?\n";

$slice46 = $slice_adaptor46->fetch_by_region('chromosome', $chromosome, $mirna_start, $mirna_end);
my $sequence_small = $slice46 ->seq();

# print "hier in elk geval-2?\n";
my $gene_start="";
my $gene_end="";
print SMALL $sequence_small. "\n";
print LARGE $sequence_large. "\n";
if (($transcript)){
	# print "ok, ok wat gaat hier dan mis?\n";
	#my $strand = $transcript ->strand();
	# print "ok, ok wat gaat hier dan mis-2?\n";
	#print $strand."\n";
	#$gene_start = $transcript ->start();
	#$gene_end = $transcript ->end();
	#print CONTROLE "\nIN sub PROGRAM!\n$mirna_start : $mirna_end\t$gene_start : $gene_end\n";
	#print "\nIN sub PROGRAM!\n$mirna_start : $mirna_end\t$gene_start : $gene_end\n";
}
#print CONTROLE "\nIN sub PROGRAM!\nTranscript $transcript_id start : end in 40 $gene_start : $gene_end\n";
#print "\nIN sub PROGRAM!\nTranscript $transcript_id start : end in 40 $gene_start : $gene_end\n";
#close (CONTROLE);
close (SMALL);
close (LARGE);
exit;
