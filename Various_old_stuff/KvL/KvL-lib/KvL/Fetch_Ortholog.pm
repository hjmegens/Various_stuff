package Fetch_Ortholog;

use strict;
use warnings;
use Data::Dumper;

sub hgnc_symbol {
	my $database = 'kvl';
	my $server = 'localhost';
	my $user = 'anonymous';
	#my $passwd = '******';
	#my $user = 'root';

	#my $kvl = DBI->connect("dbi:mysql:$database:$server", $user, $passwd);
	my $kvl = DBI->connect("dbi:mysql:$database:$server", $user);

	my ($putative_hgnc)=@_;
	my $query = "select entrez_gene_id, approved_name from hgnc_simple where approved_symbol = ('$putative_hgnc')";
	my $sql = $kvl->prepare($query);
	$sql->execute();
	my $hgnc_name;
	my $entrez_gene_id;
	while (my $row = $sql->fetchrow_arrayref) {
		my $row2 = join("\t", @$row);
		my @row2array = split ("\t",$row2);
		
		$entrez_gene_id = $row2array[0];
		$hgnc_name = $row2array[1];
	}
	return ($entrez_gene_id,$hgnc_name);
	$kvl->disconnect;
}

sub entrez_gene_id {
	my $database = 'kvl';
	my $server = 'localhost';
	my $user = 'anonymous';
	#my $passwd = '******';
	#my $user = 'root';

	#my $kvl = DBI->connect("dbi:mysql:$database:$server", $user, $passwd);
	my $kvl = DBI->connect("dbi:mysql:$database:$server", $user);

	my ($entrez_gene_id)=@_;
	my $query = "select approved_symbol from hgnc_simple where entrez_gene_id = ('$entrez_gene_id')";
	my $sql = $kvl->prepare($query);
	$sql->execute();
	my @return = ();
	while (my $row = $sql->fetchrow_arrayref) {
		my $hgnc_symbol = join("\t", @$row);
		push (@return , $hgnc_symbol); 
	}
	return @return;
	$kvl->disconnect;
}

sub mouse_entrez {
	my $database = 'kvl';
	my $server = 'localhost';
	my $user = 'anonymous';
	#my $passwd = '******';
	#my $user = 'root';

	#my $kvl = DBI->connect("dbi:mysql:$database:$server", $user, $passwd);
	my $kvl = DBI->connect("dbi:mysql:$database:$server", $user);

	my $human_gene="";

	my ($entrez_gene_id)=@_;
	my $query = "select human_entrez_gene from human_mouse_entrez where mouse_entrez_gene = ('$entrez_gene_id')";
	my $sql = $kvl->prepare($query);
	$sql->execute();
	my @results = ();
	
	while (my $row = $sql->fetchrow_arrayref) {
		my $human_entrez_id = join("\t", @$row);
		push (@results , $human_entrez_id); 
	}
	my ($result) = @results;
	if ($result){
		#print "WEL een resultaat!\n";
		($human_gene) = entrez_gene_id($result);
	}
	return $human_gene;
	$kvl->disconnect;
}

sub rat_entrez {
	my $database = 'kvl';
	my $server = 'localhost';
	my $user = 'anonymous';
	#my $passwd = '******';
	#my $user = 'root';

	#my $kvl = DBI->connect("dbi:mysql:$database:$server", $user, $passwd);
	my $kvl = DBI->connect("dbi:mysql:$database:$server", $user);

	my $human_gene="";

	my ($entrez_gene_id)=@_;
	my $query = "select human_entrez_gene from human_rat_entrez where rat_entrez_gene = ('$entrez_gene_id')";
	my $sql = $kvl->prepare($query);
	$sql->execute();
	my @results = ();
	
	while (my $row = $sql->fetchrow_arrayref) {
		my $human_entrez_id = join("\t", @$row);
		push (@results , $human_entrez_id); 
	}
	my ($result) = @results;
	if ($result){
		#print "WEL een resultaat!\n";
		($human_gene) = entrez_gene_id($result);
	}
	return $human_gene;
	$kvl->disconnect;
}

