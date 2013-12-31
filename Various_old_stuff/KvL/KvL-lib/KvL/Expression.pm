package Expression;

use strict;
use warnings;
use DBI;
use Data::Dumper;
use Bio::SearchIO;
use LWP::Simple;

sub tissue_list {
	my ($species)=@_;
	my $database = 'kvl';
	my $server = 'localhost';
	my $user = 'anonymous';
	my $db = "gene";
	
	my $kvl = DBI->connect("dbi:mysql:$database:$server", $user);
	my $teller=0;
	my @tissues=();
	
	my $query = "describe $species"."_expression_profiles";
	my $sql = $kvl->prepare($query);
	$sql->execute();
	my $query1;
	while (my $row = $sql->fetchrow_arrayref) {
		my @row2array = @$row;
		my $tissue = $row2array[0];
		push(@tissues,$tissue)
	}
	shift @tissues;
	return @tissues;
}



sub expression_tissue {
	my ($species,$tissueref,$conditional,$tpm)=@_;
	my @tissue_search = @$tissueref;
	my @return = ();
	my $database = 'kvl';
	my $server = 'localhost';
	my $user = 'anonymous';
	my $db = "gene";
	
	my $kvl = DBI->connect("dbi:mysql:$database:$server", $user);
	my $teller=0;
	my @tissues=();

	my @entrez_gene_ids = all_tissues_to_gen_search(\@tissue_search, $kvl,$species,$conditional,$tpm);
			
	print "number of ids for @tissue_search: ".(@entrez_gene_ids)."\n";
	@return=();
	foreach my $entrez_gene_id (@entrez_gene_ids){
		my @values;
		foreach my $tissue (@tissue_search){
			my $value=entrez_gene_id_to_tissue($species,$entrez_gene_id,$tissue,$kvl);
			push (@values,$value);
		}
		my $query = "select ncbi_symbol,ncbi_gene_description from ncbi_gene_description where entrez_gene_id = '$entrez_gene_id'";
		my $ncbi_symbol;
		my $ncbi_gene_description;
		my $sql = $kvl->prepare($query);
		$sql->execute();
		while (my $row = $sql->fetchrow_arrayref) {
			my @row2array = @$row;
			$ncbi_symbol = shift @row2array;
			$ncbi_gene_description = shift @row2array;
		}
		if ($ncbi_symbol){
			print "$ncbi_symbol\t(genid: $entrez_gene_id) ==> ";
			foreach my $value (@values){
				print "\t$value";
			}
			push(@return,$ncbi_symbol);
			print "\n";
			++$teller;
		}
	}
	return @return;
}
sub expression_gene {

	my ($species,$search)=@_;
	my $database = 'kvl';
	my $server = 'localhost';
	my $user = 'anonymous';
	my $db = "gene";
	my @expr_profiles=();
	my @expr_hprd=();
	
	my $kvl = DBI->connect("dbi:mysql:$database:$server", $user);
	my $species_e = species($species);
	my @tissues = tissue_list($species_e);
	
	#my $query = "select * from ncbi_gene_description inner join $species_e"."_expression_profiles using (entrez_gene_id) where ncbi_symbol = '$search'";
	my $query = "select * from $species_e"."_expression_profiles where entrez_gene_id = '$search'";

	my $sql = $kvl->prepare($query);
	$sql->execute();
	while (my $row = $sql->fetchrow_arrayref) {
		my @row2array = @$row;
		my $countarray = 0;
		my $entrez_gene_id = shift @row2array;
		foreach my $element (@row2array){
			push (@expr_profiles, "$tissues[$countarray]\t$element");
			++$countarray;
		}	
	}
	#$query = "select hgnc_simple.approved_symbol,hprd_tissues.tissue from hprd_tissues inner join hgnc_simple using (entrez_gene_id) where hgnc_simple.approved_symbol = '$search'";
	$query = "select tissue from hprd_tissues where entrez_gene_id = '$search'";
	$sql = $kvl->prepare($query);
	$sql->execute();
	while (my $row = $sql->fetchrow_arrayref) {
		my @row2array = @$row;
		foreach my $element (@row2array){
			push (@expr_hprd, $element);
		}	
	}
	return (\@expr_profiles,\@expr_hprd);

}



