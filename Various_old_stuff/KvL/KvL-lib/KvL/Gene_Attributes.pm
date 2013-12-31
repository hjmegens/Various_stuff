package Gene_Attributes;

use strict;
use warnings;

sub description {
	my ($ref_organism, $stable_id) = @_;
	print $ref_organism."\t".$stable_id."\n";
	my $gene_adaptor = Bio::EnsEMBL::Registry->get_adaptor($ref_organism,'core','Gene');
	my $gene = $gene_adaptor->fetch_by_stable_id($stable_id);
	my $description = $gene->description();
	return $description;

}
sub ensembl_external_name {
	my ($ref_organism, $stable_id) = @_;
	print $ref_organism."\t".$stable_id."\n";
	my $gene_adaptor = Bio::EnsEMBL::Registry->get_adaptor($ref_organism,'core','Gene');
	my $gene = $gene_adaptor->fetch_by_stable_id($stable_id);
	my $name = $gene->external_name();
	return $name;

}


sub xref {
	my ($ref_organism, $stable_id) = @_;
	my $gene_adaptor = Bio::EnsEMBL::Registry->get_adaptor($ref_organism,'core','Gene');
	my $gene = $gene_adaptor->fetch_by_stable_id($stable_id);
	my @xrefs = @{$gene -> get_all_DBEntries()};
	my @return;
	foreach my $xref (@xrefs){
		my $entry = $xref->dbname()."\t".$xref->display_id;
		push (@return, $entry);
	}
	my @transcripts = @{$gene -> get_all_Transcripts()};
	foreach my $trans (@transcripts){
		my @xrefs = @{$trans -> get_all_DBEntries()};
		foreach my $xref (@xrefs){
			my $entry = $xref->dbname()."\t".$xref->display_id;
			push (@return, $entry);
		}
	}
	return @return;
}

sub transcript {
	my ($ref_organism, $stable_id) = @_;
	my $gene_adaptor = Bio::EnsEMBL::Registry->get_adaptor($ref_organism,'core','Gene');
	my $gene = $gene_adaptor->fetch_by_stable_id($stable_id);
	my @return;
	my @transcripts = @{$gene->get_all_Transcripts()};
		foreach my $trans (@transcripts){
		
			my $trans_stable_id = $trans -> stable_id();
			my $trans_name = $trans->external_name();
			my @exons = @{$trans->get_all_Exons()};
			push (@return,"$trans_stable_id\t$trans_name\t".(@exons));
		}
	return @return;

}

sub position {

	my ($ref_organism, $stable_id) = @_;
	my $gene_adaptor = Bio::EnsEMBL::Registry->get_adaptor($ref_organism,'core','Gene');
	my $gene = $gene_adaptor -> fetch_by_stable_id($stable_id);
	
	my $start = $gene->start();
	my $end = $gene->end();
	my $chromosome = $gene->seq_region_name();
	my $strand = $gene->strand();
	my @return = ($chromosome,$start, $end, $strand);
	return @return;
}


sub get_3utr {
	my ($ref_organism, $stable_id,$tempdir) = @_;
	my $transcript_adaptor = Bio::EnsEMBL::Registry->get_adaptor($ref_organism,'core','Transcript');
	my $trans = $transcript_adaptor->fetch_by_stable_id($stable_id);
	#print STDERR Dumper($trans)."\n";
	my $three_utr = $trans -> three_prime_utr();
	if (($three_utr)){
		my @exon_positions = exon_positions($ref_organism, $stable_id);
		my $num_exons = scalar @exon_positions;
		#print STDERR Dumper($three_utr)."\n";
	       	my $three_utr_seq = $three_utr ->seq();
		open (THREE_UTR, ">$tempdir/temp/my3utr.txt");
		print THREE_UTR ">$stable_id 3utr\n$three_utr_seq";
		close (THREE_UTR);
		my $three_utr_start = "";
		my $three_utr_end = "";
		my $trans_start = $trans ->start();
		my $trans_end = $trans ->end();
		my $trans_strand = $trans ->strand();
		my $three_utr_length = length($three_utr_seq);
		my $numexonsfor3utr=0;
		if ($trans_strand == -1){
			my $leftover = $three_utr_length;
			my $remain_lastexon = -1;
			
			while ($remain_lastexon < 0) {
				
				my @lastexon = split("\t",$exon_positions[$num_exons-1-$numexonsfor3utr]);
				$remain_lastexon = $lastexon[2]-$lastexon[1]-$leftover;
				
				if ($remain_lastexon >= 0){
					$three_utr_start = $lastexon[1]+$leftover;
				}
				$leftover = -1*$remain_lastexon;
				++$numexonsfor3utr;
				 
			}
			
			
			$three_utr_end = $trans_start;	
		}
		if ($trans_strand == 1){
			my $leftover = $three_utr_length;
			my $remain_lastexon = -1;
		
			while ($remain_lastexon < 0) {
				
				my @lastexon = split("\t",$exon_positions[$num_exons-1-$numexonsfor3utr]);
				$remain_lastexon = $lastexon[2]-$lastexon[1]-$leftover;
				
				if ($remain_lastexon >= 0){
					$three_utr_start = $lastexon[2]-$leftover;
				}
				$leftover = -1*$remain_lastexon;
				++$numexonsfor3utr;
			}
			$three_utr_end = $trans_end;	
		}
		
		return ($three_utr_start,$three_utr_end,$trans_strand,$three_utr_length,$numexonsfor3utr);
	}
	else { return;}
}
	
