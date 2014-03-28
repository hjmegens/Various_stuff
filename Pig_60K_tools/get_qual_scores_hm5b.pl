#!/usr/bin/perl -w
use strict;
use warnings;
use DBI;

my $database = 'pig_hapmap2';
my $server = 'localhost';
my $user = 'root';
my $pwd='chicken';
my $pig_hapmap = DBI->connect("dbi:mysql:$database:$server", $user,$pwd);

#my $query = "select pop_name from sample_sheet5 group by pop_name";
open (TABLE1,">allstats_round5b.txt");

my @geluktspec = ();
my @specimens = fetch_specimens($pig_hapmap);

foreach my $specimen (@specimens){
	my $callrate =0;
	my $gcscore =0;
	my $ssinfo = fetch_ssinfo($specimen,$pig_hapmap);
	#$altbreed = fetch_altbreedinfo($specimen,$pig_hapmap);

	$gcscore = get_gcscore($specimen,$pig_hapmap);
	$callrate= get_callrate($specimen,$pig_hapmap);
	set_callrate($specimen,$pig_hapmap,$callrate);
	set_gcscore($specimen,$pig_hapmap,$gcscore);
	if ($callrate > 0.5){
		push (@geluktspec,$specimen);
	}
	print TABLE1 "$ssinfo\t$gcscore\t$callrate\n";
	print "$ssinfo\t$gcscore\t$callrate\n";
}
close (TABLE1);
exit;
sub fetch_specimens{
	my ($pig_hapmap)=@_;
	my $query = 'select dna_name from sample_sheet8 where dna_name like "101590%"';
	my $sql = $pig_hapmap->prepare($query);
	$sql->execute();
	my @specimens1 = ();
	while (my $row = $sql->fetchrow_arrayref) {
		my $spec = join("\t", @$row);
		#print join("\t", @$row), "\n";
		push (@specimens1 , $spec); 
	}
	return @specimens1;
}

sub fetch_ssinfo{
	my ($specimen,$pig_hapmap)=@_;
	my $query = "select * from sample_sheet8 where dna_name = ('$specimen')";
	my $sql = $pig_hapmap->prepare($query);
	$sql->execute();
	my $line = '';
	while (my $row = $sql->fetchrow_arrayref) {
		$line = join("\t", @$row);
		#print join("\t", @$row), "\n";
 
	}
	return $line;
}
sub get_gcscore{
	my ($specimen,$pig_hapmap)=@_;
	my $query = "select avg(gcscore) from allgenotypes16 where dna_name = '$specimen'";;
	my $sql = $pig_hapmap->prepare($query);
	$sql->execute();
	my $line = '';
	while (my $row = $sql->fetchrow_arrayref) {
		$line = join("\t", @$row);
		#print join("\t", @$row), "\n";
 
	}
	unless ($line){
		$line =0;
	}
	return $line;
}
sub set_gcscore{
	my ($specimen,$pig_hapmap,$gcscore)=@_;
	my $query = "update sample_sheet8 set avggcscore = '$gcscore' where dna_name = '$specimen'";;
	my $sql = $pig_hapmap->prepare($query);
	$sql->execute();
}
sub set_callrate{
	my ($specimen,$pig_hapmap,$callrate)=@_;
	my $query = "update sample_sheet8 set callrate = '$callrate' where dna_name = '$specimen'";;
	my $sql = $pig_hapmap->prepare($query);
	$sql->execute();
}


sub get_callrate{
	my ($specimen,$pig_hapmap)=@_;
	my $query = "select SNP from allgenotypes16 where dna_name = '$specimen' and gcscore>0.1";;
	my $sql = $pig_hapmap->prepare($query);
	$sql->execute();
	my $line = '';
	my @SNP1 = ();
	while (my $row = $sql->fetchrow_arrayref) {
		$line = join("\t", @$row);
		push (@SNP1 , $line);
		#print join("\t", @$row), "\n";
 
	}
	$query = "select SNP from hapmap2_call_rate where Call_Freq > 0";;
	$sql = $pig_hapmap->prepare($query);
	$sql->execute();
	$line = '';
	my @SNP2 = ();
	while (my $row = $sql->fetchrow_arrayref) {
		$line = join("\t", @$row);
		push (@SNP2 , $line);
		#print join("\t", @$row), "\n";
 
	}
	my $callrate = 0;
	if (@SNP1){
		my $ref1 = \@SNP1;
		my $ref2 = \@SNP2;
		my @SNPworked = shared_array_elements($ref1,$ref2);
		my $gelukt = scalar @SNPworked;
		$callrate = $gelukt/59895;
	}
	return $callrate;

	
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

sub fetch_nondups{
	my ($pop,$pig_hapmap)=@_;
	my $query = "select dna_name from sample_sheet5 where purpose not like '%duplicate%' and purpose not like '%repeat%'";
	my $sql = $pig_hapmap->prepare($query);
	$sql->execute();
	my @specimens1 = ();
	while (my $row = $sql->fetchrow_arrayref) {
		my $spec = join("\t", @$row);
		#print join("\t", @$row), "\n";
		push (@specimens1 , $spec); 
	}
	return @specimens1;
}
sub fetch_altbreedinfo{
	my ($specimen,$pig_hapmap)=@_;
	my $query = "select alternative_pop_name from sample_sheet8 where dna_name = ('$specimen')";
	my $sql = $pig_hapmap->prepare($query);
	$sql->execute();
	my $line = '';
	while (my $row = $sql->fetchrow_arrayref) {
		$line = join("\t", @$row);
		#print join("\t", @$row), "\n";
 
	}
	return $line;
}
sub get_breedinfo{
	my ($pop,$pig_hapmap)=@_;
	my $query = "select pop_name,alternative_pop_name,full_breed_name from sample_sheet8 where alternative_pop_name = '$pop' group by alternative_pop_name";
	my $sql = $pig_hapmap->prepare($query);
	$sql->execute();
	my $line = '';
	while (my $row = $sql->fetchrow_arrayref) {
		$line = join("\t", @$row);
		#print join("\t", @$row), "\n";
 
	}
	return $line;
}

