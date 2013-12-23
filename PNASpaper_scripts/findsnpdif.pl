#!/usr/bin/perl -w
use strict;
use warnings;
use Getopt::Std;
my %opts = ();

$opts{b}='100000';
$opts{f}='infile';
getopt('fb123', \%opts);
my $file = $opts{f};
my $binsize=$opts{b};
my $one = $opts{1};
my $two = $opts{2};
my $three = $opts{3};
open(FILE, $file) or die "can not open $file $!\n";
my $firstline = <FILE>;
chomp $firstline;
close(FILE);
my @firstelements = split("\t",$firstline);
my $count = 0;
my $testcount=0;
unless($one && $two){
	die "You did not provide three names. Exiting.\n";
}
my @one1 = split(' ',$one);
my @two2 = split(' ',$two);
my $totaal1 = scalar @one1;
my $totaal2 = scalar @two2;
my @positions3=();
if ($three){
	my @three3 = split(' ',$three);
	my $totaal3 = scalar @three3;
	@positions3 = findposinmatrix(\@firstelements,\@three3);
}
my @positions1 = findposinmatrix(\@firstelements,\@one1);
my @positions2 = findposinmatrix(\@firstelements,\@two2);

open(FILE, $file) or die "can not open $file $!\n";
$firstline = <FILE>;
#my @check = split("\t",$firstline);
#print "check: $check[$onecount]\t$check[$twocount]\t$check[$threecount]\n";
#my $outfiletmp = 'tmp'.$outfile;
open(OUT, ">testout.txt");
my $snpsgroup1=0;
my $snpsgroup2=0;
my $shared = 0;
my $fixed = 0;
my $numlines=0;
while (<FILE>){
	++$numlines;
	#print "line number: $numlines\n";
	my $mislukt1 = 0;
	my $mislukt2 = 0;
	my $mislukt3 = 0;
	my $line = $_;
	chomp $line;
	my @int = split("\t",$line);
	my $chrom=$int[0];
	$chrom =~ s/Ssc10_2_//;
	my $pos=$int[1];
	my $ref=$int[57];
	my @alleles1 = ();
	my @alleles2 = ();
	my @alleles3 = ();
	foreach my $element (@positions1){
		#print "set1: $firstelements[$element]\t$int[$element]\n";
		push(@alleles1,$int[$element]);
		if ($int[$element] eq 'N'){
			++$mislukt1;
		}
	}
	foreach my $element (@positions2){
		#print "set2: $firstelements[$element]\t$int[$element]\n";

                push(@alleles2,$int[$element]);
		if ($int[$element] eq 'N'){
                        ++$mislukt2;
                }
        }
	if (@positions3){
        	foreach my $element (@positions3){
        	        #print "set2: $firstelements[$element]\t$int[$element]\n";
	
	                push(@alleles3,$int[$element]);
	                if ($int[$element] eq 'N'){
	                        ++$mislukt3;
	                }
	        }
	}


	if ($mislukt1/$totaal1 < 0.5 && $mislukt2/$totaal2 < 0.5){
		@alleles1 = reduce_to_alleles(@alleles1);
		@alleles2 = reduce_to_alleles(@alleles2);
		@alleles3 = reduce_to_alleles(@alleles3);
		my @orig1=@alleles1;
		my @orig2=@alleles2;
		my @orig3=@alleles3;
		@alleles1 = unique_array_elements(@alleles1);
		@alleles2 = unique_array_elements(@alleles2);
		@alleles3 = unique_array_elements(@alleles3);

		my @allalleles = @alleles1;
		push(@allalleles,@alleles2);

		@allalleles = unique_array_elements(@allalleles);
		my $flag='';
		my $nonref='N';
		my $oldref=$ref;

		# set ref allele at anc allele, if determined
		if (scalar @alleles3 == 1){
			$ref = $alleles3[0];
			$flag = "anc:$alleles3[0]";
		}
		elsif (scalar @alleles3 ==0){
			$flag = "anc:N";
		}
		elsif (scalar @alleles3 > 1){
			$flag = "anc:P";
		}
		
		# determine ref and non-ref alleles
		if ($allalleles[0] eq $oldref){
			if ($allalleles[1]){
				$nonref = $allalleles[1];
			}
		}
		else {
			$nonref = $allalleles[0];
		}

		# set anc as ref
		my $oldnonref=$nonref;
		
		
		if ($allalleles[0] eq $ref){
                        if ($allalleles[1]){
                                $nonref = $allalleles[1];
                        }
                }
                else {
                        $nonref = $allalleles[0];
                }

		# determine ref(anc) and nonref(derived) frequencies
		my $ref1count=0;
		my $nonref1count=0;
		my $ref2count=0;
		my $nonref2count=0;

		foreach my $element (@orig1){
			if ($element eq $ref){
				++$ref1count;
			}
			elsif ($element eq $nonref){
				++$nonref1count;
			}
		}
		foreach my $element (@orig2){
                        if ($element eq $ref){
                                ++$ref2count;
                        }
                        elsif ($element eq $nonref){
                                ++$nonref2count;
                        }
                }
		
		my $geluktgroup1= scalar @orig1;
                $geluktgroup1=$geluktgroup1/2;
		my $geluktgroup2= scalar @orig2;
                $geluktgroup2=$geluktgroup2/2;
		my $geluktgroup3= scalar @orig3;
                $geluktgroup3=$geluktgroup3/2;
		#print "$line\n";
		if (@alleles1 && @alleles2 && ($ref1count+$nonref1count)>0 && ($ref2count+$nonref2count)>0){
			my $reffreq1=$ref1count/($ref1count+$nonref1count);
			my $reffreq2=$ref2count/($ref2count+$nonref2count);
			my @common = shared_array_elements(\@alleles1,\@alleles2);
			if (scalar @alleles1 >1 && scalar @alleles2 == 1 && scalar @common == 1){
				++$snpsgroup1;	
				my $all = $snpsgroup1+$snpsgroup2+$shared+$fixed;
				print "$chrom\t$pos\t$pos\t$oldref\t$oldnonref\t".$line."\tnumlines: $numlines\tsnpno: $all\t$flag snpgroup1:$snpsgroup1 group1:$reffreq1 group2:$reffreq2 $geluktgroup1:$geluktgroup2:$geluktgroup3\n"
			}
			
			elsif (scalar @alleles1 == 1 && scalar @alleles2 > 1 && scalar @common == 1){
				++$snpsgroup2;
				my $all = $snpsgroup1+$snpsgroup2+$shared+$fixed;
				print "$chrom\t$pos\t$pos\t$oldref\t$oldnonref\t".$line."\tnumlines: $numlines\tsnpno: $all\t$flag snpgroup2:$snpsgroup2 group1:$reffreq1 group2:$reffreq2 $geluktgroup1:$geluktgroup2:$geluktgroup3\n";
			}
			elsif (scalar @alleles1 >1 && scalar @alleles2 > 1 && scalar @common > 1){
				++$shared;
				my $all = $snpsgroup1+$snpsgroup2+$shared+$fixed;
				print "$chrom\t$pos\t$pos\t$oldref\t$oldnonref\t".$line."\tnumlines: $numlines\tsnpno: $all\t$flag snpshared:$shared group1:$reffreq1 group2:$reffreq2 $geluktgroup1:$geluktgroup2:$geluktgroup3\n";
			}
			elsif (scalar @alleles1 == 1 && scalar @alleles2 == 1 && scalar @common == 0){
				++$fixed;
				my $all = $snpsgroup1+$snpsgroup2+$shared+$fixed;
				print "$chrom\t$pos\t$pos\t$oldref\t$oldnonref\t".$line."\tnumlines: $numlines\tsnpno: $all\t$flag snpfixed:$fixed group1:$reffreq1 group2:$reffreq2 $geluktgroup1:$geluktgroup2:$geluktgroup3\n";
			}
		}
	}
}