sub regulatory_elements {	
	my ($organism, $stable_id) = @_;
	
	my $gene_adaptor = Bio::EnsEMBL::Registry->get_adaptor($organism,'core','Gene');
	my $transcript_adaptor = Bio::EnsEMBL::Registry->get_adaptor($organism,'core','Transcript');
	my $gene = $gene_adaptor -> fetch_by_stable_id($stable_id);

	my @reg_elements=();
	
	my @reg_features = @{$gene -> get_all_regulatory_features()};
	foreach my $reg_feature (@reg_features){
		push (@reg_elements, $reg_feature -> name()."\t".$reg_feature -> start()."\t".$reg_feature -> end()."\t".$reg_feature -> factor -> name());
	}
	my @transcripts = @{$gene->get_all_Transcripts()};

	foreach my $trans (@transcripts){
		my @reg_features_trans = @{$trans -> fetch_all_regulatory_features()};
		foreach my $reg_feature_trans (@reg_features_trans){
			push (@reg_elements, $reg_feature_trans -> name()."\t".$reg_feature_trans -> start()."\t".$reg_feature_trans -> end()."\t".$reg_feature_trans -> factor -> name());
		}
	}
	return @reg_elements;		
}

sub get_5utr {
	my ($ref_organism, $stable_id,$tempdir) = @_;
	my $transcript_adaptor = Bio::EnsEMBL::Registry->get_adaptor($ref_organism,'core','Transcript');
	my $trans = $transcript_adaptor->fetch_by_stable_id($stable_id);
	#print STDERR Dumper($trans)."\n";
	my $five_utr = $trans -> five_prime_utr();
	if (($five_utr)){
		#print STDERR Dumper($three_utr)."\n";
	       	my $five_utr_seq = $five_utr ->seq();
		open (FIVE_UTR, ">$tempdir/temp/my5utr.txt");
		print FIVE_UTR ">$stable_id 5utr\n$five_utr_seq";
		close (FIVE_UTR);
		my $five_utr_start = "";
		my $five_utr_end = "";
		my $trans_start = $trans ->start();
		my $trans_end = $trans ->end();
		my $trans_strand = $trans ->strand();
		my $five_utr_length = length($five_utr_seq);
		if ($trans_strand == -1){
			$five_utr_start = $trans_end;
			$five_utr_end = $trans_end - $five_utr_length;	
		}
		if ($trans_strand == 1){
			$five_utr_end = $trans_start + $five_utr_length;
			$five_utr_start = $trans_start;	
		}
		
		return ($five_utr_start,$five_utr_end,$trans_strand,$five_utr_length);
	}
	else { return;}
}

sub exon_positions {
	my ($ref_organism, $stable_id) = @_;
	my $transcript_adaptor = Bio::EnsEMBL::Registry->get_adaptor($ref_organism,'core','Transcript');
	my $trans = $transcript_adaptor->fetch_by_stable_id($stable_id);
	my @exons = (@{$trans -> get_all_Exons()});
	my @return = ();
	foreach my $exon (@exons){
		my $id = $exon -> stable_id();
		my $exonstart = $exon -> start();
		my $exonend = $exon -> end();
		my $exoninfo = "$id\t$exonstart\t$exonend";
		push (@return, $exoninfo);
		
		
	}
	return @return;
}

sub xref_to_ensembl_id {
	my ($xref, $species) = @_;
	my @return;
	my $gene_adaptor = Bio::EnsEMBL::Registry->get_adaptor($species,'core','Gene');
	my @genes = @{$gene_adaptor->fetch_all_by_external_name($xref)};
	foreach my $gene (@genes){
		my $gene_id = $gene -> stable_id();
		if (($gene_id)){
			my @tests = ensembl_id_to_entrez_gene_id($species,$gene_id);
			foreach my $test (@tests){
				if ($test){
					if ($test eq $xref){
						push (@return, $gene_id);
					}
				}
		
			}
		}
	}
	return @return;
}

sub ensembl_id_to_entrez_gene_id {
	my ($species, $stable_id) = @_;
	my @return;
	my $gene_adaptor = Bio::EnsEMBL::Registry->get_adaptor($species,'core','Gene');
	my $gene = $gene_adaptor->fetch_by_stable_id($stable_id);
	my @xrefs = @{$gene -> get_all_DBEntries('EntrezGene')};
	foreach my $xref (@xrefs){
		my $entry = $xref->display_id;
		my $entrez_gene_id = PubMed::ncbi_genes($species,$entry);
		push (@return, $entrez_gene_id);
	}
	my @transcripts = @{$gene -> get_all_Transcripts()};
	foreach my $trans (@transcripts){
		my @xrefs = @{$trans -> get_all_DBEntries('EntrezGene')};
		foreach my $xref (@xrefs){
			my $entry = $xref->display_id;
			my $entrez_gene_id = PubMed::ncbi_genes($entry,$species);

			push (@return, $entrez_gene_id);
		}
	}
	unless (@return){
		my $gene_name = $gene->external_name();	
		my $entrez_gene_id = PubMed::ncbi_genes($gene_name,$species);

		push(@return,$entrez_gene_id);
	}
	@return = unique_array_elements(@return);
	return @return;
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

1;
