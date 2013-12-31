package PubMed;

use strict;
use warnings;

use Data::Dumper;
use LWP::Simple;

	
sub pubmed {
	
	my ($query, $wantabstract, $fh, $fhht,$species,$opt)=@_;
	my $eutils	= "http://eutils.ncbi.nlm.nih.gov/entrez/eutils";
	my @results=();
	my @gene_names=();
	my @allabstracts =();
		
	$query =~ s/ and / AND /g;
	$query =~ s/ or / OR /g;
	$query =~ s/ /+/g;

	print "$query\n";

	my $esearch = "$eutils/esearch.fcgi?" .
              "db=pubmed&retmax=1&usehistory=y&term=";

	my $esearch_result = get($esearch . $query);

	#print "\nESEARCH RESULT: $esearch_result\n";

	$esearch_result =~ 
	  m|<Count>(\d+)</Count>.*<QueryKey>(\d+)</QueryKey>.*<WebEnv>(\S+)</WebEnv>|s;

	my $Count    = $1;
	my $QueryKey = $2;
	my $WebEnv   = $3;

	#print "Count = $Count; QueryKey = $QueryKey; WebEnv = $WebEnv\n";
	print "There are $Count pubmed hits\n";
	
	my $currentlimit = 200;
	my $currentpause = 4;
	my $hour = (localtime)[2];
	if ($hour > 23 || $hour < 11){
		$currentpause = 2;
		$currentlimit = 5000;
	}
	my $wday = (localtime)[6];
	if ($wday == 6 || $wday == 0){
		$currentpause = 2;
		$currentlimit = 5000;
	}
	
	#remove limits
	if ($opt eq 'unlocked'){
		print "you have altered the restrictions by entering the magic word!\n";
		$currentpause = 1;
		$currentlimit = 10000;
	#
	}
	print "\nNOTE: Current record retrieval rate set at 1 every $currentpause seconds\n\n";
	print $fhht "\n<h3>NOTE: Current record retrieval rate set at 1 every $currentpause seconds</h3\n";

	my $retstart;
	my $startnumber =0;
	$startnumber = $startnumber + $Count -$currentlimit;
	if ($startnumber < 0) {$startnumber = 0};
	if ($startnumber > 0) {
		print $fhht "\n".'<!--';
		for(my $filler = 0; $filler < 94; ++$filler) {
			print $fhht 'fillerfillerfillerfillerfillerfiller';
		}
 
		print $fhht '-->'."\n";
		print "\n---------------\nYour query returned more results than the current limit allows\n";
		print $fhht "Your query returned more results than the current limit allows<br>\n";
		print "Only the last $currentlimit results will be processed\n";
		print $fhht "<h3>Only the last $currentlimit results will be processed</h3>\n";
		print "Note that this limit has been set to protect overburdening NCBI server\n";
		print $fhht "Note that this limit has been set to protect overburdening NCBI server<br>\n";
		print "during working hours USA ET\n";
		print $fhht "during working hours USA ET<br>\n";
		print "Limit will be set to 200 between  11AM and 11PM localtime\n";
		print $fhht "Limit will be set to 200 between  11AM and 11PM localtime<br>\n";
		print "Limit will be set to 5000 between 11PM and 11AM localtime and during weekends\n";
		print $fhht "Limit will be set to 5000 between 11PM and 11AM localtime and during weekends<br>\n";
		print "Current localtime is ".scalar (localtime)."\n---------------\n";
		print $fhht "Current localtime is ".scalar (localtime)."<br><hr>";
	}

	for($retstart = $startnumber; $retstart < $Count; ++$retstart) {
		my $num_genes=0;
		my @tempresults;
		my $efetch = "$eutils/efetch.fcgi?" . "rettype=uilist&retmode=text&retstart=$retstart&retmax=1&" .
               "db=pubmed&query_key=$QueryKey&WebEnv=$WebEnv";
		my $efetch_result = get($efetch);
		my $abstract;
		
		chomp $efetch_result;
		#print $efetch_result."\n";
  		my $elink = "$eutils/elink.fcgi?usehistory=y&id=$efetch_result&cmd=pubmed_gene&dbFrom=pubmed&db=gene";

		my $elink_result = get($elink);
		while ($elink_result =~ /<Link>\n\t\t\t<Id>(\d+)<\/Id>\n\t\t<\/Link>/g){
			my $entrez_gene_id = $1;
			my $human_gene = mouse_rat_human_entrez_to_hugo($entrez_gene_id);
			if ($human_gene) {
				push (@gene_names,$human_gene);
				my ($ortholog) = Fetch_Ortholog::ortholog($species, $human_gene,'human');
				if ($ortholog){
					push (@results,$ortholog);
					++$num_genes;
					push (@tempresults,$human_gene);
				}
							}
			my $species_gene = ncbi_genes_rev($entrez_gene_id,$species);
			if ($species_gene) {
				my @species_ensembl = Ask::get_species_gene($species_gene,$fh,$fhht,$species);
				push (@gene_names,$species_gene);
				if (@species_ensembl){
					push (@results,@species_ensembl);
					++$num_genes;
					push (@tempresults,$species_gene);
				}
			}		
		}
		if ($wantabstract eq 'yes'){
			if (@tempresults){
				my $abstract_efetch= "$eutils/efetch.fcgi?" . "rettype=abstract&retmode=text&retstart=$retstart&retmax=1&" . 
					"db=pubmed&query_key=$QueryKey&WebEnv=$WebEnv";

				$abstract = get($abstract_efetch);

				print "\n+++++++++++++++++\n$abstract\n---------------\nassociated gene(s):";
				$abstract = $abstract . "\n\nassociated gene(s):";
				foreach my $element(@tempresults){
					print "\t$element";
					$abstract = $abstract . "\t$element";

				}
				push (@allabstracts, $abstract);
				print "\n+++++++++++++++++\n\n";
			}
			
		}
		print "pubmed hit " . ($retstart+1) . " (PubMed id = $efetch_result) has $num_genes genes associated\n";
		#print $elink_result."\n";
  		#print "(".($retstart+1) . "): $efetch_result\n";
		sleep ($currentpause);
	}
	return (\@results,\@allabstracts);
	
}

