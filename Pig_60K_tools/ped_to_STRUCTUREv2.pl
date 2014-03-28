#!/usr/bin/perl -w
use strict;
use warnings;

my $USAGE = <<END_USAGE;

    ped_to_STRUCTURE.pl

    Created by Hendrik-Jan Megens (hendrik-jan.megens\@wur.nl)
    Last modified: 19 May 2010

    This script converts ped files to STRUCTURE input format

  Options:
    -f   ped file name stub, assumes that there is a similarly named map file
         with extension .map - this option is required
    -c   chromosome name - optional
    -p   population name(s) as used in the ped file, will result in extracting only
         these populations. List of populations can be entered separated by spaces.
         If not given, all animals in the ped file will be used
    -m   if put to 'yes', the mainparameter file will be adapted for a number of
         key parameters; note that a basic valid mainparameter file is assumed to 
         be present and named 'mainparams'. This option will only work properly on 
         POSIX compliant machines.

  Example:
    ped_to_STRUCTURE -f myinfile -c 1 -p "POP01 POP02 POP02" -m yes;

  Remark: this script is under construction.

  Input: valid .ped and .map files, both should have the same filename stub
         e.g. myinfile.ped and myinfile.map.
  Ouput: file with extension structure, with two-line structure output. 
         file with extension popinfo, with population information. 

  mainparameter file: note that if the -m option is put to 'yes', the script will
         modify a number of the key parameters correctly, but further editing of 
         some parameters may be required. A basic valid mainparameter file called
         'mainparams' should be present if this option is used.

END_USAGE


use Getopt::Std;
my %opts = ();

#grab comandline options
getopt('fcpm', \%opts);
my $file = $opts{f};
my $chrom = $opts{c};
my $pops = $opts{p};
my $mainparams = $opts{m};
unless ($file){
	die $USAGE;
}
my @popsarray=();
if ($pops){
	@popsarray = split(/ |\t/,$pops);
	foreach my $pop(@popsarray) {
		print "$pop\n";
	}
}
#die;
open(OUT,">$file.structure");

open(MAP, "$file.map");
my $mapcount=0;
my $target='no';
my @targetsnps=();
my $first=0;
while(<MAP>){
	my $line = $_;
	chomp $line;
	
	++$mapcount;
	if ($chrom){
		if ($line =~ m/^$chrom\t/){
			unless ($target eq 'yes'){
				$first = $mapcount;
			}
		
			$target = 'yes';
			push(@targetsnps,$line);
		}
	}
	else {
		push(@targetsnps,$line);
	}
	
}
close(MAP);

my $nummarkers = scalar(@targetsnps);
my ($pophashref,$indhashref,$numindiv)=get_individual_info(\@popsarray,$file);
my %pophash = %$pophashref;
my %indhash = %$indhashref;

if ($mainparams){
	modify_mainparams($mainparams,$numindiv,$nummarkers);
}
foreach my $marker (@targetsnps){
	my @int = split("\t",$marker);
	print OUT " $int[3]"
}
print OUT "\n";

open(PED, "$file.ped");
while(<PED>){
	my $line = $_;
	chomp $line;
	
	$line =~ s/\t+| +/\t/g;
	my @linearray = split("\t",$line);

	# some checking if individuals need to be omitted/included
	my $include = 'no';
	unless (@popsarray){
		$include = 'yes';
	}
	if (@popsarray){
		foreach my $pop (@popsarray){
			if ($pop eq $linearray[0]){
				$include = 'yes';
			}
		}
	}
	if ($include eq 'yes'){
		
		if ($chrom){

			my $ind = $indhash{$linearray[1]};
			my $pop = $pophash{$linearray[0]};
			
			my $start = ($first-1)*2+6;
			my $end = $start + ($nummarkers*2);
			my @geno=();
			for (my $i=$start;$i<$end;++$i){
				my $allele = $linearray[$i];
				@geno = add_allele(\@geno,$allele);
			}
			print_genotypes(\@geno,$ind,$pop);

		}
		else {
			
			#print "do I get here, take 4\n";
			my $element = shift @linearray;
			#print $element . "\n";
			my $pop = $pophash{$element};
			$element = shift @linearray;
			print $element . "\n";
			my $ind = $indhash{$element};
			shift @linearray; shift @linearray; shift @linearray; shift @linearray;
			my $alleles = join("\t",@linearray);
			#print "$alleles\n";
			$alleles =~ s/N/-9/g;
			$alleles =~ s/A/1/g;
			$alleles =~ s/C/2/g;
			$alleles =~ s/G/3/g;
			$alleles =~ s/T/4/g;
		
			my @geno=split("\t",$alleles);;
			#print scalar(@geno)."\n";
			print_genotypes(\@geno,$ind,$pop);
		}
			
	}
}
close(PED);
close(OUT);
exit;

