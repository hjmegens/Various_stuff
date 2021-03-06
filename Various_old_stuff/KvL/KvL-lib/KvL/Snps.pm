package Snps;

use strict;
use warnings;
#open(STDERR, ">myprogram.error") or die "cannot open error file: myprogram.error:$!\n";

sub get_variation_on_transcript {

	# Ensemble configuration file
	my ($organism,$transcript_id)=@_;

	my $transcript_adaptor = Bio::EnsEMBL::Registry->get_adaptor($organism,'core','Transcript');
	my $vf_adaptor = Bio::EnsEMBL::Registry->get_adaptor($organism, 'variation','VariationFeature');
	my $trv_adaptor = Bio::EnsEMBL::Registry->get_adaptor($organism, 'variation','TranscriptVariation');
	
	my $transcript = $transcript_adaptor->fetch_by_stable_id($transcript_id);
	my $trvs = $trv_adaptor->fetch_all_by_Transcripts([$transcript]);
	my @return=();
	foreach my $tv (@{$trvs}){
		#if (join(",",@{$tv->consequence_type}) =~ /(NON_SYNONYMOUS|UTR|SPLICE_SITE|FRAMESHIFT)/g){
		if (join(",",@{$tv->consequence_type}) =~ /(NON_SYNONYMOUS|SPLICE_SITE|FRAMESHIFT)/g){
			my @SNP = ($tv->variation_feature->variation_name,join(",",@{$tv->consequence_type}));
			push (@return, join("\t",@SNP));
		}
	
	}
	return @return;
}	

sub get_variation_on_slice{
	
	my ($organism,$chromosome,$start,$end)=@_;
	
	my $slice_adaptor = Bio::EnsEMBL::Registry->get_adaptor($organism,'core','Slice');
	my $vf_adaptor = Bio::EnsEMBL::Registry->get_adaptor($organism, 'variation','VariationFeature');
	
	my @return=();

	#################################################
	# detected a bug that crashed the program due to wrong calculation of positions
	# by Mirna module. Now only find variation if start <= end 24-04-7
	# ###############################################
	
	unless ($start > $end){
		
		my $slice = $slice_adaptor->fetch_by_region('chromosome', $chromosome,$start,$end);
		my $vfs = $vf_adaptor->fetch_all_by_Slice($slice); #return ALL variations defined in $slice
		foreach my $vf (@{$vfs}){
		    my @SNP = ($vf->variation_name, $vf->allele_string, $vf->start,$vf->end);
		    push (@return, join("\t", @SNP));
    		}
	}
	return @return;
}

sub get_SNP_info {
	
	my ($organism,$rsId) = @_;
	
	my $va_adaptor = Bio::EnsEMBL::Registry->get_adaptor($organism, 'variation','Variation');
	my $vf_adaptor = Bio::EnsEMBL::Registry->get_adaptor($organism, 'variation','VariationFeature');
	
	my $gene_adaptor = Bio::EnsEMBL::Registry->get_adaptor($organism,'core','Gene');
	
	# get Variation object

	my $var = $va_adaptor->fetch_by_name($rsId); #get the Variation from the database using the name
	my @snps=();
        # get all VariationFeature objects: might be more than 1 !!!
	foreach my $vf (@{$vf_adaptor->fetch_all_by_Variation($var)}){
		my $variation_name = $vf->variation_name();
            
        	my $consequence_type = join(",",@{$vf->get_consequence_type()});
		my $five_prime_flanking_sequence = substr($var->five_prime_flanking_seq,-10);
		my $allele_string = $vf->allele_string();
		my $three_prime_flanking_sequence = substr($var->three_prime_flanking_seq,0,10);
		my $chromosome = $vf->seq_region_name;
		my $variation_start = $vf->start;
		my $variation_end = $vf->end;
		my @snp = ($variation_name,$consequence_type,$five_prime_flanking_sequence,$allele_string,$three_prime_flanking_sequence,$chromosome,$variation_start,$variation_end);
		push (@snps, join("\t",@snp));
            
	}
	return @snps;
}

1;
	
	
		
