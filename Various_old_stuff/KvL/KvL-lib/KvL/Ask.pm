package Ask;

use strict;
use warnings;

use Data::Dumper;
use LWP::Simple;
use File::stat;

sub gene {
	my ($example, $fh, $fhht, $species) = @_;
	my $gen="";
	my @result;
	my $refspecies = 'human';
	$gen = ask_gene($example);
	@result = get_species_gene($gen,$fh,$fhht,$species);
	if (@result){
		$refspecies = $species;
	}
	else{
		unless (Fetch_Ortholog::hgnc_symbol($gen)){
			print "\n$gen is not an official Hugo symbol!\n";
			print $fh "\n$gen is not an official Hugo symbol!\n";
			print $fhht "<br>$gen is not an official Hugo symbol!<br>";
		}	

		if  (Fetch_Ortholog::hgnc_symbol($gen)){
		
			my ($entrez_gene_id,$approved_name) = Fetch_Ortholog::hgnc_symbol($gen);
			print $fh "\nHGNC symbol $gen has approved name $approved_name.\n";
			print $fhht "<hr><br><strong>HGNC symbol <a href=".'"'."http://www.ncbi.nlm.nih.gov/sites/entrez?db=gene&cmd=search&term=$entrez_gene_id".'" target = "_blank" '."<em> $gen </em> </a>has approved name $approved_name.</strong><br><hr>";
			print "\nHGNC symbol $gen has approved name $approved_name.\n";
			push (@result, $gen);
		}
	}

	
	return (\@result, $refspecies);
}
sub get_species_gene {
	my ($gen, $fh, $fhht, $species) = @_;
	my @result;
	my $entrez_gene_id = PubMed::ncbi_genes($gen,$species);
	my @gene_ids_ensembl_ncbi;
	my $ncbi_symbol;
	my $ncbi_description;
	my $ens_species = Ask::species_to_ensembl_species($species);

	#for testing
	print "** $gen\t";
	print $fh "** $gen\t";
	#
	if ($entrez_gene_id){
		#for testing
		print "*$entrez_gene_id**";
		print $fh "*$entrez_gene_id**";
		#
		($ncbi_symbol, $ncbi_description) = PubMed::ncbi_gene_description($entrez_gene_id);
		unless ($species eq 'pig'){
			@gene_ids_ensembl_ncbi = Gene_Attributes::xref_to_ensembl_id($entrez_gene_id, $species);
		}
	}
	# for testing
	print "\n";
	print $fh "\n";
	#
	if (@gene_ids_ensembl_ncbi || $species eq 'pig'){
		if ($entrez_gene_id){
			print "$species gene $ncbi_symbol ($ncbi_description) has NCBI gene id $entrez_gene_id and EnsEMBL gene id";
			print $fh "$species gene $ncbi_symbol ($ncbi_description) has NCBI gene id $entrez_gene_id and EnsEMBL gene id";
			print $fhht "<strong>$species gene <a href=".'"'."http://www.ncbi.nlm.nih.gov/sites/entrez?db=gene&cmd=search&term=$entrez_gene_id".'" target = "_blank" '."<em>$ncbi_symbol</em> </a>($ncbi_description) has NCBI gene id <em> $entrez_gene_id </em> and EnsEMBL gene id ";
		
			foreach my $element (@gene_ids_ensembl_ncbi){
				print " $element";
				print $fh " $element";
				print $fhht "<a href=".'"'."http://www.ensembl.org/$ens_species/geneview?gene=$element".'" target = "_blank" <em>'.$element."</em></a>";
				push (@result, $element);
			}
			print "\n";
			print $fh "\n";
			print $fhht "</strong><br>\n";
		}
	}
	else {
		unless (Fetch_Ortholog::hgnc_symbol($gen)){
			print "\n$gen is not an official Hugo symbol!\n";
			print $fh "\n$gen is not an official Hugo symbol!\n";
			print $fhht "<br>$gen is not an official Hugo symbol!<br>";
		}	

		if  (Fetch_Ortholog::hgnc_symbol($gen)){
			my $refspecies = 'human';
			my $entrezgene;
			my ($entrez_gene_id2,$approved_name) = Fetch_Ortholog::hgnc_symbol($gen);
			print $fh "HGNC symbol $gen --> ";
			print $fhht "<strong>HGNC symbol <a href=".'"'."http://www.ncbi.nlm.nih.gov/sites/entrez?db=gene&cmd=search&term=$entrez_gene_id2".'" target = "_blank" '."<em> $gen </em> </a> --> </strong>";
	
			print "HGNC symbol $gen --> ";
			my ($ortholog) = Fetch_Ortholog::ortholog($species, $gen, $refspecies);

			if ($ortholog){
				my @xrefs = Gene_Attributes::xref($species, $ortholog);
				foreach my $element (@xrefs){
					if ($element =~ /EntrezGene/){
						$element =~ s/EntrezGene\t//g;
						$entrezgene = $element;
					}
				}
				$entrez_gene_id = PubMed::ncbi_genes($entrezgene,$species);
				if ($entrez_gene_id){
					($ncbi_symbol, $ncbi_description) = PubMed::ncbi_gene_description($entrez_gene_id);
					@gene_ids_ensembl_ncbi = Gene_Attributes::xref_to_ensembl_id($entrez_gene_id, $species);
				}
			}
			if (@gene_ids_ensembl_ncbi){
				print "$species gene $ncbi_symbol ($ncbi_description) has NCBI gene id $entrez_gene_id and EnsEMBL gene id";
				print $fh "$species gene $ncbi_symbol ($ncbi_description) has NCBI gene id $entrez_gene_id and EnsEMBL gene id";
				print $fhht "<strong>$species gene <a href=".'"'."http://www.ncbi.nlm.nih.gov/sites/entrez?db=gene&cmd=search&term=$entrez_gene_id".'" target = "_blank" '."<em>$ncbi_symbol</em> </a>($ncbi_description) has NCBI gene id <em> $entrez_gene_id </em> and EnsEMBL gene id ";
		
				foreach my $element (@gene_ids_ensembl_ncbi){
					print " $element";
					print $fh " $element";
					print $fhht "<a href=".'"'."http://www.ensembl.org/$ens_species/geneview?gene=$element".'" target = "_blank" <em>'.$element."</em></a>";
					push (@result, $element);
				}
				print "\n";
				print $fh "\n";
				print $fhht "</strong><br>\n";
				$refspecies = $species;

			}
			else {
				print " No $species ortholog!\n";
				print $fh " No $species ortholog!\n";
				print $fhht "<strong> No $species ortholog!</strong><br>\n";
			}

		
		}
	}
	return @result;
}

