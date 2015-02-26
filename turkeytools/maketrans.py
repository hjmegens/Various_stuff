import sys
import gzip
# python3 maketrans.py transtable.txt ref_Turkey_5.0_top_level.gff3.gz new.gff3 
transtabletext=sys.argv[1]
orig_gff=sys.argv[2]
outfile=sys.argv[3]

def return_transtable(transtabletext):
   fh = open(transtabletext, 'r')
   transtable={}
   line = fh.readline()
   while line:
      #print(line,type(line))
      [chrom,ncbi]=line.rstrip().split(' ')
      print(chrom,ncbi)
      transtable[ncbi]=chrom
      line = fh.readline()
   return transtable
   fh.close()

def translate(transtable,orig_gff,outfile):
   fh=gzip.open(orig_gff, 'r')
   outf=open(outfile, 'w')
   line=fh.readline().decode('utf-8')[:-1]
   print(line)
   while line:
      line=line.split('\t',1)
      if len(line)<2:
         #print(line[0],end='\n')
         outf.write(line[0]+'\n')
      elif line[0] in transtable.keys():
         line[0]=transtable[line[0]]
         #print(line[0],line[1],sep='\t',end='\n')
         outf.write(line[0]+'\t'+line[1]+'\n')
      else:
         outf.write(line[0]+'\t'+line[1]+'\n')

      line=fh.readline().decode('utf-8')[:-1]
   fh.close()
   outf.close()

if __name__ == '__main__':
   transtable=return_transtable(transtabletext)
   print(transtable)
   print(orig_gff)
   translate(transtable,orig_gff,outfile)


