from Bio import SeqIO
from Bio.SeqUtils.CheckSum import seguid
import argparse
import sys

# python3 multifasta_stats.py -f in.fa
parser = argparse.ArgumentParser( description='provides for each entry in multifasta file seq length, N count, GC perc, checksum')
parser.add_argument("-f", "--filename", help="input filename", nargs=1)

args = parser.parse_args()
filename=args.filename[0]

fh = open(filename)
for record in SeqIO.parse(fh, "fasta"):
   print(record.id,len(record.seq),record.seq.count('N'),(record.seq.count('C')+record.seq.count('G'))/len(record.seq),seguid(record.seq))