sub modify_mainparams {
	my ($mainparams,$numindiv,$nummarkers)=@_;
	if ($mainparams eq 'yes'){
		open(PAR,"mainparams") or die "Error: no file called 'mainparams' found in your working dir; $!\n";
		open(PAR2,">mainparams2");
		while(<PAR>){
			my $parline = $_;
			if ($parline =~ /NUMINDS/) {print PAR2 "#define NUMINDS $numindiv\n";}
			elsif ($parline =~ /NUMLOCI/) {print PAR2 "#define NUMLOCI $nummarkers\n";}
			elsif ($parline =~ /LABEL/) {print PAR2 "#define LABEL 1\n";}
			elsif ($parline =~ /POPDATA/) {print PAR2 "#define POPDATA 1\n";}
			elsif ($parline =~ /ONEROWPERIND/) {print PAR2 "#define ONEROWPERIND 0\n";}
			elsif ($parline =~ /MISSING/) {print PAR2 "#define MISSING -9\n";}
			elsif ($parline =~ /MARKERNAMES/) {print PAR2 "#define MARKERNAMES 1 \n";}
			elsif ($parline =~ /MAPDISTANCES/) {print PAR2 "#define MAPDISTANCES 0\n";}
			else { print PAR2 $parline;}
		}
		close(PAR);
		close(PAR2);
		`mv mainparams2 mainparams`;
	}
}

sub add_allele {
	my ($refgeno,$allele)=@_;
	my @geno = @$refgeno;
	
	$allele =~ s/N/-9/g;
	$allele =~ s/A/1/g;
	$allele =~ s/C/2/g;
	$allele =~ s/G/3/g;
	$allele =~ s/T/4/g;
	push(@geno,$allele);
	return @geno;
}
sub print_genotypes {
	my ($genoref,$ind,$pop) = @_;
	my @geno = @$genoref;
	my $n=0;
	my @geno1 = grep{!($n++ % 2)} @geno;
	 
	shift(@geno);
	my @geno2 = grep{!($n++ % 2)} @geno;
	 
	print OUT "$ind\t$pop\t@geno1\n";
	print OUT "$ind\t$pop\t@geno2\n";
}


sub get_individual_info {

	my ($poparrayref,$file)=@_;
	my @poparray = @$poparrayref;
	open(PED, "$file.ped");
	my $numindiv=0;
	my $popnumber = 0;
	my %pophash=();
	my %indhash=();
	open (POPINFO, ">$file.popinfo");
	print POPINFO "individual\tindiv. id\tpopulation\tpop. id\n";
	while(<PED>){
		my $genostring = $_;
		unless ($genostring =~ /^\n/){
			if (@popsarray){
				foreach my $pop (@popsarray){
					if ($_ =~ m/^$pop[ |\t]/){
						my @int = split (m/\t| /, $genostring);
						my $intpop = $int[0];
						my $intindiv = $int[1];
						unless (exists $pophash{$intpop}){
							++$popnumber;
							$pophash{$intpop}=$popnumber;
						}
						++$numindiv;
						$indhash{$intindiv}=$numindiv;
						print POPINFO "$intindiv\t$numindiv\t$intpop\t$popnumber\n";
					}
				}
			
			}
			else {
				++$numindiv;
				my @int = split (m/\t| /,$genostring);
				my $intpop = $int[0];
				my $intindiv = $int[1];
				print $intpop . "\n";
				unless (exists $pophash{$intpop}){
					++$popnumber;
					$pophash{$intpop}=$popnumber;
				}
				$indhash{$intindiv}=$numindiv;
				print POPINFO "$intindiv\t$numindiv\t$intpop\t$popnumber\n";
			}
		}		
	}	
	close(POPINFO);
	close(PED);
	
	return (\%pophash,\%indhash,$numindiv);
}
