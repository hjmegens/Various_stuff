#!/usr/bin/perl -w
use strict;
use warnings;
use DBI;
use Getopt::Std;
#open(STDERR, ">myprogram.error") or die "cannot open error file: myprogram.error:$!\n";
my %opts = ();

#grab comandline options
getopt('ptsef', \%opts);
my $pop = $opts{p};
my $target = $opts{t};
my $start = $opts{s};
my $end = $opts{e};
my $filename = $opts{f};
my $database = 'pig_hapmap2';
my $server = 'localhost';
my $user = 'hapmapuser';
my $passwd = 'hapmapuser@1234';

my $pig_hapmap = DBI->connect("dbi:mysql:$database:$server", $user,$passwd);
my $ID=0;
#foreach my $pop (@pops){
my @snps = fetch_snps($target,$pig_hapmap);
unless ($target && @snps){
	die "no target, no snps! $!\n";
}
my @intsnps = ();
if ($start){
	for (my $i = $start; $i<=$end; ++$i){
		push (@intsnps,$snps[$i]);
	}
}
else {	
	@intsnps = @snps;
	$start=1;
}
	
my %datahash=();
my @specimens = ();
##############
if ($filename){
	open (INFILE, "$filename") or die "no such filename $filename, $!\n";
	my $firstline = <INFILE>;
	if ($firstline =~ m/specimens/){
		while (<INFILE>){
			my $tempid = $_;
			chomp $tempid;
			#print "official sample name: $tempid\n";
			push (@specimens, get_dna_name_from_final_sample_name($pig_hapmap,$tempid));
		}
	}
}
elsif ($pop){
	@specimens =fetch_specimens_from_pop($pop,$pig_hapmap);
}
else {
	die "no valid sample selection!\n";
}


mkdir "$target", 0755 or warn "cannot make directory $target: $!\n";



my $count=0;
foreach my $specimen (@specimens){
	print "genotype name: $specimen \n";


	my $query = "select SNP,dna_name,fwallele1,fwallele2 from allgenotypes16 where dna_name = '$specimen'";
	my $sql = $pig_hapmap->prepare($query);
	$sql-> execute();
	while (my $row = $sql->fetchrow_arrayref) {
		my ($snp,$sample,$allele1,$allele2) = @$row;
	
		my $key = $snp."_".$sample;
		my $value=$allele1.",".$allele2;
		
	
		$datahash{$key} = $value;
		++$count;
	}
}
print $count."\n";
my $hashref = \%datahash;
############
my $sampleref = \@specimens;
#foreach my $target (@targetsall){
$ID=0;

	
my $snpref = \@intsnps;

open(GOODSNP, ">$target/goodsnps_$target-$pop.txt");
print GOODSNP "$pop\t$target\t0\t";
$snpref = good_snps($hashref,$sampleref,$snpref,$start);
make_info_files($snpref,$pig_hapmap,$target,$pop);
print GOODSNP "\n";
close(GOODSNP);
@snps = @$snpref;


make_info_files($snpref,$pig_hapmap,$target,$pop);
@snps = @$snpref;

open(TABLE, ">$target/PHASE_$pop$target.txt");
print TABLE (@specimens)."\n";
print TABLE (@snps)."\n";
#print TABLE "P";
#make_info($snpref,$usda_sweep,$target);
#print TABLE "\n";
#make_info_files($snpref,$usda_sweep,$target);

print TABLE "P";

foreach my $snp (@snps){
	my $position = get_snp_position($snp,$pig_hapmap);
	print TABLE " $position";
}
print TABLE "\n";
my $i = 0;
while ($i<(@snps)){
	print TABLE "S";
	++$i;
	if ($i<(@snps)){
		print TABLE " ";
	}
}
print TABLE "\n";
$ID = make_table($hashref,$sampleref,$snpref,$ID);
close (TABLE);

undef %datahash;
undef $hashref;
# Break connection with MySQL database

$pig_hapmap->disconnect;
print "$pop => $target\n";
`fastPHASE -T10 -i -F -o$target/results$pop-$target $target/PHASE_$pop$target.txt`;
my $hapguess = "results$pop-$target"."_hapguess_indiv.out";

open (HAPLOS, ">$target/$pop-seqonly.txt");
open (RESULTS, "$target/$hapguess");
my $previous = "";
my $haplocounter = 0;
while (<RESULTS>){
	chomp $_;
	my $line = $_;
	if ($line =~ /^[ACGT] [ACGT] /){
		++$haplocounter;
		print HAPLOS "$previous"."_".$haplocounter."\t$line\n";
	}
	elsif ($line){
		$previous = $line;
		$haplocounter=0;
	}
}
close (HAPLOS);
close (RESULTS);	
		
#`cat $target/$hapguess | grep -P '^[ACGT] [ACGT] ' >$target/$pop-seqonly.txt`;
#close (STDERR);
# exit the program
exit;

