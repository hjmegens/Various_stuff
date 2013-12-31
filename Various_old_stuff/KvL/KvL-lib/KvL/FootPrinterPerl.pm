package FootPrinterPerl;
use strict;
use warnings;

sub main {
	my ($species, $gen, $tempdir) = @_;
#print "Kom ik er wel IN!??\n\n";
	open (FASTA, ">$tempdir/temp/fastafile.fasta");
	#my @input = ('chicken','MC4R','human');
	my @compare_species = ("human\tHUMAN", "house mouse\tMOUSE",  "Norway rat\tRAT", "dog\tDOG" , "cattle\tCOW" , "chicken\tCHICKEN");

		my @to_recalc = ();
	#if ($species eq 'cattle'){push (@compare_species, "cattle\tCOW");}
	#if ($species eq 'chicken'){push (@compare_species, "chicken\tCHICKEN");}

	foreach my $twocspecies (@compare_species){
		my @int = split ("\t",$twocspecies);
		my $cspecies=$int[0];
		my $footspecies=$int[1];
		#print "\nrefspecies: $species \t gene: $gen\nSpecies: $cspecies\t";
		my @ref = Fetch_Ortholog::ortholog($cspecies, $gen, $species);
		my $gene_id = $ref[0];

		if ($gene_id) {
			#print "Gene_ID: $gene_id\n\n";

			my($chromosome,$start, $end, $strand) = Gene_Attributes::position($cspecies, $gene_id);
		
			if ($cspecies eq $species){
				@to_recalc = ($chromosome, $start, $end, $strand);
			}
			#transcript($cspecies, $gene_id);
	
			#print "chromosome $chromosome - start $start - end $end - strand $strand\n";
		
			if ($strand == -1){
				my $slice_adaptor = Bio::EnsEMBL::Registry->get_adaptor($cspecies,'core','Slice');
				my $slice = $slice_adaptor->fetch_by_region('chromosome', $chromosome, $end, ($end+700));
				my $sequpstream = $slice ->get_repeatmasked_seq()->seq();
				my $revcom = reverse $sequpstream;
				$revcom =~ tr/ACGTacgt/TGCAtgca/;
				
				print FASTA ">$footspecies\n$revcom\n";
			}
			
			if ($strand == 1){
				my $slice_adaptor = Bio::EnsEMBL::Registry->get_adaptor($cspecies,'core','Slice');
				my $slice = $slice_adaptor->fetch_by_region('chromosome', $chromosome, ($start-700), $start);
				my $sequpstream = $slice ->get_repeatmasked_seq()->seq();
			
				print FASTA ">$footspecies\n$sequpstream\n";
			}
		}
		#else {
		#	print "No ortholog\n\n";
		#}
	}
	close (FASTA);
	my $maxmutations = 1;
	my $size = 8;
	
	do_FootPrinter($maxmutations,$size,$tempdir);
	
	my @positions = find_positions($species, $tempdir);
	
	if (scalar @positions < 3){
		print "second attempt:\n";
		$maxmutations++;
		do_FootPrinter($maxmutations,$size,$tempdir);
		@positions = find_positions($species, $tempdir);
		if (scalar @positions < 3){
			print "third attempt:\n";
			$size--;
			do_FootPrinter($maxmutations,$size,$tempdir);
			@positions = find_positions($species,$tempdir);
		}
	}
	@positions = recalc_positions(\@positions,\@to_recalc); 
	return @positions;
}

sub do_FootPrinter {
	my($maxmutations,$size,$tempdir) = @_;

	#`FootPrinter temp/fastafile.fasta kvl_lib/tree_of_life -max_mutations $maxmutations -size $size -triplet_filtering -post_filtering`;
	`/usr/local/bin/FootPrinter $tempdir/temp/fastafile.fasta /usr/local/lib/kvl_lib/tree_of_life -max_mutations $maxmutations -size $size -triplet_filtering -post_filtering`;
}

sub find_positions {

	my ($species, $tempdir) = @_;
	my $footspecies = "";

	if ($species eq 'cattle'){
		$footspecies = "COW";
	}
	if ($species eq 'chicken'){
		$footspecies = "CHICKEN";
	}
	if ($species eq 'human'){
		$footspecies = "HUMAN";
	}
	open (FOOTOUT, "$tempdir/temp/fastafile.fasta.seq.txt");
	my $conselements = "";
	while (<FOOTOUT>){
		chomp $_;
		if ($_ eq ">$footspecies") {
			my $firstline = "";
			my $element = "";
			my $seq = "";
			
			do {
				
				chomp $firstline;
				chomp $element;
				$seq .= $firstline;
				$conselements .= $element;
				
				$firstline = <FOOTOUT>;
			
				$element = <FOOTOUT>;
			
				<FOOTOUT>;
				<FOOTOUT>;

				my @test = split ("",$firstline);
				if (scalar @test == 0){
					$firstline = "";
				}
	
			} until ($firstline !~ m/^[acgtn]/g);
			#print "$seq\n";
			#print "$conselements\n";
			#print CONTROLE "$seq\n";
			#print CONTROLE "$conselements\n";
		}
	}
	
	close (FOOTOUT);
	
	my @poselements = ();
	while ($conselements =~ m/\S/g){
		
		my $start_element = pos $conselements;
		my $end_element = 0;
		$start_element++;
	
		if ($conselements =~ m/\s/g){
		
			$end_element = pos $conselements;
		}
		push (@poselements, "$start_element\t$end_element");
	}
	#foreach my $poselement (@poselements){
	#	print $poselement."\n";
	#}
	return @poselements;
}

sub transcript {

	my ($cspecies, $gene_id) = @_;
	my @transcript = Gene_Attributes::transcript($cspecies, $gene_id);
	foreach my $trans (@transcript){
		my @sub = split("\t",$trans);
		my $transcript_id = $sub[0];
		print "\nTranscript ID: $transcript_id:\n";
		my @five_utr = Gene_Attributes::get_5utr($cspecies, $transcript_id);
		if (@five_utr) {
			#print######################
			print "A 5UTR with length $five_utr[3] has been annotated, start $five_utr[0] : end $five_utr[1] on strand $five_utr[2]\n";	
			######################print#
		}
		else {
			#print######################
			print "No 5UTR annotated\n";
			######################print#
		}
		my @exons = Gene_Attributes::exon_positions($cspecies, $transcript_id);
		foreach my $exon (@exons){
			print $exon."\n";
		}
	}
}

sub recalc_positions {

	my ($intpos,$int_to_recalc) = @_;
	my @positions = @$intpos;
	my @chrompos = @$int_to_recalc;
	my $chromosome = $chrompos[0];
	my $chr_start = $chrompos[1]; 
	my $chr_end = $chrompos[2]; 
	my $strand = $chrompos[3];
	my @recalc_positions = ();
	
	if ($strand == -1){
		foreach my $position (@positions) {
			my @sub = split("\t",$position);
			my $start = $sub[0];
			my $end = $sub[1];
			my $recalc_start = $chr_end + 700 - $end;
			my $recalc_end = $chr_end + 700 - $start;
			push (@recalc_positions, "$recalc_start\t$recalc_end");
		}
			
	}
		
	if ($strand == 1){
		foreach my $position (@positions) {
			my @sub = split("\t",$position);
			my $start = $sub[0];
			my $end = $sub[1];
			my $recalc_start = $chr_start - 700 + $start;
			my $recalc_end = $chr_start -700 + $end;
			push (@recalc_positions, "$recalc_start\t$recalc_end");
		}
	}

	return @recalc_positions;
}
1;

