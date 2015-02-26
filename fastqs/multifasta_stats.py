from Bio import SeqIO
from Bio.SeqUtils.CheckSum import seguid
import argparse
import sys

# python3 multifasta_stats.py -f in.fa
parser = argparse.ArgumentParser( description='provides for each entry in multifasta file seq length, N count, GC perc, checksum')
parser.add_argument("-f", "--filename", help="input filename", nargs=1)

args = parser.parse_args()
filename=args.filename[0]
cum_length=0
fh = open(filename)
for record in SeqIO.parse(fh, "fasta"):
   gc=(record.seq.count('C')+record.seq.count('G'))/len(record.seq)
   lc=(record.seq.count('c')+record.seq.count('g')+record.seq.count('a')+record.seq.count('t'))/(len(record.seq)-record.seq.count('N'))
   cum_length=cum_length+len(record.seq)
   print(record.id,len(record.seq),record.seq.count('N'),gc,lc,seguid(record.seq),cum_length, sep="\t")