sub human_gene {
	my ($example, $fh, $fhht) = @_;
	my $gen="";
	my @result;
	$gen = ask_gene($example);

	unless (Fetch_Ortholog::hgnc_symbol($gen)){
		print "\n$gen is not an official Hugo symbol!\n";
		print $fh "\n$gen is not an official Hugo symbol!\n";
		print $fhht "<br>$gen is not an official Hugo symbol!<br>";
	}	

	if  (Fetch_Ortholog::hgnc_symbol($gen)){
	
		my ($entrez_gene_id,$approved_name) = Fetch_Ortholog::hgnc_symbol($gen);
		print $fh "\nHGNC symbol $gen has approved name $approved_name.\n";
		print $fhht "<br><strong>HGNC symbol <a href=".'"'."http://www.ncbi.nlm.nih.gov/sites/entrez?db=gene&cmd=search&term=$entrez_gene_id".'" target = "_blank" '."<em> $gen </em> </a>has approved name $approved_name.</strong><br>";
		print "\nHGNC symbol $gen has approved name $approved_name.\n";
		push (@result, $gen);
	}
	
	
	return (@result);
}
sub get_human_gene {
	my ($gen, $fh, $fhht,$species) = @_;
	my @result;
	my $ens_species = Ask::species_to_ensembl_species($species);
	my $refspecies = 'human';

	unless (Fetch_Ortholog::hgnc_symbol($gen)){
		print "\n$gen is not an official Hugo symbol!\n";
		print $fh "\n$gen is not an official Hugo symbol!\n";
		print $fhht "<br>$gen is not an official Hugo symbol!<br>";
	}	

	if  (Fetch_Ortholog::hgnc_symbol($gen)){
		my ($ortholog, $hum_chrom, $hum_chrom_start, $hum_chrom_end, $description, $identity, $homology_type, $hugo) = Fetch_Ortholog::ortholog($species, $gen, $refspecies);

		my ($entrez_gene_id,$approved_name) = Fetch_Ortholog::hgnc_symbol($gen);
		print $fh "\nHGNC symbol $gen has approved name $approved_name.";
		print $fhht "<strong>HGNC symbol <a href=".'"'."http://www.ncbi.nlm.nih.gov/sites/entrez?db=gene&cmd=search&term=$entrez_gene_id".'" target = "_blank"'."<em> $gen </em> </a>has approved name $approved_name</strong> - ";
		print "\nHGNC symbol $gen has approved name $approved_name - ";
		
		if ($ortholog){
			
			my $type;
			if ($homology_type =~ /ortholog_one2one/){
				$type = 1;				
			}
			else {
				$type = 'many';
			}
			print "$species ortholog (1-$type) is $ortholog\n";
			print $fh "$species ortholog (1-$type) is $ortholog\n";
			print $fhht "$species ortholog (1-$type) is "."<a href=".'"'."http://www.ensembl.org/$ens_species/geneview?gene=$ortholog".'" target = "_blank" <em>'.$ortholog."</em></a><br>\n";

			push (@result, $ortholog);


		}
		else {
			print "no $species ortholog found!\n";
			print $fh "no $species ortholog found!\n";
			print $fhht "no $species ortholog found!<br>\n";
		}
			
	}
	
	
	return (@result);
}

sub species {
	my $rc = "";
	my $counter = 0;
	my @species = @_;
	my $search='';
	do {
		
		print "For which species do you want to find genes?\n";
		my $next = 0;
		foreach my $element (@species){
			print "(".($next+1).") $species[$next]\n";
			++$next;
		}
		$rc = <>;
		#$rc = "\n".$rc;
		unless ($rc =~ /^[123456]\n/){
			++$counter;
			if ($counter > 4){
				$rc = "1\n";
			}
		}
	$search = '^[1-'.(@species).']\n';
	#}until ($rc =~ /^[1-6]\n/);
	}until ($rc =~ /$search/);
	
 	$rc =~ s/\n//g;
  	$rc = $species[$rc-1];
  	return $rc;
}

sub ask_gene {
	my $rc = "";
	print "Which gene (HGCN) do you want to retrieve? (example: $_[0]) ";
	$rc = <>;
	chomp $rc;
  	if($rc eq "") { $rc = $_[0]; }
	$rc = uc $rc;
	return $rc;
  	
}

sub what {	
	my $rc = "";
	my $counter = 0;
	my @what = @_;
	do {
		print "How do you want to find your genes?\n";
		my $next = 0;
		foreach my $element (@what){
			print "(".($next+1).") $what[$next]\n";
			++$next;
		}
		$rc = <>;
		chomp $rc;
		unless ($rc =~ /^\d+$/g){
			++$counter;
			if ($counter > 4){
				$rc = "1\n";
			}
			else {$rc = 1000;}
		}

		if ($rc =~ /^\d+$/g){

			unless ($rc < (@what)){
				++$counter;
				if ($counter > 4){
					$rc = "1\n";
				}
			}
		}

	}until ($rc <= (@what));
	
 	$rc =~ s/\n//g;
  	if($rc eq "1") { $rc = 'gene'; }
	if($rc eq "2") { $rc = 'qtl'; }
	if($rc eq "3") { $rc = 'go'; }
	if($rc eq "4") { $rc = 'pubmed';}
	if($rc eq "5") { $rc = 'omim';}
	if($rc eq "6") { $rc = 'list';}
	if($rc eq "7") { $rc = 'gene_id';}
	if($rc eq "8") { $rc = 'network';}
	if($rc eq "9") { $rc = 'intersect';}
	if($rc eq "10") { $rc = 'express';}
  	return $rc;
}