print OUT "num group1 snps: $snpsgroup1\n";
print OUT "num group2 snps: $snpsgroup2\n";
print OUT "num shared: $shared\n";
print OUT "num fixed: $fixed\n";
print "num group1 snps: $snpsgroup1\n";
print "num group2 snps: $snpsgroup2\n";
print "num shared: $shared\n";
print "num fixed: $fixed\n";

close(FILE);
close(OUT);
exit;

sub findposinmatrix {
	my ($firstelementref, $collectionref) = @_;
	my @firstelements = @$firstelementref;
	my @collection = @$collectionref;
	my @positions = ();
	my $count = 0;
	my $testcount = 0;
	foreach my $element (@firstelements){
        	$element =~ s/_mx//;
        	foreach my $element2 (@collection){
                	if ($element eq $element2){
                        	push(@positions,$count);
                        	++$testcount;
                	}
        	}
		
                ++$count;
	}
	if ($testcount< scalar @collection){
	        die "you did not provide all valid names. Exiting.\n";
	}
	return @positions;
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

sub reduce_to_alleles {
	my (@all) = @_;	
	my @alleles = ();
	foreach my $element (@all){
		if ($element =~ /[ACGT]/){
			push(@alleles,($element,$element));
		}
		elsif ($element eq 'R'){
			push(@alleles,('A','G'));
		}
		elsif ($element eq 'Y'){
                        push(@alleles,('C','T'));
                }
		elsif ($element eq 'W'){
                        push(@alleles,('A','T'));
                }
		elsif ($element eq 'S'){
                        push(@alleles,('C','G'));
                }
		elsif ($element eq 'M'){
                        push(@alleles,('A','C'));
                }
		elsif ($element eq 'K'){
                        push(@alleles,('G','T'));
                }
		
	}
	#@alleles = unique_array_elements(@alleles);
	return @alleles;
	
}
