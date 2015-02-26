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
fh = open(filename)
newname=filename.split('_Y')[0]
for record in SeqIO.parse(fh, "fasta"):
   record.id=newname

   n=(record.seq.count('N')+record.seq.count('n'))/len(record.seq)
#   print(record.id+"\t"+str(n)+"\t"+str(len(record.seq)))
   if n < 0.5:
      record.seq=record.seq[0:1635700]

      SeqIO.write(record,sys.stdout,'fasta')
