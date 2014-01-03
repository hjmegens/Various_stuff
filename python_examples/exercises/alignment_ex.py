# currently only works for Python2.7
import argparse
import sys
import os
from alignment.sequence import Sequence
from alignment.vocabulary import Vocabulary
from alignment.sequencealigner import SimpleScoring, GlobalSequenceAligner

parser = argparse.ArgumentParser( description='reformat fasta files per desired length of lines')
parser.add_argument("-f", "--find", help="search for this string", nargs=1)

args = parser.parse_args()
search=str(args.find[0])

seqs = sys.stdin.read()

a = Sequence(seqs)
b = Sequence(search)

# Create a vocabulary and encode the sequences.
v = Vocabulary()
aEncoded = v.encodeSequence(a)
bEncoded = v.encodeSequence(b)

# Create a scoring and align the sequences using global aligner.
scoring = SimpleScoring(2, -1)
aligner = GlobalSequenceAligner(scoring, -2)
score, encodeds = aligner.align(aEncoded, bEncoded, backtrace=True)

# Iterate over optimal alignments and print them.
for encoded in encodeds:
    alignment = v.decodeSequenceAlignment(encoded)
    print alignment
    print 'Alignment score:', alignment.score
    print 'Percent identity:', alignment.percentIdentity()

