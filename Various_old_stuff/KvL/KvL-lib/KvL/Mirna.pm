package Mirna;

use strict;
use warnings;


sub miranda {
	my ($species, $transcript, $tempdir)=@_;
	my ($three_utr_start, $three_utr_end, $strand, $three_utr_length, $numexonsfor3utr) = Gene_Attributes::get_3utr($species, $transcript,$tempdir);
	`/usr/local/bin/miranda /usr/local/lib/kvl_lib/mirna-lib.txt $tempdir/temp/my3utr.txt >$tempdir/temp/mirna-out.txt`;
	
	my @exon_positions = Gene_Attributes::exon_positions($species, $transcript);

	my $spec="";
	my @mirna_sites=();
	if ($species eq 'chicken'){$spec = 'gga';}
	if ($species eq 'cattle'){$spec = 'bta';}
	if ($species eq 'pig'){$spec = 'ssc';}
	if ($species eq 'human'){$spec = 'hsa';}

	open (MIRNA, "$tempdir/temp/mirna-out.txt") or die "cannot open error file: mirna-out.txt:$!\n";
	my $teller=0;
	while (<MIRNA>) {
		chomp $_;
		my $line="";
	
		$line=$_;
		if ($line =~ /^>$spec/) {
			my @results = split (/\s/, $line);
			my $mirna = $results[0];
			my $score = $results[2];
			my $start = $results[7];
			my $end = $results[8];
			my $mirna_chr_start="";
			my $mirna_chr_end="";
			if ($strand == -1){
				#corrigeren voor multiple exonen
				$mirna_chr_start = $three_utr_start - $end;
				$mirna_chr_end = $three_utr_start - $start;	
			}
			if ($strand == 1){
				$mirna_chr_start = $three_utr_start + $start;
				$mirna_chr_end = $three_utr_start + $end;	
			}
			push (@mirna_sites, "$mirna\t$score\t$mirna_chr_start\t$mirna_chr_end"); 
			#print $line."\n";
			++$teller
		}
	}
	close (MIRNA);
	return @mirna_sites;


	#print "There are ".$teller." miRNA hits\n";

}

sub fetch_mirna_target{
	
	my $database = 'kvl';
	my $server = 'localhost';
	#my $user = 'root';
	my $user = 'anonymous';
	#my $passwd = '******';

	#my $kvl = DBI->connect("dbi:mysql:$database:$server", $user, $passwd);
	my $kvl = DBI->connect("dbi:mysql:$database:$server", $user);


	my ($species,$transcript_id)=@_;
	my $query = "select mirna_id,chr,start,end,score,pvalue_og from mirna_target_$species where transcript_id = ('$transcript_id')";
	my $sql = $kvl->prepare($query);
	$sql->execute();
	my @mirnas = ();
	while (my $row = $sql->fetchrow_arrayref) {
		my $mirna = join("\t", @$row);
		#print join("\t", @$row), "\n";
		push (@mirnas , $mirna); 
	}
	return @mirnas;
	$kvl->disconnect;
}

sub compare_mirbase_with_new {

	my ($int, $species, $transcript_id,$tempdir) = @_;

	my @row = split("\t", $int);
	my $mirna = $row[0];
	my $chromosome = $row[1];
	my $mirna_start = $row[2];
	my $mirna_end = $row[3];
	
	#print "oud: $mirna_start-$mirna_end\t";

	($mirna_start, $mirna_end) = Comparebyblast::get_old_and_new($species,$mirna,$chromosome,$mirna_start,$mirna_end,$transcript_id,$tempdir);
	#print "nieuw: $mirna_start-$mirna_end\n";

	return ($mirna,$chromosome,$mirna_start,$mirna_end);


}

1;

