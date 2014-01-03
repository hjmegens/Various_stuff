#!/usr/bin/perl
# Generate random DNA
#  using a random number generator to randomly select bases

use strict;
use warnings;

my $randdna=make_random_DNA(10000000);
#print $randdna."\n";
for (my $i=0; $i<length($randdna); $i+=10){
	$randdna =~ substr($randdna,$i,3,'XYZ'); 
}
#print $randdna."\n";
my $times = ($randdna =~ s/X/X/g);
print $times."\n";

sub make_random_DNA {

    # Collect arguments, declare variables
    my($length) = @_;

    my $dna;

    for (my $i=0 ; $i < $length ; ++$i) {

        $dna .= randomnucleotide(  );
    }

    return $dna;
}
sub randomnucleotide {

    my(@nucleotides) = ('A', 'C', 'G', 'T');

    # scalar returns the size of an array. 
    # The elements of the array are numbered 0 to size-1
    return randomelement(@nucleotides);
}

# randomelement
#
# randomly select an element from an array
#
# WARNING: make sure you call srand to seed the
#  random number generator before you call this function.

sub randomelement {

    my(@array) = @_;

    return $array[rand @array];
}
