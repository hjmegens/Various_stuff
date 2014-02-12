from Bio import SeqIO
from Bio.SeqUtils.CheckSum import seguid
import argparse
import sys

# python3 contiglengths.py -f UMD_5_genome_nospaces_60.fa.original -m 1500 >UMD_5_genome_nospaces_60.fa
parser = argparse.ArgumentParser( description='select contigs based on minimumlength')
parser.add_argument("-f", "--filename", help="input filename", nargs=1)
parser.add_argument("-m", "--minimumlength", help="minimum length of contig", nargs=1)

args = parser.parse_args()
filename=args.filename[0]
minlength=args.minimumlength[0]

fh = open(filename)
for record in SeqIO.parse(fh, "fasta"):
    if len(record.seq)>minlength:
       SeqIO.write(record,sys.stdout,'fasta')
       #print(record.id,len(record.seq),record.seq.count('N'))