sub region {
	my $fh = $_[4];
	my $fhht = $_[5];
	my $species = $_[3];
	my $slice_adaptor = Bio::EnsEMBL::Registry->get_adaptor($species,'core','Slice');

	my $chromosome = "";
	my $start = "";
	my $end = "";
	my @gene_ids=();
	my @gene_names;

	print "What chromosomal or qtl region do you want to query?\n Name of chromosome (example: $_[0]) ";
	$chromosome = <>;
	chomp $chromosome;
  	if($chromosome eq "") { $chromosome = $_[0]; }
	print "start of region in bp (example: $_[1]) ";
	$start = <>;
	chomp $start;
  	if($start eq "") { $start = $_[1]; }
	print "end of region in bp (example: $_[2]) ";
	$end = <>;
	chomp $end;
  	if($end eq "") { $end = $_[2]; }
	

	my $slice = $slice_adaptor->fetch_by_region('chromosome', $chromosome, $start, $end);
	
	# getting all genes in that region
	my @genes = @{$slice->get_all_Genes()};

	unless (@genes){
		print "No genes found based on your entry\n";
		print $fh "No genes found based on your entry\n";
		print $fhht "No genes found based on your entry<br>";
	}
	if (@genes){
		print $fhht '<hr>';
		print $fhht '<table border="1"><tr><th>chr.</th><th>gene start</th><th>gene end</th><th>gene id</th><th>gene name</th></tr>';

		foreach my $gene (@genes){
			my $gene_id = $gene -> stable_id();
			my $start_gene=$start+($gene->start());
			my $end_gene=$start+($gene->end());
	
			print $fh $start_gene."\t".$end_gene."\t".$gene_id."\t".$gene -> external_name()."\n";
			print $fhht '<tr><td>'.$chromosome."</td><td>".$start_gene."</td><td>".$end_gene."</td><td>".$gene_id."</td><td>".$gene -> external_name()."</td></tr>";
	
			print $start_gene."\t".$end_gene."\t".$gene_id."\t".$gene -> external_name()."\n";
			push (@gene_ids, $gene_id);
			push (@gene_names,$gene->external_name());
			
		}
		print $fhht '</table>'."\n";
		print "There are ". @gene_ids . " genes in chromosome $chromosome, bases $start to $end in $_[3].";
		print $fh "There are ". @gene_ids . " genes in chromosome $chromosome, bases $start to $end in $_[3].";
		print $fhht "<strong>There are ". @gene_ids . " genes in chromosome $chromosome, bases $start to $end in $_[3].</strong><hr>";
	}
	my $gene_ids_ref = \@gene_ids;

	print_species_ensembl_gene_id_info($gene_ids_ref,$species,$fh,$fhht);

	return @gene_ids;
}

sub go {

	my @gene_ids=();
	my $ok = 'no';
	my $parent;
	my $acc_name;
	my $assoc_gene;
	my $query;
	my $fh = $_[2];
	my $fhht = $_[3];
	my $species = $_[4];
	my @assoc_genes;

	print "For which GO term (accession or name) would you like to retrieve associated genes?\n(example: either '$_[0]' OR '$_[1]') ";
	my $go = <>;
	chomp $go;
 	if($go eq "") { $go = $_[0]; }
		
	print "\n------please be patient, it may take several minutes to retrieve data from the databases\n";
	($ok, $parent, $acc_name, $assoc_gene) = MyGO::MyGO($go, $fh, $fhht);
	# if the go term is not found the program will die in the module MyGO!!!!
	$query=$go;
	
	unless ($ok eq 'no'){
		my @acc_names = @$acc_name;
		@assoc_genes = @$assoc_gene;
		my @parents = @$parent;
		@acc_names = sort @acc_names;
		print $fh "You have queried go for the following term: $query\n\n";
		print $fhht "<hr><h3>You have queried go for the following term: $query</h3><br>";
		print "You have queried go for the following term: $query\n\n";
	
		my $flag = $acc_names[0];
		$flag =~ s/^\d+\t//g;
		$flag =~ s/\t/ - /g;
	
		print "GO term '$flag' is parent of the following terms:\n\nDist.\tGO acc\t\tGO name\n";
		print $fh "GO term '$flag' is parent of the following terms:\n\nDist.\tGO acc\t\tGO name\n";
		print $fhht "<hr><strong>GO term '$flag' is parent of the following terms:</strong><br><br><em><XMP>Dist.\tGO acc\t\tGO name</XMP></em>";
		
	
		foreach my $term (@acc_names){
			print "$term\n";
			print $fh "$term\n";
			print $fhht "<XMP>$term</XMP>";

		}
		@parents = sort @parents;
		print "\nGO term '$flag' is descendant of the following terms:\n\nDist.\tGO acc\t\tGO name\n";
		print $fh "\nGO term '$flag' is descendant of the following terms:\n\nDist.\tGO acc\t\tGO name\n";
		print $fhht "\n<br><strong>GO term '$flag' is descendant of the following terms:</strong><br><br><em><XMP>Dist.\tGO acc\t\tGO name</XMP></em>";
		foreach my $term (@parents){
			print "$term\n";
			print $fh "$term\n";
			print $fhht "<XMP>$term</XMP>";
		}

		print "\nThe following genes are associated with the term and its children:\n";
		print $fh "\nThe following genes are associated with the term and its children:\n";
		print $fhht "\n<hr><br><strong>The following genes are associated with the term and its children:</strong><br>\n";
		foreach my $gene (@assoc_genes){
			print "$gene\n";
			print $fh "$gene\n";
			print $fhht "$gene<br>";
		}
		print "There are ". @assoc_genes . " unique genes in go term '$flag'.";
		print $fh "There are ". @assoc_genes . " unique genes in go term '$flag'.";
		print $fhht "<br>There are <strong>". @assoc_genes . "</strong> unique genes in go term <strong>'$flag'</strong>.<br><hr>";
	
	}
	my @species_assoc_genes;
	#print "These genes correspond to the following $species genes:\n";
	foreach my $human_gene (@assoc_genes){
		my @intresult = get_human_gene($human_gene,$fh,$fhht,$species);
		push (@species_assoc_genes, @intresult);
	}

	my $gene_ids_ref = \@species_assoc_genes;
	print $fhht "<hr>there are ".scalar(@species_assoc_genes)." genes that match your query<br>\n";
	print_species_ensembl_gene_id_info($gene_ids_ref,$species,$fh,$fhht);
	
	
	return @species_assoc_genes;
}

sub list {
	
	my @gene_ids;
	my @genes;

	print "Name of file containing genes? (example: $_[0]) ";
	my $fh = $_[1];
	my $fhht = $_[2];
	my $species = $_[3];
	my $file = <>;
	chomp $file;

  	if($file eq "") { $file = $_[0]; }
	my $checkfile =stat("$file");
	unless ($checkfile){	
		print "This file appears not to exist!!\n";
	}

	if ($checkfile){	
		open(FILE, "$file") or warn "can not open file: $file $!\n";
	
	
		@genes = <FILE>;
		close (FILE);
	}
	print "Genes in file: $file\n";
	print $fh "Genes in file: $file\n\n";
	print $fhht "<hr><h3>Genes in file: $file</h3>";

	unless (@genes){
		print "No genes found in file $file!\n";
		print $fh "No genes found in file $file!\n";
		print $fhht "No genes found in file $file!<br>";

	}

	foreach my $gene (@genes){
		chomp $gene;
		if ($gene =~ /ENSG.*\d\d\d\d\d\d\d$/){
			$gene = check_ensemblgeneid($gene,$species);
			if ($gene){
				my @dummyref;
				push (@dummyref,$gene);
				print_species_ensembl_gene_id_info(\@dummyref,$species,$fh,$fhht);
				push (@gene_ids,$gene);
			}
		}
		else {
			my @result = get_species_gene($gene,$fh,$fhht,$species);
			push (@gene_ids, @result);
		}

	}
	
	
	print "There are ". @gene_ids . " valid genes in $file.\n";
	print $fh "There are ". @gene_ids . " valid genes in $file.\n";
	print $fhht "<strong>There are ". @gene_ids . " valid genes in $file.</strong><hr>";
	
	return @gene_ids;
}

