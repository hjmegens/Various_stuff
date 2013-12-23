#!/usr/bin/perl -w
use strict;
use warnings;
use Getopt::Std;
my %opts = ();

$opts{b}=0;
$opts{f}='infile';
getopt('fbsph', \%opts);
my $file = $opts{f};
my $binsize=$opts{b};
my $filestub = $opts{s};
my $polyphenout=$opts{p};
my $ssctohsa=$opts{h};
my %genehash=();

my %hgnchash=();
open (SCHS,$ssctohsa) or die $!;
while (<SCHS>){
        my $line = $_;
        chomp $line;
        my @int = split("\t",$line);
        my @elements = split(';',$int[8]);
        my $ensg = $elements[0];
        $ensg =~ s/"//g;
        $ensg =~ s/gene_id //;
	$ensg =~ s/ //g;
        my $enst = $elements[1];
        $enst =~ s/"//g;
        $enst =~ s/transcript_id //;
	$enst =~ s/ //g;

        my $hgnc = $elements[3];
        $hgnc =~ s/"//g;
        if ($line =~ /gene_name/){
                $hgnc =~ s/gene_name //;
        }
        else {
                $hgnc =~ s/gene_biotype //;
        }
        $hgnchash{"$ensg$enst"}=$hgnc;
        #print "$ensg $enst $hgnc\n";
}
close(SCHS);
while( my ($key,$value) = each %hgnchash){
        #print "$key\t$value\n";
}

open (PPH,$polyphenout) or die $!;
my %ppheffecthash=();
while (<PPH>){
	my $line = $_;
        chomp $line;
        my @elements = split("\t",$line);
        my $id = $elements[0];
        my $position = $elements[1];
        my $from = $elements[2];
        my $to = $elements[3];
        my $effect = $elements[11];
	if($ppheffecthash{"$id $position"}){
		$ppheffecthash{"$id $position"}=$ppheffecthash{"$id $position"}."_".$position.'|'.$from.'|'.$to.'|'.$effect;
	}
	else {
		$ppheffecthash{"$id $position"}=$position.'|'.$from.'|'.$to.'|'.$effect;
	}
}
close(PPH);

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
my %pphash=();
my $counter=$binsize;
while (<FA>){
        my $line = $_;
        chomp $line;
        if ($line =~ m/^>/){
                if ($id){
                        my $pphashref = do_something($id, $seq, \%genehash, \%pphash);
			%pphash=%$pphashref;
                }

                $id = $line;
                $id =~ s/^>//;
                $seq = '';
        }
        else {
                $seq = $seq . $line;
        }
}
while( my ($key,$value) = each %pphash){
        print "$key\t$value\n";
}

exit;

sub do_something {
        my($id,$seq,$genehashref,$pphashref) = @_;
	my %genehash=%$genehashref;
	my %pphash=%$pphashref;
	my ($ensg,$enst)=split(' ',$id);
	my $newid = $ensg.$enst;
        if ($genehash{$ensg."_".$enst}){
		#++$counter;
		my @muts = split("_",$genehash{$ensg."_".$enst});
		foreach my $mut (@muts){
                	my @int = split(/\|/,$mut);
			# print "num elements: ".scalar @int . "\n";
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
			my $effect='unk unk unk unknowneffect';
			if ($ppheffecthash{"$newid $position"}){
				$effect=$ppheffecthash{"$newid $position"};
			}
			$mut =~ s/\|/ /g;
			$effect =~ s/\|/ /g;
                        my $checkaa = substr($seq,($position-1),1, $newaa);
			#print "checkaa: $checkaa\n";
			#print $genehash{$ensg."_".$enst}." mut: $mut pepmut:$pepmut from:$from to:$to position:$position\n";
			my $newnewid = $newid;
			$newnewid =~ s/ENSSSCT/ ENSSSCT/;
			print "$newnewid $position $from $to $mut $effect $hgnchash{$newid}\n";
		}
		#my $newfile = $filestub.'.fa.'.$counter;
		#open (NEWFA, ">$newfile") or die $!;
		#print NEWFA ">$newid\n";
                #format_seq($seq,60);
		#close(NEWFA);
		#my $coordfile = $filestub.'.coord.'.$counter;
		#open (COORD,">$coordfile") or die $!;
        	#while( my ($key,$value) = each %pphash){
               #		 print COORD"$key\t$value\n";
        	#}
        	#close(COORD);
		#my $qsubfile = $filestub.'.qsub.'.$counter;
                #open (QS, ">$qsubfile") or die $!;
                #print QS '#!/bin/bash'."\n";
		#print QS '#$ -cwd'."\n";
		#print QS '#$ -S /bin/sh'."\n";
		#print QS '#$ -l h_vmem=5G'."\n";
		#print QS '#$ -p -1'."\n";
		#print QS '/srv/mds01/shared/Polyphen/polyphen-2.2.2/bin/run_pph.pl -s '.$filestub.'.fa.'.$counter.' '.$filestub.'.coord.'.$counter."\n";
		#close (QS);
		#`qsub -q all.q $qsubfile`;

	}
	
	return \%pphash;
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
                #print NEWFA "$intseq\n";
                $index += $offset;
        }
}
