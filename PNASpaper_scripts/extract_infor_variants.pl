#!/usr/bin/perl -w
use strict;
use warnings;
use Getopt::Std;
my %opts = ();

$opts{f}='infile';
$opts{b}=100000;
getopt('fb', \%opts);
my $file = $opts{f};
my $binsize=$opts{b};
my @genes=();
my %genehash=();
my %exonhash=();
open (FILE, $file) or die "no such file $file $!\n";
while (<FILE>){
	my $line = $_;
        chomp $line;
        my @elements = split("\t",$line);
        my $type = $elements[1];
        my $gene=$elements[2];
        my $chrom = $elements[3];
        my $refpos = $elements[4];
        my $refbase = $elements[6];
        my $nonref = $elements[7];
        my $info = $elements[8];
        @elements = split(" ",$info);
        my $ancstate=$elements[0];
        my $group1freq = $elements[2];
        my $group2freq = $elements[3];
        my $fst = $elements[4];
	@elements = split(":",$gene);
        $gene=$elements[0];
	if (exists $exonhash{$gene}){
		my $line3=$exonhash{$gene};
                my @int3=split("\t",$line3);
                my $syn=$int3[0];
                my $nonsyn=$int3[1];
                if ($type eq 'synonymous SNV'){
                      $syn=$int3[0]+1;
                }
                elsif ($type eq 'nonsynonymous SNV'){
                      $nonsyn=$int3[1]+1;
               }
		$exonhash{$gene}="$syn\t$nonsyn";
	}
	else {	
		my $syn=0;
		my $nonsyn=0;
		my $numfst=1;
                my $numgroupfreq=1;
		if ($type eq 'synonymous SNV'){
                      $syn=$syn+1;
                }
                elsif ($type eq 'nonsynonymous SNV'){
                      $nonsyn=$nonsyn+1;
                }
		if ($ancstate =~ /[NP]/){
                	$group1freq=0;
                        $group2freq=0;
                        $numgroupfreq=0;
               }
               if ($fst eq 'ND'){
                        $fst = 0;
                        $numfst=0;
               }

		$exonhash{$gene}="$syn\t$nonsyn";
	}
}

while (<>){
	my $line = $_;
        chomp $line;
        my @elements = split("\t",$line);
        my $type = $elements[0];
	my $gene=$elements[1];
	my $chrom = $elements[2];
        my $refpos = $elements[3];
        my $refbase = $elements[5];
        my $nonref = $elements[6];
        my $info = $elements[7];
        @elements = split(" ",$info);
        my $ancstate=$elements[0];
        my $group1freq = $elements[2];
        my $group2freq = $elements[3];
        my $fst = $elements[4];
	my $distance=0;
	if ($type eq 'intergenic'){
		
		@elements = split(',',$gene);
		my @gene1=split(/\(dist=/,$elements[0]);
		my @gene2=split(/\(dist=/,$elements[1]);
		my $dist1=$gene1[1];
		my $dist2=$gene2[1];
		$dist1 =~ s/\)//;
		$dist2 =~ s/\)//;
		if ($dist1 eq 'NONE'){
			$dist1 = 1000000;
		}
		if ($dist2 eq 'NONE'){
                        $dist2 = 1000000;
                }
		if ($dist1<$dist2 && $dist1<10000){
			$gene=$gene1[0];
		}
		elsif ($dist2<$dist1 && $dist2<10000){
			$gene=$gene2[0];
		}
		else {
			$distance= 10001;
		}
	}
	if ($distance <10000 && ($type eq 'intergenic' || $type eq 'upstream' || $type eq 'downstream' || $type eq 'intronic' || $type eq 'exonic') && $gene !~ /,/){

    		$ancstate =~ s/anc://;
	        $group1freq =~ s/group1://;
	        $group2freq =~ s/group2://;
	        $fst =~ s/gr1vs2fst://;
		my $numgroupfreq=0;
		my $numfst=0;
		if (exists $genehash{$gene}){
			my $line3=$genehash{$gene};
			my @int3=split("\t",$line3);
			my $intergenic=$int3[8];
			my $intronic=$int3[9];
			my $exonic=$int3[10];	
			if ($type eq 'intergenic' || $type eq 'upstream' || $type eq 'downstream'){
                                $intergenic=$int3[8]+1;
                        }
                        elsif ($type eq 'intronic'){
                                $intronic=$int3[9]+1;
                        }
                        elsif ($type eq 'exonic'){
                                $exonic=$int3[10]+1;
                        }

                        if ($ancstate !~ /[NP]/){
                                $group1freq=$int3[3]+$group1freq;
                                $group2freq=$int3[4]+$group2freq;
                                $numgroupfreq=$int3[5]+1;
				
                        }
			else {
				$group1freq=$int3[3];
                                $group2freq=$int3[4];
                                $numgroupfreq=$int3[5];
			}
                        if ($fst ne 'ND'){
                                $fst = $int3[6]+$fst;
                                $numfst=$int3[7]+1;
                        }
			else {	
				$fst = $int3[6];
                                $numfst=$int3[7];
			}
			$genehash{$gene}=$int3[0]."\t".$int3[1]."\t".$refpos."\t".$group1freq."\t".$group2freq."\t$numgroupfreq\t".$fst."\t".$numfst."\t".$intergenic."\t".$intronic."\t".$exonic;
			
		}
		else {	
			my $typetab="\t0\t0\t0";
			my $numfst=1;
			my $numgroupfreq=1;
			if ($type eq 'intergenic' || $type eq 'upstream' || $type eq 'downstream'){
				$typetab = "\t1\t0\t0";
			}
			elsif ($type eq 'intronic'){
				$typetab = "\t0\t1\t0";
			}
			elsif ($type eq 'exonic'){
				$typetab = "\t0\t0\t1";
			}
			
			if ($ancstate =~ /[NP]/){
				$group1freq=0;
				$group2freq=0;
				$numgroupfreq=0;
			}
			if ($fst eq 'ND'){
				$fst = 0;
				$numfst=0;
			}
			$genehash{$gene}=$chrom."\t".$refpos."\t".$refpos."\t".$group1freq."\t".$group2freq."\t$numgroupfreq\t".$fst."\t".$numfst.$typetab;
		}
	}
}
	



while( my ($key,$value) = each %genehash){
	print "$key\t$value\t";
	if (exists $exonhash{$key}){
		print $exonhash{$key};
		print "\n";
	}
	else {
		print "0\t0\n";
	}
}	
exit;


