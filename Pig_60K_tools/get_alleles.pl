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
my @allsnps = ();

my @snps = fetch_snps($pig_hapmap);

foreach my $snp (@snps){
	my @alleles = ();
	my $info = '';
	my $query = "select fwallele1 from allgenotypes16 where SNP = '$snp' group by fwallele1";
	my $sql = $pig_hapmap->prepare($query);
	$sql-> execute();
	while (my $row = $sql->fetchrow_arrayref) {
		my $allele = join("\t", @$row);
		unless ($allele eq '-'){
			push (@alleles , $allele);
		} 
	}
	$query = "select fwallele2 from allgenotypes16 where SNP = '$snp' group by fwallele2";
	$sql = $pig_hapmap->prepare($query);
	$sql-> execute();
	while (my $row = $sql->fetchrow_arrayref) {
		my $allele = join("\t", @$row);
		unless ($allele eq '-'){
			push (@alleles , $allele);
		}
	}
	$query = "select * from snps_build10 where SNP = '$snp'";
	$sql = $pig_hapmap->prepare($query);
	$sql-> execute();
	while (my $row = $sql->fetchrow_arrayref) {
		$info = join("\t", @$row);
	}
	if ($info){
		my($snpfound,$chromfound,$posfound,$altchr,$altpos)=split("\t",$info);
		if ($chromfound eq 'Uwgs'){
			$info = "$snp\t0\t0";
		}
		elsif ($altpos==0){
			$info = "$snpfound\t$chromfound\t$posfound";
		}
		else {
			$info = "$snpfound\t$chromfound\t0";
		}
	}
	else {
		$info = "$snp\t0\t0";

	}
	#foreach my $allele (@alleles){
		#print "$allele\n";
	#}

	@alleles = unique_array_elements(@alleles);
	print "$snp\t$info\t[";
	my $count = 0;
	my $lastallele = '';
	foreach my $allele (@alleles){
		if ($count == 0){
			print "$allele";
			$lastallele=$allele;
		}
		else {
			print "/$allele";
		}
		++$count; 
	}
	if ($count == 1){
		print "/$lastallele";
	}
	if ($count == 0){
		print "N/N";
	}
	print "]\n";
}
$pig_hapmap->disconnect;

#close (STDERR);
# exit the program
exit;


#############################
#get list of snps from target
#############################
sub fetch_snps {
	my ($pig_hapmap)=@_;
	my $query = "select SNP from snps";
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

sub get_breed_name {

        my ($pig_hapmap,$specimen)=@_;
        my $alternative_pop_name = '';
        my $query = "select breed from sample_info where dna_name = '$specimen'";
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


