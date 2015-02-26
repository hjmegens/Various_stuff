from Bio import SeqIO
from Bio.SeqUtils.CheckSum import seguid
import argparse
import sys
import re

# python3 multifasta_stats.py -f in.fa
parser = argparse.ArgumentParser( description='provides for each entry in multifasta file seq length, N count, GC perc, checksum')
parser.add_argument("-f", "--filename", help="input filename", nargs=1)
sequences={}
args = parser.parse_args()
filename=args.filename[0]
cum_length=0
fh = open(filename)
for record in SeqIO.parse(fh, "fasta"):
   sequence = re.sub('[^GATCgatc]', "N", str(record.seq))
 #  SeqIO.write(record,sys.stdout,'fasta')
   sequences[sequence]=record.id
   #SeqIO.write(record,sys.stdout,'fasta')

for sequence in sequences:
    print(">"+sequences[sequence]+"\n"+sequence+"\n",end='')