sub omim {
	my $fh = $_[1];
	my $fhht = $_[2];
	my $species = $_[3];

	my $query="";
	my $eutils	= "http://eutils.ncbi.nlm.nih.gov/entrez/eutils";
	my @results=();
	print "\nSearch for OMIM classes (example: $_[0]) ";
	$query = <>;
	chomp $query;
  	if($query eq "") { $query = $_[0]; }
	
	print "Your query: $query\n";
	print $fh "Your query: $query\n";
	print $fhht "<hr><h3>Your query: $query</h3>";


	$query =~ s/ and / AND /g;
	$query =~ s/ or / OR /g;
	$query =~ s/ /+/g;

	my $esearch = "$eutils/esearch.fcgi?" .
              "db=omim&retmax=1&usehistory=y&term=";

	my $esearch_result = get($esearch . $query);

	#print "\nESEARCH RESULT: $esearch_result\n";

	$esearch_result =~ 
	  m|<Count>(\d+)</Count>.*<QueryKey>(\d+)</QueryKey>.*<WebEnv>(\S+)</WebEnv>|s;

	my $Count    = $1;
	my $QueryKey = $2;
	my $WebEnv   = $3;

	#print "Count = $Count; QueryKey = $QueryKey; WebEnv = $WebEnv\n";

	print "There are $Count OMIM hits\n";
	print $fh "There are $Count OMIM hits\n";
	print $fhht "<strong>There are $Count OMIM hits</strong><br>";

	my $retstart;

	for($retstart = 0; $retstart < $Count; ++$retstart) {
		my $num_genes=0;
		my $efetch = "$eutils/efetch.fcgi?" . "rettype=uilist&retmode=text&retstart=$retstart&retmax=1&" .
               "db=omim&query_key=$QueryKey&WebEnv=$WebEnv";
		my $efetch_result = get($efetch);
		#print $efetch_result."\n";
  		my $elink = "$eutils/elink.fcgi?usehistory=y&id=$efetch_result&cmd=omim_gene&dbFrom=omim&db=gene";

		my $elink_result = get($elink);
		#print $elink_result."\n";
		while ($elink_result =~ /<Link>\n\t\t\t<Id>(\d+)<\/Id>\n\t\t<\/Link>/g){
			push (@results,$1);
			++$num_genes;
		}
		print "OMIM hit " . ($retstart+1) . " has $num_genes genes associated\n";
		print $fh "OMIM hit " . ($retstart+1) . " has $num_genes genes associated\n";
		print $fhht "<em>OMIM hit " . ($retstart+1) . " has $num_genes genes associated</em><br>";

		#print $elink_result."\n";
  		#print "(".($retstart+1) . "): $efetch_result\n";
	}
	
	my %count = ( );
	foreach my $element (@results) {
	    $count{$element}++;
	}
	while ( my ($k,$v) = each %count ) {
	    print "$k => $v\n";
	}
	

	my @final_results=();
	my %seen = ( );
	foreach my $item (@results) {
		unless ($seen{$item}) {
        	# if we get here, we have not seen it before
        		$seen{$item} = 1;
        		push(@final_results, $item);
		}
	}
	
	my $total_genes=0;
	my @sub_return = ();

	foreach my $final_result (@final_results){
		my ($human_gene) = Fetch_Ortholog::entrez_gene_id($final_result);
		if ($human_gene){
			print "$final_result\t$human_gene\n";
			push (@sub_return, $human_gene);
			++$total_genes;
		}
		else {
			my $human_gene2 = Fetch_Ortholog::mouse_entrez($final_result);
			if ($human_gene2){
				print "$final_result\t$human_gene2\n";
				push (@sub_return, $human_gene2);
				++$total_genes;
				
			}
		}
	}

	my @return=();
	%seen = ( );
	foreach my $item (@sub_return) {
		unless ($seen{$item}) {
        	# if we get here, we have not seen it before
        		$seen{$item} = 1;
        		push(@return, $item);
		}
	}
	
	print "There are $total_genes associated with the OMIM query, of which ". @return . " unique ids.";
	print $fh "There are $total_genes associated with the OMIM query, of which ". @return . " unique ids.";
	print $fhht "<strong>There are $total_genes associated with the OMIM query, of which ". @return . " unique ids.</strong><hr>";

	foreach my $ret (@return){
		print $fh $ret."\n";
		print $fhht $ret."<br>";
	}

	my @species_assoc_genes;
	foreach my $human_gene (@return){
		my @intresult = get_human_gene($human_gene,$fh,$fhht,$species);
		push (@species_assoc_genes, @intresult);
	}
	
	my $gene_ids_ref = \@species_assoc_genes;
	print $fhht "<hr>";
	print_species_ensembl_gene_id_info($gene_ids_ref,$species,$fh,$fhht);
	
	return @species_assoc_genes;
}

	
sub pubmed {
	my $fh = $_[1];
	my $fhht = $_[2];
	my $species = $_[3];
	my $opt = $_[4];
	my $query="";
	print "Find genes based on pubmed search (example: $_[0]) ";
	$query = <>;
	chomp $query;
  	if($query eq "") { $query = $_[0]; }
	my $wantabstract = 'yes';
	
	my ($intresults,$intabstracts) = PubMed::pubmed($query,$wantabstract,$fh, $fhht,$species,$opt);
	my @results = @$intresults;
	my @abstracts = @$intabstracts;
	print "\n";
	
	my @return=();
	my %count = ();
	my %seen = ();
	foreach my $item (@results) {
		$count{$item}++;

		unless ($seen{$item}) {
        	# if we get here, we have not seen it before
        		$seen{$item} = 1;
        		push(@return, $item);
		}
	}

	print $fh "$query on pubmed:\n\n";
	print $fhht "<hr><strong>$query on pubmed:</strong><br>";
	while ( my ($k,$v) = each %count ) {
		print "$k => $v\n";
		print $fh "$k => $v\n";
		print $fhht "$k => $v<br>";

	}
	

	print "There are ". @results ." genes associated with the pubmed query, but ". @return . " unique ids.";
	print $fh "\nThere are ". @results ." genes associated with the pubmed query, but ". @return . " unique ids.\n";
	print $fhht "<br><strong>There are ". @results ." genes associated with the pubmed query, but ". @return . " unique ids.</strong><hr>";
	

	foreach my $abstract (@abstracts){
		print $fh "++++++++++\n\n".$abstract."\n\n++++++++++++++++\n\n";
		print $fhht "<XMP>".$abstract."</XMP><hr>";
	}
	print "\nThe following genes are associated with the query: $query\n\n";
	print $fh "\nThe following genes are associated with the query: $query\n\n";
	print $fhht "<strong>The following ".@return. " genes are associated with the query: <em>$query</em></strong><br>";
	foreach my $ret (@return){
		print $ret."\n";
		print $fh $ret."\n";
		#print $fhht $ret."<br>";
	}
	print $fhht '<hr>';
	my $gene_ids_ref = \@return;
	print_species_ensembl_gene_id_info($gene_ids_ref,$species,$fh,$fhht);
	
	return @return;
	
}