sub make_table {
	my ($hashref,$specimenref,$snpref,$ID)=@_;
	my %datahash = %$hashref;
	my @specimens = @$specimenref;
	my @target_snps = @$snpref;
	
	foreach my $specimen (@specimens){
		my $altpop = get_official_pop_for_specimen($pig_hapmap,$specimen);
		my $label = get_final_sample_name($pig_hapmap,$specimen);

		my $array=[];
		++$ID;
		print TABLE "$label\n";
		#print "ID$ID\t$label\t0\t0\t0\t0\t";
		my $snpcount=0;
		foreach my $snp (@target_snps){
	
		
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
					$allele1b = '?';}
				#	$allele1b = 0;}
				#if ($allele2 eq "-") {
				#	$allele2b = 0;}
				if ($allele2b eq "-") {
					$allele2b = '?';}
			}
			else {
				$allele1b = '?';
				$allele2b = '?';
			}
							
			$array->[$snpcount][0] = $allele1b;
			$array->[$snpcount][1] = $allele2b;
			++$snpcount;	
			
		
					
		}
		my $i=0;
		while ($i < $snpcount){
			print TABLE $array->[$i][0];
			++$i;
			if ($i<$snpcount){
				print TABLE " ";
			}
		}
		$i=0;
		print TABLE "\n";
			while ($i < $snpcount){
			print TABLE $array->[$i][1];
			++$i;
			if ($i<$snpcount){
				print TABLE " ";
			}
		}
		print TABLE "\n";

	
	}
	return $ID;

}

sub fetch_specimens_old{
	my ($pop,$pig_hapmap)=@_;
	my $query = "select dna_name from sample_sheet inner join spec_succes using (dna_name) where sample_sheet.pop_name = ('$pop') and spec_succes.prop_failed < 0.05";
	my $sql = $pig_hapmap->prepare($query);
	$sql->execute();
	my @specimens = ();
	while (my $row = $sql->fetchrow_arrayref) {
		my $spec = join("\t", @$row);
		#print join("\t", @$row), "\n";
		push (@specimens , $spec); 
	}
	return @specimens;
}

sub fetch_specimens{
	my ($pop,$pig_hapmap)=@_;
	my $query = "select dna_name from sample_sheet where pop_name = ('$pop')";
	my $sql = $pig_hapmap->prepare($query);
	$sql->execute();
	my @specimens1 = ();
	while (my $row = $sql->fetchrow_arrayref) {
		my $spec = join("\t", @$row);
		#print join("\t", @$row), "\n";
		push (@specimens1 , $spec); 
	}
	$query = "select dna_name from pop$pop group by dna_name having avg(gcscore)>0.5";
	$sql = $pig_hapmap->prepare($query);
	$sql->execute();
	my @specimens2 = ();
	while (my $row = $sql->fetchrow_arrayref) {
		my $spec = join("\t", @$row);
		#print join("\t", @$row), "\n";
		push (@specimens2 , $spec); 
	}
	my $ref1 = \@specimens1;
	my $ref2 = \@specimens2;
	my @specimens = shared_array_elements($ref1,$ref2);
	return @specimens;
}




