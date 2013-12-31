package Comparebyblast;
use strict;
use warnings;

sub get_old_and_new {
	my ($species, $mirna, $chromosome, $mirna_start, $mirna_end, $gene_transcript, $tempdir) = @_;
	
	my $slice_adaptor = Bio::EnsEMBL::Registry->get_adaptor($species,'core','Slice');
	my $gene_adaptor = Bio::EnsEMBL::Registry->get_adaptor($species,'core','Gene');
	my $transcript_adaptor = Bio::EnsEMBL::Registry->get_adaptor($species,'core','Transcript');
	
	open (TO_46, ">$tempdir/temp/to_46.txt");
	print TO_46 "$species\n$gene_transcript\n$chromosome\n$mirna_start\n$mirna_end";
	close (TO_46);
	
	`/usr/local/bin/get_from_46.pl $tempdir`;
	#system ('./to_40/get_from_40.pl');

	open (SMALL, "$tempdir/temp/seq_small_from46.txt");
	my ($sequence_small) = (<SMALL>);
	close (SMALL);	
	open (LARGE, "$tempdir/temp/seq_large_from46.txt");
	my ($sequence_large) = (<LARGE>);
	close (LARGE);
	
	chomp $sequence_small;
	chomp $sequence_large;
		
	my $refname = $gene_transcript."-".$mirna."-".$mirna_start."-".$mirna_end;
	open (MIRNA, ">$tempdir/temp/mirna_ref.txt");

	print MIRNA ">$tempdir/mirna_$refname\n".$sequence_large."\n";
	close (MIRNA);

	#print $gene_transcript."\n";
	
	my $transcript = $transcript_adaptor->fetch_by_stable_id($gene_transcript);
	if (($transcript)){
		my $strand = $transcript ->strand();
		#print $strand."\n";
		my $gene_start = $transcript ->start();
		my $gene_end = $transcript ->end();
		$chromosome = $transcript ->seq_region_name();

		#print "\nIN MAIN PROGRAM!\n$mirna_start : $mirna_end\t$gene_start : $gene_end\n";
		
		if ($strand == 1){
			my $slice = $slice_adaptor->fetch_by_region('chromosome', $chromosome, ($gene_end - 10000) , ($gene_end + 10000));
			my $sequence = $slice ->seq();
			open (OUT, ">$tempdir/temp/gene_ref.txt");
			print OUT ">$tempdir/gene_$refname\n".$sequence."\n";
			close (OUT);
		}
	
		if ($strand == -1){
			#print "$chromosome\n";
			my $slice = $slice_adaptor->fetch_by_region('chromosome', $chromosome, ($gene_start - 10000) , ($gene_start + 10000));
			my $sequence = $slice ->seq();
			open (OUT, ">$tempdir/temp/gene_ref.txt");
			print OUT ">$tempdir/gene_$refname\n".$sequence."\n";
			close (OUT);
		}
		do_blast($refname,$tempdir);

		get_positions($gene_start, $gene_end, $strand,$tempdir);
	}
	else {
		print "Transcript ID $gene_transcript no longer in 47!\n";
	}
	#print "\n\n==========================\n\n";
	
	


}

sub get_positions {

	my ($gene_start, $gene_end, $strand,$tempdir) = @_;
	my $mirna_start = 0;
	my $mirna_end = 0;

	my $in = new Bio::SearchIO(-format => 'blast', 
	                           -file   => "$tempdir/temp/mytest.out");
	while( my $result = $in->next_result ) {
		while( my $hit = $result->next_hit ) {
			while( my $hsp = $hit->next_hsp ) {
				if( $hsp->length('total') > 120 ) {
					if ( $hsp->percent_identity >= 98 ) {
						my $hit_name = $hit->name; 
						my $hsp_length = $hsp->length('total');
						my $percent_id = $hsp->percent_identity;
						my $start_hit = $hsp->start('hit');
						my $end_hit = $hsp->end('hit');
						my $start_query = $hsp->start('query');
						my $end_query = $hsp->end('query');
						my $strand_hit = $hsp->strand('hit');
						my $strand_query = $hsp->strand('query');
						
												
						if ($strand == 1){

							if ($start_query == 1) {
								$mirna_start = $gene_end - 10000 + $start_hit + 100;
								$mirna_end = $gene_end - 10000 + $end_hit - 100;
							}

							if ($start_query == -1) {
								$mirna_start = $gene_end - 10000 + $end_hit - 100;
								$mirna_end = $gene_end - 10000 + $start_hit + 100;
							}
						}

						if ($strand == -1){

							if ($start_query == 1) {
								$mirna_start = $gene_start - 10000 + $start_hit + 100;
								$mirna_end = $gene_start - 10000 + $end_hit - 100;
							}

							if ($start_query == -1) {
								$mirna_start = $gene_start - 10000 + $start_hit + 100;
								$mirna_end = $gene_start - 10000 + $end_hit - 100;
							}
						}
					}
				}
			}  
		}
	}
	#temporary workaround, test further 121207
	$mirna_start = $mirna_start-1;
	$mirna_end = $mirna_end -1;
	return ($mirna_start,$mirna_end);
}

sub do_blast {
	my ($refname,$tempdir)=@_;

	#`formatdb -i gene_ref.txt -p F -o T`;

	#`blastall -p blastn -d gene_ref.txt -i mirna_ref.txt -o mytest.out`;

	`bl2seq -p blastn -F F -j $tempdir/temp/gene_ref.txt -i $tempdir/temp/mirna_ref.txt -o $tempdir/temp/mytest.out`
}
1;
