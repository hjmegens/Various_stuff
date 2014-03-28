#!/usr/bin/perl

use strict;
use warnings;

# Make connection with MySQL database
open(STDERR, ">myprogram.error") or die "cannot open error file: myprogram.error:$!\n";
use DBI;

my $database = 'pig_hapmap2';
my $server = 'localhost';
my $user = 'root';
#my $passwd = 'mysqlscomp1095@1234';
my $passwd = 'chicken';

my $homologs = DBI->connect("dbi:mysql:$database:$server", $user, $passwd);
my $sqlinit = $homologs->prepare("show tables");
$sqlinit->execute();
while (my $row = $sqlinit->fetchrow_arrayref) {
	print join("\t", @$row), "\n";
}

my $flag = 0;
my $table;
my @tables;
my $sql;
my $numfields=0;
while(<>) {
	
	chomp;
    # skip blank lines
    if(/^\s*$/) {
        next;

    # begin new table
    }elsif(/^TABLE\t(\w+)/) {
	    $numfields=0;
        $flag = 1;
        $table = $1;
	push(@tables, $table);
	# Delete all rows in database table
	my $droprows = $homologs->prepare("delete from $table");
	$droprows->execute();

    # get fieldnames, prepare SQL statement
    } elsif($flag == 1) {
        $flag = 2;
        my @fieldnames = split;
	$numfields = (@fieldnames);
	
	my $query = "insert into  $table (" . join(",", @fieldnames) . ") values (" . "?, " x (@fieldnames-1) . "?)";
	$sql = $homologs->prepare($query);

    # get row, execute SQL statement
    } elsif($flag == 2) {
	#s/ /_/g;
	#s/#/_/g;
	#s/__/_/g;
        my @fields = split "\t";
	
	my $numfieldsdata = (@fields);
	#print STDERR "\n$numfields = ";
	#print STDERR (scalar $numfieldsdata)." = ";
	while ($numfieldsdata < $numfields){
		push (@fields, '');
		$numfieldsdata++;
	}
	#print STDERR (scalar @fields)."\n";
	$sql->execute( @fields);
    }
}

# Check if tables were updated

foreach my $table (@tables) {
	print "\nTable: $table\n\n";
	my $query = "select * from $table";
	my $sql = $homologs->prepare($query);
	$sql->execute();

	while (my $row = $sql->fetchrow_arrayref) {
	    print join("\t", @$row), "\n";
	}
}

# Break connection with MySQL database

$homologs->disconnect;

close (STDERR);
exit;