sub ortholog {
	my ($queryspecies, $querygen, $ref_organism) = @_;
	my $result="";
	my @genes = ();
	my $homology_type="";
	my $hum_chrom = "";
	my $hum_chrom_start = "";
	my $hum_chrom_end = "";
	my $descripton = "";
	my $identity = "";
	my $hugo="";

	my $slice_adaptor = Bio::EnsEMBL::Registry->get_adaptor($ref_organism,'core','Slice');
	my $gene_adaptor = Bio::EnsEMBL::Registry->get_adaptor($ref_organism,'core','Gene');
	my $member_adaptor = Bio::EnsEMBL::Registry->get_adaptor('Multi','compara','Member');
	my $homology_adaptor = Bio::EnsEMBL::Registry->get_adaptor('Multi', 'compara', 'Homology');
	
	
	unless ($querygen =~ /^ENS[A-Z]*G00[0-9]+/){
		@genes = @{$gene_adaptor->fetch_all_by_external_name($querygen)};
	}
	else {
		push (@genes,$gene_adaptor->fetch_by_stable_id($querygen));
	}

	foreach my $gene (@genes){
		my $gene_id = $gene -> stable_id();
		$hugo = $gene -> external_name();
		######################

		# first you have to get a Member object. In case of homology is a gene, in
		# case of family it can be a gene or a protein

		my $member = $member_adaptor -> fetch_by_source_stable_id("ENSEMBLGENE",$gene_id);
		
		#########################
		# rarely there is no compara-entry, not even for human. The script would crash
		# if a method was called on the empty object, taking down the whole script. I 
		# introduced the following check to see whether an object is returned 20-04-07
		# #######################
		
		if ($member) {
		
			$hum_chrom = $member->chr_name;
	       		$hum_chrom_start = $member->chr_start;
			$hum_chrom_end = $member->chr_end;
			$descripton = $member->description;
					
			my $taxon = $member->taxon;
			#print join ("; ", map { $taxon->$_ } qw(common_name genus species binomial classification))."\n";
		
			# then you get the homologies where the member is involved
	
			my $homologies = $homology_adaptor->fetch_by_Member($member);
	
			# That will return a reference to an array with all homologies (orthologues in
			# other species and paralogues in the same one)
			# Then for each homology, you can get all the Members implicated

			foreach my $homology (@{$homologies}) {
		
			# You will find different kind of description
			# UBRH, MBRH, RHS, YoungParalogues
			# see ensembl-compara/docs/docs/schema_doc.html for more details
	
				if ($homology->description =~ /ortholog_one2one/g){
					foreach my $member_attribute (@{$homology->get_all_Member_Attribute}){
	
			  		# for each Member, you get information on the Member specifically and in
			  		# relation to the homology relation via Attribute object
			 			my ($member, $attribute) = @{$member_attribute};
						my $taxon = $member->taxon;
						#print join "; ", map { $taxon->$_ } qw(common_name genus species binomial classification),"\n";
						my $common_name = $taxon->common_name;
						#print "$common_name\n";
						unless (($common_name)){
							$common_name="unknown"
						};
					 	if ($common_name eq $queryspecies){
							$homology_type = $homology->description."\t".$homology->subtype;
							
							# And if they are defined dN and dS related values
							#print join (" ", map { $member->$_ }  qw(stable_id taxon_id))."\n";
						
			 				$identity = join (" ", map { $attribute->$_ } qw(perc_id perc_pos perc_cov))."\n";
							$result = $member -> stable_id();
							#print "homology type: $homology_type\n";
						
						}
					}
				}
			}
			
			unless ($result){
				foreach my $homology (@{$homologies}) {
		
				# You will find different kind of description
				# UBRH, MBRH, RHS, YoungParalogues
				# see ensembl-compara/docs/docs/schema_doc.html for more details
	
					if ($homology->description eq "ortholog_one2many"){
						foreach my $member_attribute (@{$homology->get_all_Member_Attribute}){
		
				  		# for each Member, you get information on the Member specifically and in
				  		# relation to the homology relation via Attribute object
							
				 			my ($member, $attribute) = @{$member_attribute};
							my $taxon = $member->taxon;
							my $common_name = $taxon->common_name;
							#print "$common_name\n";
							unless (($common_name)){
								$common_name="unknown"
							};
						
					 		if ($common_name eq $queryspecies){
								$homology_type = $homology->description." ". $homology->subtype;
								
								# And if they are defined dN and dS related values
							
								#print join (" ", map { $member->$_ }  qw(stable_id taxon_id))."\n";
							
									
				 				$identity = join (" ", map { $attribute->$_ } qw(perc_id perc_pos perc_cov))."\n";
							
								$result = $member -> stable_id();
							
							}
						}
					}
				}
			}
		}
		else {
			print "No Compara entry for $querygen\n";
		}
			
		######################
	}
	
	return ($result, $hum_chrom, $hum_chrom_start, $hum_chrom_end, $descripton, $identity, $homology_type, $hugo);
}

sub hugo_to_entrez_gene_id {
	my $database = 'kvl';
	my $server = 'localhost';
	my $user = 'anonymous';
	#my $passwd = '******';
	#my $user = 'root';

	#my $kvl = DBI->connect("dbi:mysql:$database:$server", $user, $passwd);
	my $kvl = DBI->connect("dbi:mysql:$database:$server", $user);

	my ($hugo_name)=@_;
	my $query = "select entrez_gene_id from hgnc_simple where approved_symbol = ('$hugo_name')";
	my $sql = $kvl->prepare($query);
	$sql->execute();
	my @return = ();
	while (my $row = $sql->fetchrow_arrayref) {
		my $entrez_gene_id = join("\t", @$row);
		push (@return , $entrez_gene_id); 
	}
	return @return;
	$kvl->disconnect;
}

1;
