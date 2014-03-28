#!/perl/bin/perl -w
use strict;
use warnings;
use DBI;
open(STDERR, ">myprogram.error") or die "cannot open error file: myprogram.error:$!\n";

use Getopt::Std;
my %opts = ();
$opts{f}="myfile"; # default is 0.5mb
getopt('f', \%opts);
my $basename = $opts{f};

my $database = 'pig_hapmap2';
my $server = 'localhost';
my $user = 'anonymous';

my $pig_hapmap = DBI->connect("dbi:mysql:$database:$server", $user);
open (TABLE1, "$basename.mdist");
open (TABLE2, "$basename.ped");
open (INFO, ">infofile_$basename.txt");
print INFO "index\tlabel\torig_dna_name\tdna_name\tindiv_name\tpop_name\talternative_pop_name\tbreed_name\tfamilystatus\tpurpose\tmother\tfather\tfull_breed_name\tcontinent_origin\tcountry_origin\n";
open (MATRIX, ">distmatrix_$basename.txt");
my $index = 0;
while (<TABLE1>){
	++$index;
	my $line1 = $_;
	my $line2 = <TABLE2>;
	my @intarray = split("\t",$line2);
	my $label = $intarray[1];
	my $origlabel = $label;
	$label =~ s/#//g;
	$label =~ s/ //g;
	$label =~ s/_//g;
	
	while (length $label <10) {
		$label = join ('',$label," ");
	}
	while (length $label >10) {
			
		my @naam = split ('',$label);
		shift (@naam);
		$label = join ('',@naam);
	}
	my $query = "select * from sample_sheet8 where alternative_dna_name = ('$origlabel')";
	my $sql = $pig_hapmap->prepare($query);
	$sql->execute();
	my @info = ();
	while (my $row = $sql->fetchrow_arrayref) {
		my $inf = join("\t", @$row);
		#print join("\t", @$row), "\n";
		push (@info , $inf); 
	}
	print INFO "$index\t$label\t$origlabel\t$info[0]\n";
	while (length $index <10) {
		$index = join ('',$index," ");
	}

	print (MATRIX "$index $line1");
}
close(INFO);	
close(TABLE1);
close(TABLE2);
close(MATRIX);
close (STDERR);

# exit the program
exit;