sub ask_gene {
	my $rc = "";
	print "your query: ";
	$rc = <>;
	chomp $rc;
  	return $rc;
  	
}
sub logical {	
	my $rc = "";
	do {
		print "How do you want to combine tissue search? (AND-OR-NOT)";
		print "\n(1) AND\n(2) OR\n(3) NOT\n";
		$rc = <>;
		#$rc = "\n".$rc;
	}until ($rc =~ /^[123]\n/);
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
sub unique_array_elements {
	my @sub_return = @_;
	my @return=();
	my %seen = ();
	foreach my $item (@sub_return) {
		unless ($seen{$item}) {
	        # if we get here, we have not seen it before
	        	$seen{$item} = 1;
	        	push(@return, $item);
		}
	}
	return @return;
}

sub unique_first_array_elements {
	my ($refA,$refB) = @_;
	my @arrayA = @$refA;
	my @arrayB = @$refB;
	my %seen = ( );                    # lookup table to test membership of B
	my @aonly = ( );                   # answer

	# build lookup table
	foreach my $item (@arrayB) { $seen{$item} = 1 }

	# find only elements in @A and not in @B
	foreach my $item (@arrayA) {
	    unless ($seen{$item}) {
	        # it's not in %seen, so add to @aonly
	        push(@aonly, $item);
	    }
	}
	return(@aonly);
}

sub shared_array_elements {
	my ($refA,$refB) = @_;
	my @arrayA = @$refA;
	my @arrayB = @$refB;
	my %seen = ();                    # lookup table to test membership of B
	my @both = ();                   # answer

	# build lookup table
	foreach my $item (@arrayB) { $seen{$item} = 1 }

	# find only elements in @A and not in @B
	foreach my $item (@arrayA) {
	    if ($seen{$item}) {
	        # it's not in %seen, so add to @aonly
	        push(@both, $item);
	    }
	}
	return(@both);
}

sub what_tissue {	
	my $rc = "";
	my $counter = 0;
	my @what = @_;
	my @numbers=();
	my @tissues;
	do {
		print "How do you want to find your genes?\n";
		my $next = 0;
		foreach my $element (@what){
			print "(".($next+1).") $what[$next]\n";
			++$next;
		}
		$rc = <>;
		chomp $rc;
		my @rcs = split(/\s/,$rc);
		foreach $rc (@rcs){
			unless ($rc =~ /^\d+$/){
				print "$rc is not a number!!!\n";
				++$counter;
				if ($counter > 4){
					if ((@numbers)<1){
						push(@numbers,'1');
					}
				}
				else {$rc = 1000;}
			}
	
			if ($rc =~ /^\d+$/){
				#print "this is a number\t";
				if ($rc <= (@what)){
					push (@numbers,$rc);
					#print "and it is valid!!\n"
				}
				else {
					++$counter;	
					#print "but it is NOT valid!!\n";
					if ($counter > 4){
						if ((@numbers)<1){
							push(@numbers,'1');
						}
					}
				}
			}
		}

	}until ((@numbers)>0);

	foreach my $number (@numbers){
  		push (@tissues, $what[$number-1]);
	}
  	return @tissues;
}

sub all_tissues_to_gen_search{
	my ($tissueref,$kvl,$species,$conditional,$tpm) = @_;
	my @tissuesearch = @$tissueref;
	
	my $firsttissue = shift(@tissuesearch);

	my @entrez_gene_ids = tissue_to_gen_search($firsttissue,$kvl,$species,$tpm);
	foreach my $tissue (@tissuesearch){
		@entrez_gene_ids = conditionals(\@entrez_gene_ids,$tissue,$conditional,$kvl,$species,$tpm);
	}
	return (@entrez_gene_ids);
	
}

sub tissue_to_gen_search{
	my ($tissuesearch,$kvl,$species,$tpm) = @_;
	my @return=();
		

	#$query = "select ncbi_gene_description.entrez_gene_id,ncbi_symbol,ncbi_gene_description,(juvenile/adult) from ncbi_gene_description inner join $species"."_expression_profiles using (entrez_gene_id) where ((juvenile > (adult*10)) and (adult > 0)) order by (juvenile/adult) desc";
	#$query1 = "select ncbi_gene_description.entrez_gene_id,ncbi_symbol,ncbi_gene_description,(juvenile/adult) from ncbi_gene_description inner join $species"."_expression_profiles using (entrez_gene_id) where $tissuesearch > 10 order by ($tissuesearch) desc";
	my $query = "select entrez_gene_id,$tissuesearch from $species"."_expression_profiles where $tissuesearch > $tpm order by ($tissuesearch) desc";
	my $sql = $kvl->prepare($query);
	$sql->execute();
	while (my $row = $sql->fetchrow_arrayref) {
		my @row2array = @$row;
		my $entrez_gene_id = shift @row2array;
		my $tissuevalue = shift @row2array;
		push(@return,$entrez_gene_id);
	}
	return (@return);
	
}

sub entrez_gene_id_to_tissue{
	my ($species,$entrez_gene_id,$tissue,$kvl)=@_;
	my $query="select $tissue from $species"."_expression_profiles where entrez_gene_id = '$entrez_gene_id'";
	my $sql = $kvl->prepare($query);
	$sql->execute();
	my $row = $sql->fetchrow_arrayref;
	my @row2array = @$row;
	my $value = shift @row2array;
	return $value;
}

sub conditionals {
	my ($entrez_gene_id_ref,$tissue,$conditional,$kvl,$species,$tpm)=@_;
	my @entrez_gene_ids = @$entrez_gene_id_ref;
	if ($conditional == 1){
		my @entrez_gene_ids_previous = @entrez_gene_ids;
		@entrez_gene_ids = tissue_to_gen_search($tissue, $kvl,$species,$tpm);
		@entrez_gene_ids = shared_array_elements(\@entrez_gene_ids,\@entrez_gene_ids_previous);
	}
	if ($conditional == 2){
		my @entrez_gene_ids_previous = @entrez_gene_ids;
		@entrez_gene_ids = tissue_to_gen_search($tissue, $kvl,$species,$tpm);
		push (@entrez_gene_ids,@entrez_gene_ids_previous);
		@entrez_gene_ids = unique_array_elements(@entrez_gene_ids);
	}
	if ($conditional == 3){
		my @entrez_gene_ids_previous = @entrez_gene_ids;
		@entrez_gene_ids = tissue_to_gen_search($tissue, $kvl,$species,$tpm);
		@entrez_gene_ids = unique_first_array_elements(\@entrez_gene_ids,\@entrez_gene_ids_previous);
	}
	return (@entrez_gene_ids);
}

sub tpm {
	my $rc = "";
	my $counter = 0;
	my @tpm = @_;
	my $search='';
	do {
		
		my $next = 0;
		foreach my $element (@tpm){
			print "(".($next+1).") $tpm[$next]\n";
			++$next;
		}
		$rc = <>;
		#$rc = "\n".$rc;
		unless ($rc =~ /^[123]\n/){
			++$counter;
			if ($counter > 4){
				$rc = "1\n";
			}
		}
	$search = '^[1-'.(@tpm).']\n';
	#}until ($rc =~ /^[1-6]\n/);
	}until ($rc =~ /$search/);
	
 	$rc =~ s/\n//g;
  	$rc = $tpm[$rc-1];
  	return $rc;
}

sub species {
	my ($species) = @_;
	if ($species eq 'chicken') {$species = 'Gga'};
	if ($species eq 'cattle') {$species = 'Bt'};
	if ($species eq 'pig') {$species = 'Ssc'};
	if ($species eq 'human') {$species = 'Hs'};
	if ($species eq 'house mouse') {$species = 'Mm'};
	if ($species eq 'dog') {$species = 'Cfa'};
	if ($species eq 'horse') {$species = 'Eca'};
	if ($species eq 'zebrafish') {$species = 'Dr'};
	return $species;
}

1;
