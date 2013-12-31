use strict;
use warnings;
open(STDERR, ">myprogram.error") or die "cannot open error file: myprogram.error:$!\n";
use DBI;

print "=======================================================\n";
print "This program has the option to run in silent mode for\n";
print "job processing on the lx servers. Type anything (+enter)\n";
print "but 'silent' on the next prompt to run verbose mode\n";
print "Running mode: ";
my $running_mode = <>;
chomp $running_mode;
if ($running_mode eq 'silent'){
	print "\n\nRun starts at " . scalar (localtime) ."\n\n";
	open STDOUT, ">tmp";
}

# ensembl modules
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Data::Dumper;

# Ensemble configuration file
my $reg_conf = "ensembl_init_new";
Bio::EnsEMBL::Registry->load_all($reg_conf);
my $database = 'kvl';
my $server = 'localhost';
my $user = 'root';
my $passwd = 'chicken';
my $ref_organism = 'human';

my $gene_adaptor = Bio::EnsEMBL::Registry->get_adaptor($ref_organism,'core','Gene');

my $kvl = DBI->connect("dbi:mysql:$database:$server", $user, $passwd);

my $query = "delete from hugo_ensembl;";

my $sql = $kvl->prepare($query);
$sql->execute();

$query = "select s.approved_symbol,s.entrez_gene_id from hgnc_simple as s left join hugo_ensembl as h using (approved_symbol) where h.ensembl_gene_id is NULL;";

$sql = $kvl->prepare($query);
$sql->execute();

my $eerste=0;
my $tweede=0;

while (my $row = $sql->fetchrow_arrayref) {
	my $row2 = join("\t", @$row);
	my @row2array = split ("\t",$row2);
	my $hgnc_name = $row2array[0];
	my $entrez_gene_id = $row2array[1];

	print $hgnc_name . "\t" . $entrez_gene_id ."\t";
	#print STDERR $hgnc_name . "\t" . $entrez_gene_id ."\t";
	my $gelukt = insert($kvl,$gene_adaptor,$hgnc_name);
	if ($gelukt) {++$eerste;}
	
	print "--------------\n";
	
}

$sql = $kvl->prepare($query);
$sql->execute();

while (my $row = $sql->fetchrow_arrayref) {
	
	
	my $row2 = join("\t", @$row);
	my @row2array = split ("\t",$row2);
	my $hgnc_name = $row2array[0];
	my $entrez_gene_id = $row2array[1];
	
	print $hgnc_name . "\t" . $entrez_gene_id ."\t";
	#print STDERR $hgnc_name . "\t" . $entrez_gene_id ."\t";
	my $ref = $entrez_gene_id;
	
	my $gelukt = update($kvl,$gene_adaptor,$hgnc_name, $ref);
	if ($gelukt) {++$tweede;}
	
	print "--------------\n";
	
}

$kvl->disconnect;

print "There are $eerste ensembl_gene_id entries based on HGNC symbol\n";
print "There are $tweede ensembl_gene_id entries based on entrez_gene_id\n";

if ($running_mode eq 'silent'){
		close (STDOUT);
}
print "\n\nRun ends at " . scalar (localtime) ."\n\n";

close (STDERR);
exit;

sub check {
	my ($kvl, $ref) = @_;
	my $query = "select s.approved_symbol,s.entrez_gene_id,h.ensembl_gene_id from hgnc_simple as s inner join hugo_ensembl as h using (approved_symbol) where h.approved_symbol = ('$ref');";

	my $sql = $kvl->prepare($query);
	$sql ->execute();
	
	while (my $row = $sql->fetchrow_arrayref) {
		my $row2 = join("\t", @$row);
		my @row2array = split ("\t",$row2);
		my $hgnc_name = $row2array[0];
		my $entrez_gene_id = $row2array[1];
		my $ensembl_gene_id = $row2array[2];
		print "now in db: ".$hgnc_name."\t".$entrez_gene_id."\t".$ensembl_gene_id."\n";
	}
}

sub update {
	my $gelukt = "";
	my ($kvl,$gene_adaptor, $hgnc_id, $entrez_gene_id)= @_;

	if (($entrez_gene_id)){
	
		my $query = "update hugo_ensembl set ensembl_gene_id = ? where approved_symbol = ('$hgnc_id');";

		my $sql = $kvl->prepare($query);
	
		my @genes = @{$gene_adaptor->fetch_all_by_external_name($entrez_gene_id)};
	
		if ((@genes)){
			foreach my $gene (@genes){
				my $gene_id = $gene -> stable_id();
				print $gene_id."\n";
				unless ($gelukt eq 'yes'){
					if (($gene_id)){
						
						$sql -> execute($gene_id);
						check($kvl,$hgnc_id);
						$gelukt = 'yes';
					}
					
				}
				else {
					my $query2 = "insert into hugo_ensembl values (?,?,NULL)";
					my $sql2 = $kvl->prepare($query2);
						
					$sql2 -> execute($hgnc_id,$gene_id);
					check($kvl,$hgnc_id);
					my $gelukt = 'yes';
				}
			}
		}
	}

	return $gelukt;
}

sub insert {
	my $gelukt = "";
	my ($kvl,$gene_adaptor,$hgnc_id)= @_;

	if (($hgnc_id)){
	
		my $query = "insert into hugo_ensembl values (?,?,NULL)";
				
		my $sql = $kvl->prepare($query);
	
		my @genes = @{$gene_adaptor->fetch_all_by_external_name($hgnc_id)};
	
		if ((@genes)){
			foreach my $gene (@genes){
				my $gene_id = $gene -> stable_id();
				print $gene_id."\n";
				my $sql = $kvl->prepare($query);
						
				$sql -> execute($hgnc_id,$gene_id);
				check($kvl,$hgnc_id);
				my $gelukt = 'yes';

			}
		}
		else {
			my $gene_id;
			my $sql = $kvl->prepare($query);
						
			$sql -> execute($hgnc_id,$gene_id);
			check($kvl,$hgnc_id);
			my $gelukt = 'yes';
		}
	}

	return $gelukt;
}
