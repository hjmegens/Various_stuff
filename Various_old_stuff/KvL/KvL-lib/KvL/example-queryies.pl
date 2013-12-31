use strict;
use warnings;
open(STDERR, ">myprogram3.error") or die "cannot open error file: myprogram.error:$!\n";
use DBI;
#open(OUT, ">check2.txt");
# ensembl modules
use Data::Dumper;
use Bio::SearchIO;
use LWP::Simple;

my $database = 'kvl';
my $server = 'localhost';
my $user = 'root';
my $passwd = 'chicken';
my $db = "gene";
my $query;
my $how = what();
my $search = ask_gene();
if ($how == 1){
	$query = "select hgnc_simple.approved_symbol,hprd_tissues.tissue from hprd_tissues inner join hgnc_simple using (entrez_gene_id) where hprd_tissues.tissue like '\%$search%'";
}
if ($how == 2){
	$query = "select hgnc_simple.approved_symbol,hprd_tissues.tissue from hprd_tissues inner join hgnc_simple using (entrez_gene_id) where hgnc_simple.approved_symbol = '$search'";
}

my $kvl = DBI->connect("dbi:mysql:$database:$server", $user, $passwd);
my $teller=0;

my $sql = $kvl->prepare($query);
$sql->execute();


while (my $row = $sql->fetchrow_arrayref) {
	++$teller;
	my $int = join("\t", @$row);
		
	print $int."\n";
}
print "number of hits: $teller\n";
exit;

sub ask_gene {
	my $rc = "";
	print "your query: ";
	$rc = <>;
	chomp $rc;
  	return $rc;
  	
}

sub what {	
	my $rc = "";
	do {
		print "How do you want to query? ";
		print "\n(1) tissue\n(2) gene\n";
		$rc = <>;
		#$rc = "\n".$rc;
	}until ($rc =~ /^[12]\n/);
	chomp $rc;
  	return $rc;
}