sub intro {
	#my $path = "KvL";
	my $path = "/usr/local/lib/kvl_lib/KvL";
	#my $path = "/home/bioroot/lib/perl/KvL";
	print "\n==============================================================\n";
	print " KvL Toolbox version 0.04.2\n";
	print "\n";
	print " This is a work in progress. Bugs of any kind, including crashes\n";
	print " and errors in the output are to be expected at this stage. By \n";
	print " testing you help develop the toolbox further!\n";
	print " Report errors or remarks to: hendrik-jan.megens\@wur.nl\n";
	print "--------------------------------------------------------------\n";
	print " components                          last modified\n";
	print "--------------------------------------------------------------\n";
	#my $sb =stat('/home/bioroot/bin/DevKvL0');
	#my $sb =stat('DevKvL0.pl');
	my $sb =stat('/usr/local/bin/KvL');
	my $age = scalar localtime $sb->mtime;
	print " main:      DevKvL0.pl               $age\n";
	$sb =stat("$path/Ask.pm");
	$age = scalar localtime $sb->mtime;
	print " module:    Ask.pm                   $age\n";
	$sb =stat("$path/Fetch_Ortholog.pm");
	$age = scalar localtime $sb->mtime;
	print " module:    Fetch_Ortholog.pm        $age\n";	
	$sb =stat("$path/Snps.pm");
	$age = scalar localtime $sb->mtime;
	print " module:    Snps.pm                  $age\n";	
	$sb =stat("$path/Gene_Attributes.pm");
	$age = scalar localtime $sb->mtime;
	print " module:    Gene_Attributes.pm       $age\n";		
	$sb =stat("$path/Mirna.pm");
	$age = scalar localtime $sb->mtime;
	print " module:    Mirna.pm                 $age\n";	
	$sb =stat("$path/Comparebyblast.pm");
	$age = scalar localtime $sb->mtime;
	print " module:    Comparebyblast.pm        $age\n";
	$sb =stat("$path/FootPrinterPerl.pm");
	$age = scalar localtime $sb->mtime;
	print " module:    FootPrinterPerl.pm       $age\n";
	$sb =stat("$path/CloverPerl.pm");
	$age = scalar localtime $sb->mtime;
	print " module:    CloverPerl.pm            $age\n";
	$sb =stat("$path/GeneNetworks.pm");
	$age = scalar localtime $sb->mtime;
	print " module:    GeneNetworks.pm          $age\n";
	$sb =stat("$path/MyGO.pm");
	$age = scalar localtime $sb->mtime;
	print " module:    MyGO.pm                  $age\n";
	$sb =stat("$path/PubMed.pm");
	$age = scalar localtime $sb->mtime;
	print " module:    PubMed.pm                $age\n";
	$sb =stat("$path/Expression.pm");
	$age = scalar localtime $sb->mtime;
	print " module:    Expression.pm            $age\n";
	print "--------------------------------------------------------------\n";
	print " mySQLdb:   kvl\n";
	print " mySQLdb:   mygo\n";
	print "--------------------------------------------------------------\n";
	print " API:       EnsEMBL48\n";
	print " API:       GenBank (NCBI) etools\n";
	print "--------------------------------------------------------------\n";
	print " program:   miRanda\n";
	print " program:   Blast (bl2seq)\n";
	print " program:   FootPrinter\n";
	print " program:   Clover\n";
	print "==============================================================\n\n";
		
}

sub ensemblgeneid {
	my ($example, $species, $fh, $fhht) = @_;
	my $gen="";
	my @result;
	my $gene_adaptor = Bio::EnsEMBL::Registry->get_adaptor($species ,'core','Gene');
	
	$gen = "";
	print "Which gene id for $species do you want to retrieve? (example: $example)";
	$gen = <>;
	chomp $gen;
  	if($gen eq "") { $gen = $example; }
	$gen = uc $gen;

	unless ($gene_adaptor -> fetch_by_stable_id($gen)){
		print "$gen is not a recognized gene id for $species, please try again!\n";
		print $fh "$gen is not a recognized gene id for $species, please try again!\n";
		print $fhht "<hr><strong>$gen is not a recognized gene id for $species, please try again!</strong><hr>";

	}	

	if ($gene_adaptor -> fetch_by_stable_id($gen)){

		print "$gen is a valid stable id for $species.\n";
		print $fh "$gen is a valid stable id for $species.\n";
		print $fhht "<hr><strong>$gen is a valid stable id for $species.</strong><hr>";

		push (@result, $gen);
	}
	return @result;
}

