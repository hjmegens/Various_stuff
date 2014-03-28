#!/usr/bin/perl -w
use strict;
use warnings;
use DBI;
use Getopt::Std;
my %opts = ();
getopt('fbc', \%opts);
my $filename = $opts{f};
my $basename = $opts{b};
my $callrate_cutoff = $opts{c};
#open(STDERR, ">myprogram.error") or die "cannot open error file: myprogram.error:$!\n";

my $database = 'pig_hapmap2';
my $server = 'localhost';
my $user = 'anonymous';

my $pig_hapmap = DBI->connect("dbi:mysql:$database:$server", $user);
my $ID=0;


#my @targetsall = (1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18);
my @targetsall = ('X');
unless ($basename){
	die "you did not supply a valid basename!\n"
}	


open(TABLE, ">$basename.ped");
##################################
#get list of specimens from breed
##################################
my @allsnps = ();

open(INFO, ">$basename.map");

foreach my $target (@targetsall){
	my @snps = fetch_snps($target,$pig_hapmap);
	my $snpref = \@snps;
	push (@allsnps,@snps);
	make_info_file($snpref,$pig_hapmap,$target);
}
close (INFO);
my @specimens = ();

if ($filename){
	open (INFILE, "$filename") or die "no such filename $filename, $!\n";
	my $firstline = <INFILE>;
	if ($firstline eq "specimens"){
		while (<INFILE>){
			my $tempid = $_;
			chomp $tempid;
			#print "official sample name: $tempid\n";
			push (@specimens, get_dna_name_from_final_sample_name($pig_hapmap,$tempid));
		}
	}
	elsif ($firstline =~ m/specimens_dna_name/){
		while (<INFILE>){
			my $tempid = $_;
			chomp $tempid;
			#print "official sample name: $tempid\n";
			my $callrate = confirm_dna_name($pig_hapmap,$tempid);
			if ($callrate > $callrate_cutoff){
				print "$tempid $callrate\n";
				push (@specimens, $tempid);
			}
			else {
				print "$tempid: callrate too low $callrate\n";
			
			}
		}
	}

	elsif ($firstline =~ m/pops/){
		while (<INFILE>){
			my $tempid = $_;
			chomp $tempid;
			push (@specimens, fetch_specimens_from_pop($tempid,$pig_hapmap));
		}
	}
	else {
		die "no valid inputfile!\n";
	}
}
else {
	@specimens = fetch_specimens($pig_hapmap);
}

foreach my $specimen (@specimens){
	print "genotype name: $specimen corresponds to official name: ";

	my %datahash=();

	my $query = "select SNP,dna_name,fwallele1,fwallele2 from allgenotypes16 where dna_name = '$specimen'";
	my $sql = $pig_hapmap->prepare($query);
	$sql-> execute();
	while (my $row = $sql->fetchrow_arrayref) {
		my ($snp,$sample,$allele1,$allele2) = @$row;
	
		my $key = $snp."_".$sample;
		my $value=$allele1.",".$allele2;
		#print "!!$key!!$value!!\n";
	
		$datahash{$key} = $value;
	}
	my $hashref = \%datahash;

	my $ID=0;
	my $snpref = \@allsnps;

	$ID = make_table($hashref,$specimen,$snpref,$ID,$pig_hapmap);

		
	#}
	
}

close (TABLE);

# Break connection with MySQL database

$pig_hapmap->disconnect;

#close (STDERR);
# exit the program
exit;

sub make_table {
	my ($hashref,$specimen,$snpref,$ID,$pig_hapmap)=@_;
	my %datahash = %$hashref;
	my @target_snps = @$snpref;
	my $altpop = get_official_pop_for_specimen_alt($pig_hapmap,$specimen);
	++$ID;
	my $label = get_final_sample_name_alt($pig_hapmap,$specimen);
	print "$label\n";
	$label =~ s/ //g;
			
	print TABLE "$altpop\t$label\t0\t0\t0\t0";
		
	foreach my $snp (@target_snps){
	
		my $allele1="0";
		my $allele2="0";
		my $allele1b="N";
		my $allele2b="N";
			
		my $key = $snp."_".$specimen;
		#print "**$specimen**$snp**\t";		
		if (exists $datahash{$key}) {
			#print 'yes';
			my $value = $datahash{$key};
			my @subdataelement = split (',', $value);
			$allele1b=$subdataelement[0];
			$allele2b=$subdataelement[1];	
	
			if ($allele1b eq "-") {
				$allele1b = 'N';}
			if ($allele2b eq "-") {
				$allele2b = 'N';}
		}			
					
		print TABLE "\t$allele1b  $allele2b";
		#print "\t$allele1b  $allele2b";
			
	}
	print TABLE "\n";
	return $ID;

}

sub fetch_specimens{
	my ($pig_hapmap)=@_;
	#my $query = "select dna_name from sample_sheet8 where purpose not like '%duplicate%' and purpose not like '%repeat%' and purpose not like '%outgroup%' and tree = 'yes' and callrate > 0.7";
	my $query = "select dna_name from sample_sheet8 where purpose not like '%duplicate%' and purpose not like '%repeat%' and familystatus != 'F1' and tree = 'yes' and callrate > 0.7";

	my $sql = $pig_hapmap->prepare($query);
	$sql->execute();
	my @specimens1 = ();
	while (my $row = $sql->fetchrow_arrayref) {
		my $spec = join("\t", @$row);
		push (@specimens1 , $spec); 
	}

	return @specimens1;
}

