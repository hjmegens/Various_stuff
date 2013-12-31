package CloverPerl;
use strict;
use warnings;

sub main {
	
	my ($species, $gene_id,$tempdir) = @_;
	open (FASTA, ">$tempdir/temp/in.fa");

	#print "Gene_ID: $gene_id\t";

	my($chromosome,$start, $end, $strand) = Gene_Attributes::position($species, $gene_id);

	#print "chromosome $chromosome - start $start - end $end - strand $strand\n";
	
	if ($strand == -1){
		my $slice_adaptor = Bio::EnsEMBL::Registry->get_adaptor($species,'core','Slice');
		my $slice = $slice_adaptor->fetch_by_region('chromosome', $chromosome, $end, ($end+700));
		my $sequpstream = $slice ->get_repeatmasked_seq()->seq();
		my $revcom = reverse $sequpstream;
		$revcom =~ tr/ACGTacgt/TGCAtgca/;
	
		print FASTA ">$species$gene_id\n$revcom\n";
	}
	
	if ($strand == 1){
		my $slice_adaptor = Bio::EnsEMBL::Registry->get_adaptor($species,'core','Slice');
		my $slice = $slice_adaptor->fetch_by_region('chromosome', $chromosome, ($start-700), $start);
		my $sequpstream = $slice ->get_repeatmasked_seq()->seq();
		
		print FASTA ">$species$gene_id\n$sequpstream\n";
	}
	close (FASTA);

	do_Clover($tempdir);
	
	my @positions = find_positions($species,$tempdir);
	
	my @to_recalc = ($chromosome, $start, $end, $strand);

	@positions = recalc_positions(\@positions,\@to_recalc); 

	return @positions;

	foreach my $position (@positions){
		print "$position\n";
	}
}

sub do_Clover {
	my ($tempdir)=@_;
	`/usr/local/bin/clover -n -t 0.05 /usr/local/lib/kvl_lib/jaspar2005core $tempdir/temp/in.fa >$tempdir/temp/cloverout.txt`;
	#`clover -n -t 0.05 /home/bioroot/bin/kvl_lib/jaspar2005core temp/in.fa >temp/cloverout.txt`;
}

sub find_positions {

	my ($species, $tempdir) = @_;
	my @poselements = ();
	
	open (CLOVOUT, "$tempdir/temp/cloverout.txt");
	
	while (<CLOVOUT>){
		my $nextline = $_;
		chomp $nextline;
		my @test = split ("",$nextline);
		if (scalar @test == 0){
			$nextline = "";
		}
		if ($nextline =~ m/^>$species/g) {
			$nextline = <CLOVOUT>;
			chomp $nextline;
			@test = split ("",$nextline);
			if (scalar @test == 0){
				$nextline = "";
			}
			
			while (scalar @test > 0) {

				#print "$nextline\n";

				$nextline =~ m/^(.+\w)\s\s+(\d+)\s-\s+(\d+)\s+(\+|-)\s+(\w+)\s\s+\d+\.\d+$/g;

				my $tf = $1;
				my $tfbs_start = $2;
				my $tfbs_end = $3;
				my $plusminus = $4;
				my $tfbs_seq = $5;
				$tf =~ s/^\s+//g;
				my $element = "$tf\t$tfbs_start\t$tfbs_end\t$plusminus\t$tfbs_seq";
				push (@poselements, $element);
				
				$nextline = <CLOVOUT>;
				chomp $nextline;
				@test = split ("",$nextline);
				if (scalar @test == 0){
					$nextline = "";
				}
				
	
			} 
			
		}
	}
	close (CLOVOUT);
	return @poselements;
	

	

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
			my $tf = $sub[0];
			my $start = $sub[1];
			my $end = $sub[2];
			my $plusminus = $sub[3];
			my $tfbs_seq = $sub[4];
			my $recalc_start = $chr_end + 700 - $end;
			my $recalc_end = $chr_end + 700 - $start;
			if ($plusminus eq "+"){
				push (@recalc_positions, "$tf\t$recalc_start\t$recalc_end\t$tfbs_seq");
			}
		}
			
	}
		
	if ($strand == 1){
		foreach my $position (@positions) {
			my @sub = split("\t",$position);
			my $tf = $sub[0];
			my $start = $sub[1];
			my $end = $sub[2];
			my $plusminus = $sub[3];
			my $tfbs_seq = $sub[4];
			my $recalc_start = $chr_start - 700 + $start;
			my $recalc_end = $chr_start -700 + $end;
			if ($plusminus eq "+"){
				push (@recalc_positions, "$tf\t$recalc_start\t$recalc_end\t$tfbs_seq");
			}
		}
	}

	return @recalc_positions;
}
1;