sub intersecting_networks {
	my ($example1,$example2, $depth, $fh, $fhht,$species)=@_;
	my $entrez_gene_id1;
	my $entrez_gene_id2;
	my @genes1;
	my @genes2;
	my @human_genes = ();


	print "Input two genes that are starting points for building networks:\n";
	print "\nGene 1:\n";
	print $fh "\nGene 1:\n";
	@genes1 = Ask::human_gene($example1,$fh, $fhht);
	if (@genes1){
		($entrez_gene_id1) = Fetch_Ortholog::hugo_to_entrez_gene_id($genes1[0]);
		if ($entrez_gene_id1){
			print "$genes1[0] corresponds to entrez gene id $entrez_gene_id1\n";
			print $fh "$genes1[0] corresponds to entrez gene id $entrez_gene_id1\n";
			print $fhht "$genes1[0] corresponds to entrez gene id $entrez_gene_id1";
		}
		else {
			print "no entrez gene id for this gene\n";
			print $fh "no entrez gene id for this gene\n";
			print $fhht "no entrez gene id for this gene";
		}
	}

	print "\nGene 2:\n";
	print $fh "\nGene 2:\n";

	@genes2 = Ask::human_gene($example2, $fh, $fhht);
	if (@genes2){
		($entrez_gene_id2) = Fetch_Ortholog::hugo_to_entrez_gene_id($genes2[0]);
		if ($entrez_gene_id2){
			print "$genes2[0] corresponds to entrez gene id $entrez_gene_id2\n";
			print $fh "$genes2[0] corresponds to entrez gene id $entrez_gene_id2\n";
			print $fhht "$genes2[0] corresponds to entrez gene id $entrez_gene_id2";
		}
		else {
			print "no entrez gene id for this gene\n";
			print $fh "no entrez gene id for this gene\n";
			print $fhht "no entrez gene id for this gene\n";

		}
	}

	print $fhht "<hr>";
	my $rc = "";
	do {
		print "To what depth do you want to retreive the network? (between 1 and 4, example: $depth): \n";
		$rc = <>;
		chomp $rc;
  		if($rc eq "") { $rc = $depth; }
	}until ($rc =~ /^[1234]$/);
	$depth = $rc;
	
	if ($entrez_gene_id1 && $entrez_gene_id2){

		my $gene1 = "$genes1[0]\t$entrez_gene_id1";
		my $gene2 = "$genes2[0]\t$entrez_gene_id2";
		
		my ($refboth,$refres1,$refres2) = SearchNCBI::intersecting_networks($gene1,$gene2,$depth);
		my @both = @$refboth;
		my @results1 = @$refres1;
		my @results2 = @$refres2;
		
		foreach my $element (@both){
			#print $element."\n";
			my @int = split ("\t",$element);
			if (Fetch_Ortholog::entrez_gene_id($int[1])){
				push (@human_genes, Fetch_Ortholog::entrez_gene_id($int[1]));
			}
		
		}
		my $gene_flag1 = $gene1;
		$gene_flag1 =~ s/\t\d+$//g;
		my $gene_flag2 = $gene2;
		$gene_flag2 =~ s/\t\d+$//g;
		print "You investigated the overlap in gene network between $gene_flag1 and $gene_flag2 with depth of $depth:\n\n";
		print $fh "You investigated the overlap in gene network between $gene_flag1 and $gene_flag2 with depth of $depth:\n\n";
		print $fhht "<strong>You investigated the overlap in gene network between $gene_flag1 and $gene_flag2 with depth of $depth:</strong><br><br>";
	
		print "$gene_flag1 resulted in ".scalar @results1." genes in its network (depth of $depth)\n";
		print $fh "$gene_flag1 resulted in ".scalar @results1." genes in its network (depth of $depth)\n";
		print $fhht "<em>$gene_flag1 resulted in ".scalar @results1." genes in its network (depth of $depth)</em><br>";
		
		print "$gene_flag2 resulted in ".scalar @results2." genes in its network (depth of $depth)\n";
		print $fh "$gene_flag2 resulted in ".scalar @results2." genes in its network (depth of $depth)\n";
		print $fhht "<em>$gene_flag2 resulted in ".scalar @results2." genes in its network (depth of $depth)</em><br>";
		
		print "Overlap in both was ".scalar @both." genes\n";
		print $fh "Overlap in both was ".scalar @both." genes\n";
		print $fhht "<strong>Overlap in both was ".scalar @both." genes</strong><br>";
		
		print "number of human genes:" .scalar @human_genes."\n";
		print $fh "number of human genes:" .scalar @human_genes."\n";
		print $fhht "number of human genes:" .scalar @human_genes."<br>";
		
		foreach my $element(@human_genes){
			print "$element\n";
			print $fh "$element\n";
			print $fhht "$element<br>";
		}
	}

	else {
		print "\n+++++++++++++++++++++\none or both genes were not recognized!!!!\nstart your search again or abort (<CTRL>C)\n++++++++++++++++\n\n";
		print $fh "\n+++++++++++++++++++++\none or both genes were not recognized!!!!\nstart your search again or abort (<CTRL>C)\n++++++++++++++++\n\n";
		print $fhht "<hr>one or both genes were not recognized!!!!<br>start your search again or abort (<CTRL>C)<hr>";
	}
	print $fhht "<hr>";
	my @species_assoc_genes;
	
	#foreach my $try (@human_genes){
	#	print "$try<br>\n";
	#}

	foreach my $human_gene (@human_genes){
		my @intresult = get_human_gene($human_gene,$fh,$fhht,$species);
		push (@species_assoc_genes, @intresult);
	}

	my $gene_ids_ref = \@species_assoc_genes;
	
	print $fhht "<hr>there are ".scalar(@species_assoc_genes)." genes that match your query<br>\n";
	#foreach my $try (@species_assoc_genes){
	#	print "$try<br>\n";
	#}
	print_species_ensembl_gene_id_info($gene_ids_ref,$species,$fh,$fhht);

	return @species_assoc_genes;
}

sub gene_network_neighborhood {
	my ($example, $depth, $fh, $fhht,$species)=@_;
	my @human_genes = ();
	my $entrez_gene_id;
	my @genes;

	print "Input a gene for which to build a network neighborhood:\n";
	@genes = Ask::human_gene($example, $fh, $fhht);
		
	if (@genes){

		($entrez_gene_id) = Fetch_Ortholog::hugo_to_entrez_gene_id($genes[0]);
		if ($entrez_gene_id){
			print "$genes[0] corresponds to entrez gene id $entrez_gene_id\n";
			print $fh "$genes[0] corresponds to entrez gene id $entrez_gene_id\n";
			print $fhht "<strong>$genes[0] corresponds to entrez gene id $entrez_gene_id</strong><br>";

		}
		else {
			print "no entrez gene id for this gene\n";
			print $fh "no entrez gene id for this gene\n";
			print $fhht "no entrez gene id for this gene<br>";

		}
	}
	
	print $fhht "<hr>";
	my $rc = "";
	do {
		print "To what depth do you want to retreive the network? (between 1 and 4, example: $depth): \n";
		$rc = <>;
		chomp $rc;
  		if($rc eq "") { $rc = $depth; }
	}until ($rc =~ /^[1234]$/);
	$depth = $rc;
	
	if ($entrez_gene_id){
		my $gene = "$genes[0]\t$entrez_gene_id";
	
		
		@human_genes = make_osprey_gl($gene, $depth, $fh, $fhht);

	}

	print $fhht "<hr>";
	my @species_assoc_genes;
	#foreach my $try (@human_genes){
	#	print "$try<br>\n";
	#}

	foreach my $human_gene (@human_genes){
		my @intresult = get_human_gene($human_gene,$fh,$fhht,$species);
		push (@species_assoc_genes, @intresult);
	}
	my $gene_ids_ref = \@species_assoc_genes;
	#foreach my $try (@species_assoc_genes){
	#	print "$try<br>";
	#}

	print $fhht "<hr>there are ". scalar(@species_assoc_genes)." genes that match your query<br>\n";
	print_species_ensembl_gene_id_info($gene_ids_ref,$species,$fh,$fhht);
	
	return @species_assoc_genes;
}