#############################
#get list of snps from target
#############################
sub fetch_snps {
	my ($target,$pig_hapmap)=@_;
	my $query = "select SNP from snps_build10 inner join hapmap2_call_rate using (SNP) where (Alt_Position = 0 or Alt_Chromosome = 'Uwgs') and Call_Freq >0.95 and Chromosome = '$target' order by Position";
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

sub make_info {
	
	my ($snpref,$pig_hapmap,$target)=@_;
	my @snps = @$snpref;
	foreach my $snp (@snps) {
		my $query = "select coordinate from target_snps where snp_name = ('$snp')";
		my $sql = $pig_hapmap->prepare($query);	
		$sql->execute();
		my @target_snps;
		while (my $row = $sql->fetchrow_arrayref) {
			my ($coordinate) = @$row;
			#print $snp."\t".$coordinate."\n";
			#print INFO $snp."\t".$coordinate."\n";
			print TABLE " $coordinate";
		}
		
	}
	#close (INFO);
	
}

sub make_info_files {
	
	my ($snpref,$pig_hapmap,$target,$pop)=@_;
	my @snps = @$snpref;
	open (INFO_SWEEP, ">$target/info_sweep_$target.txt");
	open (ANC_TAB, ">$target/anc_tab_$target-$pop.txt");
	print INFO_SWEEP "snpid\tchr\tWASHU1\n";

	foreach my $snp (@snps) {
		my ($chromosome,$coordinate)=get_snp_position($snp,$pig_hapmap);
		print INFO_SWEEP "$snp\t$chromosome\t$coordinate\n";
		my ($ancstate)=get_ancstate($pig_hapmap,$snp);
		print ANC_TAB "$snp\t$chromosome\t$coordinate\t$ancstate\n";
	}
	close (INFO_SWEEP);
	close (ANC_TAB);
}

sub get_ancstate {
	my ($pig_hapmap,$snp)=@_;
	my $query = "select maj_al_sv from anc_freqs where SNP = ('$snp') and maj_af_sv = 1";
	my $sql = $pig_hapmap->prepare($query);	
	$sql->execute();
	my $row = $sql->fetchrow_arrayref;
	my $ancstate;
	if ($row){
		$ancstate = join("\t", @$row);
	}
	else {$ancstate = "N";}

	return $ancstate;
}

sub get_snp_position {
	my ($snp,$pig_hapmap)=@_;
	my $query = "select Chromosome,Position from snps_build10 where SNP = ('$snp')";
	my $sql = $pig_hapmap->prepare($query);	
	$sql->execute();
	my $chromosome;
	my $coordinate;
	while (my $row = $sql->fetchrow_arrayref) {
		my $tar = join("\t", @$row);
		my @row2array2 = split("\t",$tar);
		$chromosome = $row2array2[0];
		$coordinate = $row2array2[1];
	}
	return ($chromosome,$coordinate);
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

sub get_dna_name_from_final_sample_name {

        my ($pig_hapmap,$specimen)=@_;
        my $dna_name = '';
        my $query = "select dna_name from master_sample_sheet inner join sample_sheet8 on (alternative_dna_name = sample_name_genotype) where final_sample_name = '$specimen'";
        my $sql = $pig_hapmap->prepare($query);
        $sql->execute();
        while (my $row = $sql->fetchrow_arrayref) {
             ($dna_name) = @$row;
	}
	return $dna_name;
}

sub fetch_specimens_from_pop{
	my ($pop,$pig_hapmap)=@_;
	my $query = "select sample_sheet8.dna_name from sample_sheet8 inner join master_sample_sheet on (alternative_dna_name = sample_name_genotype) where master_sample_sheet.pop_name = ('$pop') and sample_sheet8.purpose not like '%duplicate%' and sample_sheet8.purpose not like '%repeat%' and sample_sheet8.tree = 'yes' and sample_sheet8.callrate > 0.9";
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



sub good_snps {
	my ($hashref,$specimenref,$snpref,$start)=@_;
	my %datahash = %$hashref;
	my @specimens = @$specimenref;
	my @target_snps = @$snpref;

	my $numpops =0;
	my $totaalloci=0;
	my $i=$start-1;
	my @goodsnps=();
	foreach my $snp (@target_snps){
		
		++$i;
		my $freqA = 0;
		my $A=0;
		my $freqC = 0;
		my $C=0;
		my $freqG = 0;
		my $G=0;
		my $freqT = 0;
		my $T=0;
		
		
		my $value="";
		my @subdataelement=();
		my $numanimals=0;
		my $totaal=0;
		my $heterozygoot = 0;
		foreach my $specimen (@specimens){
			
			++$numanimals;


			my $allele1="0";
			my $allele2="0";
			my $allele1b="0";
			my $allele2b="0";
			
			my $key = $snp."_".$specimen;
			
			
			if (exists $datahash{$key}) {
				$value = $datahash{$key};
				@subdataelement = split (',', $value);
				$allele1=$subdataelement[0];
				$allele2=$subdataelement[1];
					
						
					
				unless ($allele1 eq $allele2) {
					unless ($allele1 eq "-"){
						++$heterozygoot;
					}
				}
		
				if ($allele1 eq "A") {
					++$A;}
				if ($allele1 eq "C") {
					++$C;}
				if ($allele1 eq "G") {
					++$G;}	
				if ($allele1 eq "T") {
					++$T;}
				if ($allele2 eq "A") {
					++$A;}
				if ($allele2 eq "C") {
					++$C;}	
				if ($allele2 eq "G") {
					++$G;}	
				if ($allele2 eq "T") {
					++$T;}

				if ($allele1 eq "-") {
					$allele1b = 0;}
				if ($allele2 eq "-") {
					$allele2b = 0;}
					
				unless ($allele2 eq "-") {
					++$totaal;
					#++$numanimals;
				}
			}			
		
			
		}
				
		unless (($totaal/$numanimals)<0.8) {
			print GOODSNP " $snp($i)";
			push(@goodsnps,$snp)
		}
		
		
	}
	my $goodsnpref = \@goodsnps;
	return($goodsnpref);
	
}


sub get_official_pop_for_specimen {

        my ($pig_hapmap,$specimen)=@_;
        my $alternative_pop_name = '';
        my $query = "select master_sample_sheet.pop_name from master_sample_sheet inner join sample_sheet8 on (alternative_dna_name = sample_name_genotype) where dna_name = '$specimen'";
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

