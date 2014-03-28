#!/usr/bin/perl -w
use strict;
use warnings;
use DBI;
use PerlIO::gzip;
use Getopt::Std;
my %opts = ();
$opts{o}= 'out.txt';
getopt('o', \%opts);
my $outfile = $opts{o};

my $database = 'pig_hapmap2';
my $server = 'localhost';
my $user = 'anonymous';
my $pig_hapmap = DBI->connect("dbi:mysql:$database:$server", $user);
my @specimens = fetch_specimens($pig_hapmap);

open (my $out,">:gzip", $outfile) or die "could not open file for writing! $! \n";
print $out "snp,dna_name,topallele1,topallele2,fwallele1,fwallele2,gcscore\n";

foreach my $specimen (@specimens){
	print "$specimen\n";
	my $query = "select * from allgenotypes16 where dna_name = '$specimen'";
	my $sql = $pig_hapmap->prepare($query);
	$sql-> execute();
	while (my $row = $sql->fetchrow_arrayref) {
		my ($snp,$sample,$allele1top,$allele2top,$allele1fw,$allele2fw,$gcscore) = @$row;
		print $out "$snp,$sample,$allele1top,$allele2top,$allele1fw,$allele2fw,$gcscore\n";
	}
}
close ($out);

sub fetch_specimens{
	my ($pig_hapmap)=@_;
	my $query = "select dna_name from sample_sheet8";
	my $sql = $pig_hapmap->prepare($query);
	$sql->execute();
	my @specimens1 = ();
	while (my $row = $sql->fetchrow_arrayref) {
		my $spec = join("\t", @$row);
		push (@specimens1 , $spec); 
	}

	return @specimens1;
}