sub make_osprey_gl {
	my ($gene, $depth, $fh, $fhht)= @_;
	my @int= split("\t",$gene);
	my $start_gene=$int[0];
	my $database = 'kvl';
	my $server = 'localhost';
	my $user = 'anonymous';
	
	my @human_genes=();
	my ($refres) = SearchNCBI::gene_network_neighborhood($gene,($depth-1));
	my @results = @$refres;
	
	foreach my $element (@results){
		#print $element."\n";
		my @int = split ("\t",$element);
		my @human_gene_lookup = Fetch_Ortholog::entrez_gene_id($int[1]);
		if (@human_gene_lookup){
			push (@human_genes, $human_gene_lookup[0]);
		}
	}
	
	@human_genes = SearchNCBI::unique_array_elements(@human_genes);
	my @human_genes_add = @human_genes;
	my @intarray=();
	my $kvl = DBI->connect("dbi:mysql:$database:$server", $user);

	foreach my $human_gene (@human_genes) {
		my $query = "select i.assoc_entrez_gene from interactions as i where i.entrez_gene_id = (select h.entrez_gene_id from hgnc_simple as h where h.approved_symbol = '$human_gene');";

		my $sql = $kvl->prepare($query);
		$sql->execute();
		my $entrez_gene_id = '';
		while (my $row = $sql->fetchrow_arrayref) {
			my $row2 = join("\t", @$row);
			my @row2array = split ("\t",$row2);
			my $assoc_entrez_gene = $row2array[0];
			my $query2 = "select approved_symbol from hgnc_simple where entrez_gene_id = '$assoc_entrez_gene'";
			my $sql2 = $kvl->prepare($query2);
			$sql2->execute();
			my $assoc_human_gene;
			while (my $row = $sql2->fetchrow_arrayref) {
				my $row2 = join("\t", @$row);
				my @row2array = split ("\t",$row2);
				$assoc_human_gene = $row2array[0];
			}
			if ($assoc_human_gene){
				print "$human_gene\t$assoc_human_gene\n";
				push (@intarray, "$human_gene\t$assoc_human_gene");
				push (@human_genes_add, $assoc_human_gene);
			}

		}
	}
	@intarray = SearchNCBI::unique_array_elements(@intarray);
	@human_genes_add = SearchNCBI::unique_array_elements(@human_genes_add);
	print "The following associations were identified:\n";
	print $fh "The following associations were identified:\n";
	print $fhht "<strong>The following associations were identified:</strong><br>";
	print "GeneA\tGeneB\n";
	print $fh "GeneA\tGeneB\n";
	print $fhht "<em><XMP>GeneA\tGeneB</XMP></em>";
	foreach my $element (@intarray){
		print "$element\n";
		print $fh "$element\n";
		print $fhht "<XMP>$element</XMP>";
	}
	
	print "\n---------------------\nThe following genes are in the network (depth: $depth):\n";
	print $fh "\n---------------------\nThe following genes are in the network (depth: $depth):\n";
	print $fhht "<hr><strong>The following genes are in the network (depth: $depth):</strong><br>";
	foreach my $element (@human_genes_add){
		print "$element\n";
		print $fh "$element\n";
		print $fhht "$element<br>";
	}
	print "number of human genes: " .scalar @human_genes_add."\n";
	print $fh "number of human genes: " .scalar @human_genes_add."\n";
	print $fhht "<br><strong>number of human genes: " .scalar @human_genes_add."</strong>";
	
	return @human_genes_add;
}

sub expression {
	my ($species,$fh,$fhht,$running_mode)=@_;
	my @genes = ();
	my $species_e = Expression::species($species);
	my @tissuesearch;
	my $tpm;
	my $conditional;
	if ($running_mode eq 'silent'){
		my $tissuesearchstring = <>;
		chomp $tissuesearchstring;
		@tissuesearch = split(',',$tissuesearchstring);
		$tpm = <>;
		chomp $tpm;
		$conditional = <>;
		chomp $conditional;
	}
	else {
		my @tissue_list = Expression::tissue_list($species_e);
		@tissuesearch = Expression::what_tissue(@tissue_list);
		print "What TPM (Transcripts Per Million) level do you want to take?\n";
		$tpm = Expression::tpm('10','100','1000');
		if ((@tissuesearch > 1)){
			$conditional = Expression::logical();
		}
	}
	my @ncbi_genes = Expression::expression_tissue($species_e,\@tissuesearch,$conditional,$tpm);
	foreach my $gene (@ncbi_genes){
		chomp $gene;		
		my @result = get_species_gene($gene,$fh,$fhht,$species);
		push (@genes, @result);

	}
	return @genes;
}

sub species_to_ensembl_species {
	my ($species) = @_;
	my $return;
	if ($species eq 'chicken'){
		$return = 'Gallus_gallus';
	}
	if ($species eq 'cattle'){
		$return = 'Bos_taurus';
	}
	if ($species eq 'dog'){
		$return = 'Canis_familiaris';
	}	
	if ($species eq 'zebrafish'){
		$return = 'Danio_rerio';
	}	
	if ($species eq 'human'){
		$return = 'Homo_sapiens';
	}
	if ($species eq 'house mouse'){
		$return = 'Mus_musculus';
	}
	if ($species eq 'pig'){
		$return = 'Sus_scrofa';
	}
	return $return;
}

sub print_species_ensembl_gene_id_info {
	my ($gene_ids_ref,$species,$fh,$fhht) = @_;
	my @gene_ids = @$gene_ids_ref;
	my $ens_species = Ask::species_to_ensembl_species($species);
	foreach my $result (@gene_ids){	

		my $description = Gene_Attributes::description($species, $result);
		my $ensembl_external_name = Gene_Attributes::ensembl_external_name($species,$result);
		if ($description) {
			#print######################
			print "\nThe description of the $species gene $result:\n$description\n\n-----------------\n";
			print $fh "\nThe description of the $species gene $result:\n$description\n\n-----------------\n";
			print $fhht "<em>The description of the $species gene <a href=".'"'."http://www.ensembl.org/$ens_species/geneview?gene=$result".'" target = "_blank" '."<em><strong> $result </strong></em> </a>(EnsEMBL name: <strong>$ensembl_external_name</strong>):</em><br>$description<br><br>";
			######################print#
		}

		else {
		
			#print######################
			print "No description for $result\n\n-----------------\n";
			print $fh "No description for $result\n\n-----------------\n";
			print $fhht "No description for <a href=".'"'."http://www.ensembl.org/$ens_species/geneview?gene=$result".'" target = "_blank" '."<em> $result </em> </a><br><br>";
			######################print#
		
		}

	}
}
sub tissuefiltering {
	my $rc = "";
	my $counter = 0;
	my ($species) = @_;
	my $tissuefiltering;
	do {
		
		print "Do you want to apply expression filtering?\n";
		print "(1) no\n(2) yes\n";
		$rc = <>;
		#$rc = "\n".$rc;
		unless ($rc =~ /^[12]\n/){
			++$counter;
			if ($counter > 4){
				$rc = "1\n";
			}
		}
	}until ($rc =~ /^[12]\n/);
	if ($rc == 1){
		$tissuefiltering = 'tissuefiltering=no';
	}
	if ($rc == 2){
		$tissuefiltering = ask_expression_filtering($species);
	}
	return $tissuefiltering;
}


