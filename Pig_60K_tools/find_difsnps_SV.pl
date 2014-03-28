#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  find_difsnps_SV.pl
#
#        USAGE:  ./find_difsnps_SV.pl  
#
#  DESCRIPTION:  
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  YOUR NAME (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  02/01/2012 01:23:34 PM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use Getopt::Std;
use DBI;
my %opts = ();
getopt('f', \%opts);
my $filename = $opts{f};

my $database = 'pig_hapmap2';
my $server = 'localhost';
my $user = 'anonymous';

my $pig_hapmap = DBI->connect("dbi:mysql:$database:$server", $user);

open (FILE,"$filename");
my @snps=();
while (<FILE>){
	my $line = $_;
	chomp $line;
	push(@snps, $line);
}
close(FILE);
my @sv1 = split("\t",<>);
my @sv2 = split("\t",<>);
my $i=0;
foreach my $snp (@snps){
	if ($sv1[$i+6] ne $sv2[$i+6] && $sv1[$i+6] !~/N/ && $sv2[$i+6] !~/N/){
		my @alls1 = split(" ",$sv1[$i+6]);
		my @alls2 = split(" ",$sv2[$i+6]);
		if ($alls1[0] eq $alls1[1] && $alls2[0] eq $alls2[1]){
			my @int = split("\t",$snp);
			my $snpname = $int[1];
			my $snpinfo = fetch_snpinfo($pig_hapmap,$snpname);
			print "$snpinfo\t$sv1[1]\t$sv2[1]\t$sv1[$i+6]\t$sv2[$i+6]\n";
		}
	}
	++$i;	
}
exit;
sub fetch_snpinfo {

        my ($pig_hapmap,$snpname)=@_;
        my $snpinfo = '';
        my $query = "select SNP,snps_build10_2.Chromosome,snps_build10_2.Position,fwd_genomic_seq from snps_build10_2 inner join alleletable using (SNP) where SNP='$snpname'";
        my $sql = $pig_hapmap->prepare($query);
        $sql->execute();
        while (my $row = $sql->fetchrow_arrayref) {
             $snpinfo = join("\t", @$row);
		}
		return $snpinfo;
}

