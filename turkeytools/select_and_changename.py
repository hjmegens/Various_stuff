from Bio import SeqIO
from Bio.SeqUtils.CheckSum import seguid
import argparse
import sys

# wget wget ftp://ftp.ncbi.nlm.nih.gov/genomes/Meleagris_gallopavo/Assembled_chromosomes/seq/mga_ref_Turkey_5.0_chr1.fa.gz
# gunzip -c mga_ref_Turkey_5.0_*.gz >UMD5_ncbi.fa
# python3 select_and_changename.py -f UMD5_ncbi/UMD5_ncbi.fa -t transtable.txt -m 1500 >UMD5_ncbi/UMD5_ncbi_newnames_and_minlength1500.fa
parser = argparse.ArgumentParser( description='select contigs based on minimumlength')
parser.add_argument("-f", "--filename", help="input filename", nargs=1)
parser.add_argument("-t", "--contig_name_translation", help="name of translation table between chromosome and NCBI contig/scaffold names", nargs=1)
parser.add_argument("-m", "--minimumlength", help="minimum length of contig", nargs=1)

def return_transtable(transtabletext):
   fh = open(transtabletext, 'r')
   transtable={}
   for line in fh.readlines():
      #print(line,type(line))
      [chrom,ncbi]=line.rstrip().split(' ')
      #print(chrom,ncbi)
      transtable[ncbi]=chrom
   return transtable
   fh.close()

args = parser.parse_args()
filename=args.filename[0]
minlength=args.minimumlength[0]
transtabletext=args.contig_name_translation[0]

if __name__ == '__main__':
   transtable=return_transtable(transtabletext)
   fh = open(filename)
   for record in SeqIO.parse(fh, "fasta"):
      if len(record.seq)>int(minlength):
         seq_name_parts=record.id.split('|')
         if seq_name_parts[3] in transtable.keys():
            newname=transtable[seq_name_parts[3]]
            #print(newname, seq_name_parts[3],len(record.seq))
         else:
            newname=seq_name_parts[3]
            #print("Error: name not in translation table")
            #print(seq_name_parts)
         
         record.id=newname
         
         #print(record.id,len(record.seq),record.seq.count('N'),seguid(record.seq))
         SeqIO.write(record,sys.stdout,'fasta')


######################## transtable.txt contains this: ############
# Chr1 NC_015011.2
# Chr2 NC_015012.2
# Chr3 NC_015013.2
# Chr4 NC_015014.2
# Chr5 NC_015015.2
# Chr6 NC_015016.2
# Chr7 NC_015017.2
# Chr8 NC_015018.2
# Chr9 NC_015019.2
# Chr10 NC_015020.2
# Chr11 NC_015021.2
# Chr12 NC_015022.2
# Chr13 NC_015023.2
# Chr14 NC_015024.2
# Chr15 NC_015025.2
# Chr16 NC_015026.2
# Chr17 NC_015027.2
# Chr18 NC_015028.2
# Chr19 NC_015029.2
# Chr20 NC_015030.2
# Chr21 NC_015031.2
# Chr22 NC_015032.2
# Chr23 NC_015033.2
# Chr24 NC_015034.2
# Chr25 NC_015035.2
# Chr26 NC_015036.2
# Chr27 NC_015037.2
# Chr28 NC_015038.2
# Chr29 NC_015039.2
# Chr30 NC_015040.2
# Chr41 NC_015041.2
# Chr40 NC_015042.2
# mt NC_010195.2
