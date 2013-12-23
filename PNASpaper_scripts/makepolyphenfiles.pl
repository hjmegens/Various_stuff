#!/usr/bin/perl -w
use strict;
use warnings;
use Getopt::Std;
my %opts = ();

$opts{b}=0;
$opts{f}='infile';
getopt('fbs', \%opts);
my $file = $opts{f};
my $binsize=$opts{b};
my $filestub = $opts{s};
my %genehash=();
while (<>){
	my $line = $_;
        chomp $line;
        my @elements = split("\t",$line);
        my $type = $elements[1];
        my $geneinfo=$elements[2];
        my $chrom = $elements[3];
        my $refpos = $elements[4];
        my $refbase = $elements[6];
        my $nonref = $elements[7];
        my $info = $elements[8];
        @elements = split(" ",$info);
        my $ancstate=$elements[0];
        my $group1freq = $elements[2];
	my $succesrate=$elements[3];
	$ancstate =~ s/anc://;
        $group1freq =~ s/group1://;
	my ($succes1,$succes2,$succes3) = split(":",$succesrate);
	my @genes = split(',',$geneinfo);
	foreach my $gene (@genes){
		my ($ensg,$enst,$exnum,$cdnamut,$pepmut)=split(':',$gene);
		$cdnamut =~ s/c\.//;
		$pepmut =~ s/p\.//;
		if ($genehash{$ensg.'_'.$enst}){
			$genehash{$ensg.'_'.$enst}=$genehash{$ensg.'_'.$enst}.'_'.$cdnamut.'|'.$pepmut.'|'.$chrom.'|'.$refpos.'|'.$refbase.'|'.$nonref.'|'.$ancstate.'|'.$group1freq.'|'.$succesrate;
		}
		else {
			$genehash{$ensg.'_'.$enst}=$cdnamut.'|'.$pepmut.'|'.$chrom.'|'.$refpos.'|'.$refbase.'|'.$nonref.'|'.$ancstate.'|'.$group1freq.'|'.$succesrate;
		}
	}
}
while( my ($key,$value) = each %genehash){
	#print "$key\t$value\n";
}
my $seq = '';
my $id = '';

open (FA, $file) or die $!;
#my %pphash=();
my $counter=$binsize;
while (<FA>){
        my $line = $_;
        chomp $line;
        if ($line =~ m/^>/){
                if ($id){
                        $counter = do_something($id, $seq, \%genehash, $counter);
			#%pphash=%$pphashref;
                }

                $id = $line;
                $id =~ s/^>//;
                $seq = '';
        }
        else {
                $seq = $seq . $line;
        }
}
#while( my ($key,$value) = each %pphash){
#        print "$key\t$value\n";
#}

exit;

sub do_something {
        my($id,$seq,$genehashref,$counter) = @_;
	my %genehash=%$genehashref;
	my %pphash=();
	my ($ensg,$enst)=split(' ',$id);
	my $newid = $ensg.$enst;
        if ($genehash{$ensg."_".$enst}){
		++$counter;
		my @muts = split("_",$genehash{$ensg."_".$enst});
		foreach my $mut (@muts){
                	my @int = split(/\|/,$mut);
			print "num elements: ".scalar @int . "\n";
                	my $cdnamut = $int[0];
			my $pepmut= $int[1];
			my $refbase=$int[4];
			my $altbase=$int[5];
			my $anc=$int[6];
			my @int2 = split('',$pepmut);
			my $from=shift @int2;
			my $to=pop @int2;
			my $position=join('',@int2);
			my $newaa='';
			if ($altbase eq $anc){
				$newaa=$to;
			}
			else {
				$newaa=$from;
			}
                        my $checkaa = substr($seq,($position-1),1, $newaa);
			#print "checkaa: $checkaa\n";
			#print $genehash{$ensg."_".$enst}." mut: $mut pepmut:$pepmut from:$from to:$to position:$position\n";

			if ($checkaa eq $from && $refbase eq $anc)  {
				$pphash{"$newid $position"}="$from $to";
			}
			elsif ($checkaa eq $from && $altbase eq $anc){
				$pphash{"$newid $position"}="$to $from";
			}
                        elsif ($checkaa eq $from && ($anc eq 'P' || $anc eq 'N'))  {
                                $pphash{"$newid $position"}="$from $to";
                        }
			else {
				print "ERROR $checkaa $mut\n";
			}
		}
		my $newfile = $filestub.'.fa.'.$counter;
		open (NEWFA, ">$newfile") or die $!;
		print NEWFA ">$newid\n";
                format_seq($seq,60);
		close(NEWFA);
		my $coordfile = $filestub.'.coord.'.$counter;
		open (COORD,">$coordfile") or die $!;
        	while( my ($key,$value) = each %pphash){
               		 print COORD"$key\t$value\n";
        	}
        	close(COORD);
		my $qsubfile = $filestub.'.qsub.'.$counter;
                open (QS, ">$qsubfile") or die $!;
                print QS '#!/bin/bash'."\n";
		print QS '#$ -cwd'."\n";
		print QS '#$ -S /bin/sh'."\n";
		print QS '#$ -l h_vmem=5G'."\n";
		print QS '#$ -p -1'."\n";
		print QS '/srv/mds01/shared/Polyphen/polyphen-2.2.2/bin/run_pph.pl -s '.$filestub.'.fa.'.$counter.' '.$filestub.'.coord.'.$counter."\n";
		close (QS);
		`qsub -q all.q $qsubfile`;

	}
	
	return $counter;
}

sub format_seq {
        my($seq,$offset)=@_;
        my $index = 0;
        while ($index < length $seq){
                my $intseq;
                if ($index+$offset < length $seq){
                        $intseq = substr($seq,$index,$offset);
                }
                else {
                        my $remaining = (length $seq) - $index;
                        $intseq = substr($seq,$index,$remaining);
                }
                print NEWFA "$intseq\n";
                $index += $offset;
        }
}