sub mouse_rat_human_entrez_to_hugo {
	my ($result) = @_;
	
	my ($human_gene) = Fetch_Ortholog::entrez_gene_id($result);
	unless ($human_gene){
		$human_gene = Fetch_Ortholog::mouse_entrez($result);
		#if ($human_gene) { $human_gene = 'mouse'.$human_gene;}

	}
	unless ($human_gene){
		$human_gene = Fetch_Ortholog::rat_entrez($result);
		#if ($human_gene) { $human_gene = 'rat'.$human_gene;}


	}
	return $human_gene;
}
sub pubmed_kvl {
	my $database = 'kvl';
	my $server = 'localhost';
	my $user = 'anonymous';

	my $kvl = DBI->connect("dbi:mysql:$database:$server", $user);

	my ($query, $wantabstract, $fh, $fhht,$retspecies)=@_;
	my $eutils	= "http://eutils.ncbi.nlm.nih.gov/entrez/eutils";
	my @results=();
	my @allabstracts =();
	my $teller=0;
		
	$query =~ s/ and / AND /g;
	$query =~ s/ or / OR /g;
	$query =~ s/ /+/g;

	print "$query\n";

	my $esearch = "$eutils/esearch.fcgi?" .
              "db=pubmed&retmax=1&usehistory=y&term=";

	my $esearch_result = get($esearch . $query);

	#print "\nESEARCH RESULT: $esearch_result\n";

	$esearch_result =~ 
	  m|<Count>(\d+)</Count>.*<QueryKey>(\d+)</QueryKey>.*<WebEnv>(\S+)</WebEnv>|s;

	my $Count    = $1;
	my $QueryKey = $2;
	my $WebEnv   = $3;

	#print "Count = $Count; QueryKey = $QueryKey; WebEnv = $WebEnv\n";
	print "There are $Count pubmed hits\n";
	$esearch = "$eutils/esearch.fcgi?" .
              "db=pubmed&retmax=$Count&term=";
	$esearch_result = get($esearch . $query);

	while ($esearch_result =~ /<Id>(\d+)<\/Id>/g){
		my $ncbi_species_id;
		my $entrez_gene_id;
		my $PubMed_id;

		++$teller;
		my @tempresults;
		my $query = "select * from gene2pubmed where PubMed_id = (?)";
		
		my $sql = $kvl->prepare($query);
		$sql ->execute($1);
		my $num_genes=0;

		while (my $row = $sql->fetchrow_arrayref) {
			my $row2 = join("\t", @$row);
			my @row2array = split ("\t",$row2);
			$ncbi_species_id = $row2array[0];
			$entrez_gene_id = $row2array[1];
			$PubMed_id = $row2array[2];
			if ($entrez_gene_id){
				my $human_gene = mouse_rat_human_entrez_to_hugo($entrez_gene_id);

				if ($human_gene) {
					push (@results,$human_gene);
					++$num_genes;
					push (@tempresults,$human_gene);
				}
			}

		}


		my $abstract;
							
				
		if ($wantabstract eq 'yes'){
			if (@tempresults){
				my $abstract_efetch= "$eutils/efetch.fcgi?" . "rettype=abstract&retmode=text&retmax=1&" . 
					"db=pubmed&id=$PubMed_id";

				$abstract = get($abstract_efetch);

				print "\n+++++++++++++++++\n$abstract\n---------------\nassociated gene(s):";
				$abstract = $abstract . "\n\nassociated gene(s):";
				foreach my $element(@tempresults){
					print "\t$element";
					$abstract = $abstract . "\t$element";

				}
				push (@allabstracts, $abstract);
				print "\n+++++++++++++++++\n\n";
			}
			
		}
		print "pubmed hit " . ($teller) . " (PubMed id = $PubMed_id) has $num_genes genes associated\n";
		#print $elink_result."\n";
  		#print "(".($retstart+1) . "): $efetch_result\n";
		
	}
	return (\@results,\@allabstracts);
	
}