sub fetch_specimens_in_table{
	my ($db,$pig_hapmap)=@_;
	my $query = "select dna_name from sample_sheet8 where genotype_table_name = ('$db') and purpose not like '%duplicate%' and purpose not like '%repeat%' and tree = 'yes' and callrate > 0.6";
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
sub fetch_specimens_from_pop{
	my ($pop,$pig_hapmap)=@_;
	my $query = "select dna_name from sample_sheet8 where alternative_pop_name = ('$pop') and purpose not like '%duplicate%' and purpose not like '%repeat%' and tree = 'yes' and callrate > 0.6";
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

sub fetch_all_dbs{
	my ($pig_hapmap)=@_;
	my $query = "select genotype_table_name from sample_sheet8 where purpose not like '%duplicate%' and purpose not like '%repeat%' and tree = 'yes' and callrate > 0.6 group by genotype_table_name";
	my $sql = $pig_hapmap->prepare($query);
	$sql->execute();
	my @dbs = ();
	while (my $row = $sql->fetchrow_arrayref) {
		my $spec = join("\t", @$row);
		#print join("\t", @$row), "\n";
		push (@dbs , $spec); 
	}

	return @dbs;
}


#############################
#get list of snps from target
#############################
sub fetch_snps {
	my ($target,$pig_hapmap)=@_;
	#my $query = "select SNP from snps_build10_2 inner join hapmap2_call_rate using (SNP) where Chromosome = 'X' and Alt_Position = 0 and Position < 90000000 and Position > 66000000 and Call_Freq > 0.90 order by Position";
	my $query = "select SNP from snps_build10_2 inner join hapmap2_call_rate using (SNP) where Chromosome = 'X' and Alt_Position = 0 and Call_Freq > 0.90 order by Position";
	my $sql = $pig_hapmap->prepare($query);	
	$sql->execute();
	my @target_snps;
	while (my $row = $sql->fetchrow_arrayref) {
		my $tar = join("\t", @$row);
		#print join("\t", @$row), "\n";
		push (@target_snps , $tar); 
	}
	return @target_snps;
}

sub make_info_file {
	
	my ($snpref,$pig_hapmap,$target)=@_;
	my @snps = @$snpref;
	foreach my $snp (@snps) {
		my $query = "select Position from snps_build10_2 where SNP = ('$snp')";
		my $sql = $pig_hapmap->prepare($query);	
		$sql->execute();
		my @target_snps;
		while (my $row = $sql->fetchrow_arrayref) {
			my ($coordinate) = @$row;
			#print $snp."\t".$coordinate."\n";
			print INFO $target."\t".$snp."\t0\t".$coordinate."\n";
		}
		
	}
	
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

sub get_official_pop_for_specimen_alt {

        my ($pig_hapmap,$specimen)=@_;
        my $alternative_pop_name = '';
        my $query = "select alternative_pop_name from sample_sheet8 where dna_name = '$specimen'";
        my $sql = $pig_hapmap->prepare($query);
        $sql->execute();
        while (my $row = $sql->fetchrow_arrayref) {
             ($alternative_pop_name) = @$row;
	}
	return $alternative_pop_name;
}
sub get_final_sample_name {

        my ($pig_hapmap,$specimen)=@_;
        my $alternative_dna_name = '';
        my $query = "select final_sample_name from master_sample_sheet inner join sample_sheet8 on (alternative_dna_name = sample_name_genotype) where dna_name = '$specimen'";
        my $sql = $pig_hapmap->prepare($query);
        $sql->execute();
        while (my $row = $sql->fetchrow_arrayref) {
             ($alternative_dna_name) = @$row;
	}
	return $alternative_dna_name;
}
sub get_final_sample_name_alt {

        my ($pig_hapmap,$specimen)=@_;
        my $alternative_dna_name = '';
        my $query = "select alternative_dna_name from sample_sheet8 where dna_name = '$specimen'";
        my $sql = $pig_hapmap->prepare($query);
        $sql->execute();
        while (my $row = $sql->fetchrow_arrayref) {
             ($alternative_dna_name) = @$row;
	}
	return $alternative_dna_name;
}

sub get_dna_name_from_final_sample_name {

        my ($pig_hapmap,$specimen)=@_;
        my $dna_name = '';
        my $query = "select dna_name from master_sample_sheet inner join sample_sheet8 on (alternative_dna_name = sample_name_genotype) where alternative_dna_name = '$specimen'";
        my $sql = $pig_hapmap->prepare($query);
        $sql->execute();
        while (my $row = $sql->fetchrow_arrayref) {
             ($dna_name) = @$row;
	}
	return $dna_name;
}
sub confirm_dna_name {

        my ($pig_hapmap,$specimen)=@_;
        my $dna_name = '';
        my $query = "select callrate from sample_sheet8 where dna_name = '$specimen'";
        my $sql = $pig_hapmap->prepare($query);
        $sql->execute();
        while (my $row = $sql->fetchrow_arrayref) {
             ($dna_name) = @$row;
	}
	return $dna_name;
}

sub get_pop_name_from_altpop {

        my ($pop,$pig_hapmap)=@_;
        my $alternative_pop_name = '';
        my $query = "select pop_name from sample_sheet8 where alternative_pop_name = ('$pop') group by alternative_pop_name";
        my $sql = $pig_hapmap->prepare($query);
        $sql->execute();
        while (my $row = $sql->fetchrow_arrayref) {
             ($alternative_pop_name) = @$row;
	}
	return $alternative_pop_name;
}

sub get_genotype_table_name {

        my ($pop,$pig_hapmap)=@_;
        my @all_dbs = ();
        my $query = "select genotype_table_name from sample_sheet8 where pop_name = ('$pop') group by genotype_table_name";
        my $sql = $pig_hapmap->prepare($query);
        $sql->execute();
        while (my $row = $sql->fetchrow_arrayref) {
		my ($db) = @$row;
		push (@all_dbs, $db); 
	}
	return @all_dbs;
}
 
