#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Std;
my %opts = ();
$opts{d}= 't.db';
getopt('d', \%opts);
my $database = $opts{d};

# Make connection with MySQL database
open(STDERR, ">myprogram.error") or die "cannot open error file: myprogram.error:$!\n";
use DBI;

my $db = DBI->connect("dbi:SQLite:dbname=$database", "", "");
#my $sqlinit = $db->prepare('.tables');
#$sqlinit->execute();
#while (my $row = $sqlinit->fetchrow_arrayref) {
#	print join("\t", @$row), "\n";
#}

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
		my $droprows = $db->prepare("delete from $table");
		$droprows->execute();
	
	    # get fieldnames, prepare SQL statement
    } 
	elsif($flag == 1) {
        $flag = 2;
        my @fieldnames = split;
		$numfields = (@fieldnames);
		
		my $query = "insert into  $table (" . join(",", @fieldnames) . ") values (" . "?, " x (@fieldnames-1) . "?)";
		$sql = $db->prepare($query);

    # get row, execute SQL statement
    } 
	elsif($flag == 2) {
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
	print "\nTable: $table\n";
	my $query = "select * from $table";
	my $sql = $db->prepare($query);
	$sql->execute();

	while (my $row = $sql->fetchrow_arrayref) {
	    print join("\t", @$row), "\n";
	}
}

# Break connection with MySQL database

$db->disconnect;

close (STDERR);
exit;