sub species_to_ncbi_species_id {
	my ($species) = @_;
	my $database = 'kvl';
	my $server = 'localhost';
	my $user = 'anonymous';
	my $ncbi_species_id;
	my $kvl = DBI->connect("dbi:mysql:$database:$server", $user);
	my $query = "select ncbi_species_id from ncbi_species where trivial_name = '$species'";

	my $sql = $kvl->prepare($query);
	$sql ->execute();
	
	while (my $row = $sql->fetchrow_arrayref) {
		my $row2 = join("\t", @$row);
		my @row2array = split ("\t",$row2);
		$ncbi_species_id = $row2array[0];
		
	}
	return $ncbi_species_id;
}

sub ncbi_genes {
	my ($gene_name, $species)  = @_;
	my $species_id = species_to_ncbi_species_id($species);
	#print "$species_id\t$species\n";
	my $entrez_gene_id;
	my $database = 'kvl';
	my $server = 'localhost';
	my $user = 'anonymous';
	my $kvl = DBI->connect("dbi:mysql:$database:$server", $user);
	my $query = "select entrez_gene_id from ncbi_genes where ncbi_species_id ='$species_id' and ncbi_symbol = '$gene_name'";
	my $sql = $kvl->prepare($query);
	$sql ->execute();
	
	while (my $row = $sql->fetchrow_arrayref) {
		my $row2 = join("\t", @$row);
		my @row2array = split ("\t",$row2);
		$entrez_gene_id = $row2array[0];

	}
	return $entrez_gene_id;
}

sub ncbi_gene_description{

	my ($entrez_gene_id) = @_;
	my $database = 'kvl';
	my $server = 'localhost';
	my $user = 'anonymous';
	my $kvl = DBI->connect("dbi:mysql:$database:$server", $user);
	my $query = "select ncbi_symbol, ncbi_gene_description from ncbi_gene_description where entrez_gene_id = '$entrez_gene_id'";
	my $sql = $kvl->prepare($query);
	$sql ->execute();
	
	my $ncbi_symbol;
	my $ncbi_gene_description;
	while (my $row = $sql->fetchrow_arrayref) {
		my $row2 = join("\t", @$row);
		my @row2array = split ("\t",$row2);
		$ncbi_symbol = $row2array[0];
		$ncbi_gene_description = $row2array[1];

	}
	return ($ncbi_symbol, $ncbi_gene_description);
}
sub ncbi_genes_rev {
	my ($entrez_gene_id, $species)  = @_;
	my $species_id = species_to_ncbi_species_id($species);
	#print "$species_id\t$species\n";
	my $entrez_gene_name;
	my $database = 'kvl';
	my $server = 'localhost';
	my $user = 'anonymous';
	my $kvl = DBI->connect("dbi:mysql:$database:$server", $user);
	my $query = "select ncbi_symbol from ncbi_genes where ncbi_species_id ='$species_id' and entrez_gene_id = '$entrez_gene_id'";
	my $sql = $kvl->prepare($query);
	$sql ->execute();
	
	while (my $row = $sql->fetchrow_arrayref) {
		my $row2 = join("\t", @$row);
		my @row2array = split ("\t",$row2);
		$entrez_gene_name = $row2array[0];

	}
	return $entrez_gene_name;
}


1;
