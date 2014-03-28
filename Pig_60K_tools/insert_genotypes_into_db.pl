#!/usr/bin/perl -w
use strict;
use warnings;
open(STDERR, ">myprogram.error") or die "cannot open error file: myprogram.error:$!\n";
use DBI;
use Getopt::Std;
my %opts = ();
getopt('f', \%opts);
my $file = $opts{f};

my $database = 'pig_hapmap2';
my $server = 'localhost';
my $user = 'root';
my $passwd = 'chicken';

my $hapmap = DBI->connect("dbi:mysql:$database:$server", $user, $passwd);

my $query = "insert into allgenotypes16 values (?,?,?,?,?,?,?);";

open(HM,$file) or die "can not open file $!\n";
my $counter = 1;
my $firstline = <HM>;
print $firstline;
while (<HM>){
		my $line = $_;
		chomp $line;
		my @int = split("\t",$line);
		my $snp = $int[0];
		my $indiv = $int[1];
		my $top1 = $int[4];
		my $top2 = $int[5];
		my $fwd1 = $int[2];
		my $fwd2 = $int[3];
		my $ab1 = $ab[4];
        my $ab2 = $int[5];
		my $gc = $int[8];
		my $sql= $hapmap->prepare($query);
						
		$sql -> execute($snp,$indiv,$top1,$top2,$fwd1,$fwd2,$gc);
		if ($counter < 20){
			print "$snp\t$indiv\t$top1\t$top2\t$fwd1\t$fwd2\t$gc\n";
		}
	
		++$counter;
}
$hapmap->disconnect;
exit;