sub ask_expression_filtering {
	my ($species)=@_;
	my @genes = ();
	my $species_e = Expression::species($species);
	my @tissuesearch;
	my $tpm;
	my $conditional=1;
	my @tissue_list = Expression::tissue_list($species_e);
	@tissuesearch = Expression::what_tissue(@tissue_list);
	print "What TPM (Transcripts Per Million) level do you want to take?\n";
	$tpm = Expression::tpm('10','100','1000');
	if ((@tissuesearch > 1)){
		$conditional = Expression::logical();
	}
	my $tissuefiltering = "tissuefiltering=yes#".join(',',@tissuesearch)."#$tpm#$conditional";
	print "key: $tissuefiltering\n";
	return $tissuefiltering;
}

sub ask_go_filtering {
	my $rc = "";
	my $counter = 0;
	my $gofiltering;
	do {
		
		print "Do you want to apply GO filtering?\n";
		print "(1) no\n(2) yes\n";
		$rc = <>;
		#$rc = "\n".$rc;
		unless ($rc =~ /^[12]\n/){
			++$counter;
			if ($counter > 4){
				$rc = "1\n";
			}
		}
	}until ($rc =~ /^[12]\n/);
	if ($rc == 1){
		$gofiltering = 1;
	}
	if ($rc == 2){
		$gofiltering = 'yes';
	}
	if ($gofiltering eq 'yes'){
		$rc = "";
		do {
			
			print "Supply a p-value between 0.05 and 0.0000001:\n";
			$rc = <>;
			#$rc = "\n".$rc;
			unless ($rc >= 0.0000001 && $rc <= 0.05){
				++$counter;
				if ($counter > 4){
					$rc = "1\n";
				}
			}
		}until ($rc >= 0.0000001 && $rc <= 0.05);
	}
	return $gofiltering;
}
sub get_species_gene_no_output {
	my ($gen, $species) = @_;
	my @result;
	my $entrez_gene_id = PubMed::ncbi_genes($gen,$species);
	my @gene_ids_ensembl_ncbi;
	my $ncbi_symbol;
	my $ncbi_description;
	my $ens_species = Ask::species_to_ensembl_species($species);

	if ($entrez_gene_id){
		($ncbi_symbol, $ncbi_description) = PubMed::ncbi_gene_description($entrez_gene_id);
		unless ($species eq 'pig'){
			@gene_ids_ensembl_ncbi = Gene_Attributes::xref_to_ensembl_id($entrez_gene_id, $species);
		}
	}
	if (@gene_ids_ensembl_ncbi || $species eq 'pig'){
		if ($entrez_gene_id){
			foreach my $element (@gene_ids_ensembl_ncbi){
				push (@result, $element);
			}
		}
	}
	else {
	
		if  (Fetch_Ortholog::hgnc_symbol($gen)){
			my $refspecies = 'human';
			my $entrezgene;
			my ($entrez_gene_id2,$approved_name) = Fetch_Ortholog::hgnc_symbol($gen);
			my ($ortholog) = Fetch_Ortholog::ortholog($species, $gen, $refspecies);

			if ($ortholog){
				my @xrefs = Gene_Attributes::xref($species, $ortholog);
				foreach my $element (@xrefs){
					if ($element =~ /EntrezGene/){
						$element =~ s/EntrezGene\t//g;
						$entrezgene = $element;
					}
				}
				$entrez_gene_id = PubMed::ncbi_genes($entrezgene,$species);
				if ($entrez_gene_id){
					($ncbi_symbol, $ncbi_description) = PubMed::ncbi_gene_description($entrez_gene_id);
					@gene_ids_ensembl_ncbi = Gene_Attributes::xref_to_ensembl_id($entrez_gene_id, $species);
				}
			}
			if (@gene_ids_ensembl_ncbi){
					foreach my $element (@gene_ids_ensembl_ncbi){
					push (@result, $element);
				}
				$refspecies = $species;
			}
		}
	}
	return @result;
}
sub expression_filtering1 {
	my ($species,$tissuefiltering)=@_;
	my @genes = ();
	my $species_e = Expression::species($species);
	my @tissuesearch;
	my $tpm;
	my $conditional=1;
	if ($tissuefiltering =~ /=yes/){
		my @intarray = split('#',$tissuefiltering);
		@tissuesearch = split(',',$intarray[1]);
		$tpm = $intarray[2];
		$conditional = $intarray[3];
	
		my @ncbi_genes = Expression::expression_tissue($species_e,\@tissuesearch,$conditional,$tpm);
		foreach my $gene (@ncbi_genes){
			chomp $gene;
			my @result = get_species_gene_no_output($gene,$species);
			push (@genes, @result);
		}

	}
	return @genes;
}
sub check_ensemblgeneid {
	my ($id, $species) = @_;
	my $gen="";
	
	my $gene_adaptor = Bio::EnsEMBL::Registry->get_adaptor($species ,'core','Gene');
	
	$id = uc $id;
	
	if ($id){

		if ($gene_adaptor -> fetch_by_stable_id($id)){
	
			
			$gen = $id;
		}
	}
	return $gen;
}

sub expression_filtering {
	my ($species,$tissuefiltering,$generef)=@_;
	my @allgenes = @$generef;
	my @genes = ();
	my @tissuesearch;
	my $tpm;
	my $conditional=1;
	if ($tissuefiltering =~ /=yes/){
		my @intarray = split('#',$tissuefiltering);
		@tissuesearch = split(',',$intarray[1]);
		$tpm = $intarray[2];
		$conditional = $intarray[3];


		foreach my $gene (@allgenes){
			my @entrez_gene_id_array = Gene_Attributes::ensembl_id_to_entrez_gene_id($species,$gene);
			foreach my $entrez_gene_id (@entrez_gene_id_array){
				my ($expr_profiles_ref,$hprd_tissue_ref) = Expression::expression_gene($species,$entrez_gene_id);
				my @expression_profiles = @$expr_profiles_ref;
				foreach my $tissue (@expression_profiles){
					my @inttissue = split ("\t",$tissue);
					#$inttissue[0]</td><td>$inttissue[1]</td></tr>\n";
					foreach my $tissue_filter (@tissuesearch){
						if ($inttissue[0] eq $tissue_filter){
							if ($inttissue[1] >= $tpm){
								push(@genes,$gene);
							}
						}
					}
				}
				
			}
		}
	}
	if (@genes){
		@genes = Expression::unique_array_elements(@genes);
	}
	return @genes;
}


1;
