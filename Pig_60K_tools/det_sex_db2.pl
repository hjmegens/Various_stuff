#!/usr/bin/perl -w
use strict;
use warnings;
use DBI;

open(STDERR, ">myprogram.error") or die "cannot open error file: myprogram.error:$!\n";

my $database = 'pig_hapmap2';
my $server = 'localhost';
my $user = 'anonymous';

my $pig_hapmap = DBI->connect("dbi:mysql:$database:$server", $user);
my $ID=0;

open(TABLE, ">genders.txt");
##################################
#get list of specimens from breed
##################################
my @allsnps = ();

my @xsnps = fetch_snps(19,$pig_hapmap);
my @ysnps = fetch_snps(20,$pig_hapmap);
my $snprefx = \@xsnps;
my $snprefy = \@ysnps;

my @specimens = fetch_specimens($pig_hapmap);


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

	$ID = make_table($hashref,$specimen,$snprefx,$snprefy,$ID,$pig_hapmap);

		
	#}
	
}

close (TABLE);

# Break connection with MySQL database

$pig_hapmap->disconnect;
close (STDERR);
# exit the program
exit;

sub make_table {
	my ($hashref,$specimen,$snprefx,$snprefy,$ID,$pig_hapmap)=@_;
	my %datahash = %$hashref;
	my @x_snps = @$snprefx;
	my @y_snps = @$snprefy;

	my $workedx = 0;
	my $workedy = 0;
	my $hetx = 0;
	my $altpop = get_official_pop_for_specimen_alt($pig_hapmap,$specimen);
	++$ID;
	my $label = get_final_sample_name_alt($pig_hapmap,$specimen);
	print "$label\n";
	$label =~ s/ //g;
			
	print TABLE "$altpop\t$label\t";
	my $sex = 'unknown';
	if ($label =~ /M\d\d$/){
		$sex = 'male';
	}
	elsif ($label =~ /F\d\d$/){
		$sex = 'female';
	}
	my $ysex = 'unknown';
	my $xsex = 'unknown';	
	
	foreach my $snp (@x_snps){


		my $allele1="0";
		my $allele2="0";
		my $allele1b="0";
		my $allele2b="0";
		
		my $key = $snp."_".$specimen;
		
		
		if (exists $datahash{$key}) {
			my $value = $datahash{$key};
			my @subdataelement = split (',', $value);
			$allele1b=$subdataelement[0];
			$allele2b=$subdataelement[1];	
	
			if ($allele1b eq "-") {
				$allele1b = 'N';}
			if ($allele2b eq "-") {
				$allele2b = 'N';}
		}			
		unless ($allele1b eq 'N'){
			++$workedx;
			unless ($allele1b eq $allele2b){
				++$hetx;
			}
		}	
				
		
					
		}
	#print "\t".$hetx/$workedx;
	if (($hetx/$workedx)>0.05){
		$xsex = 'female'
	}
	else {
		$xsex = 'male';
	}
	foreach my $snp (@y_snps){
		my $allele1="0";
		my $allele2="0";
		my $allele1b="0";
		my $allele2b="0";
		
		my $key = $snp."_".$specimen;
		if (exists $datahash{$key}) {
			my $value = $datahash{$key};
			my @subdataelement = split (',', $value);
			#$allele1=$subdataelement[0];
			$allele1b=$subdataelement[0];
			#$allele2=$subdataelement[1];	
			$allele2b=$subdataelement[1];	

			if ($allele1b eq "-") {
				$allele1b = 'N';}
			if ($allele2b eq "-") {
				$allele2b = 'N';}
		}			
		unless ($allele1b eq 'N'){
			++$workedy;
		}	
	
		
					
	}
	#print "\t".$workedy/(scalar @y_snps);
	if (($workedy/(scalar @y_snps))>0.2){
		$ysex = 'male';
	}
	else {
		$ysex = 'female';
	}
		
	print TABLE "\t$xsex\t$ysex";
	print "\t$xsex\t$ysex";
	if ($sex eq 'unknown'){
		if ($xsex eq $ysex){
			print TABLE "\tok";
			print "\tok";
		}
	}
		
	if ($sex eq $xsex){
		if ($sex eq $ysex){
			print TABLE "\tconfirmed";
			print "\tconfirmed";
		}
	}
	print TABLE "\n";
	print "\n";

	
	return $ID;

}

sub fetch_specimens{
	my ($pig_hapmap)=@_;
	my $query = "select dna_name from sample_sheet8 where purpose not like '%duplicate%' and purpose not like '%repeat%' and tree = 'yes' and callrate > 0.7";
	my $sql = $pig_hapmap->prepare($query);
	$sql->execute();
	my @specimens1 = ();
	while (my $row = $sql->fetchrow_arrayref) {
		my $spec = join("\t", @$row);
		push (@specimens1 , $spec); 
	}

	return @specimens1;
}


#############################
#get list of snps from target
#############################
sub fetch_snps {
	my ($target,$pig_hapmap)=@_;
	my $query = "select SNP from snps inner join hapmap2_call_rate using (SNP) where Chromosome = ('$target') and Call_Freq >0.1";
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


