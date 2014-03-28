#!/usr/bin/perl

use strict;
use warnings;

# Make connection with MySQL database
use DBI;

my $database = 'pig_hapmap2';
my $server = 'localhost';
my $user = 'anonymous';

my $homologs = DBI->connect("dbi:mysql:$database:$server", $user);
while(<>) {
	
	chomp $_;
	my $sample = $_;
	my $query = "select progeny2hjm.Unique_sample_id,dna_name,id_4 from progeny8_ss inner join progeny2hjm using (Unique_sample_id) where id_4 like '%$sample'";
	my $sql = $homologs->prepare($query);
	$sql->execute();
	my $flag = 0;
	while (my $row = $sql->fetchrow_arrayref) {
	    print join("\t", @$row), "\n";
		$flag = 1;
	}
	unless ($flag > 0){
            print "$sample not found\n";
    }


}

# Break connection with MySQL database

$homologs->disconnect;

exit;

