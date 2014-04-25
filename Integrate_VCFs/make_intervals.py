import sys
import argparse
parser = argparse.ArgumentParser( description='some description')
parser.add_argument("-f", "--file", help="file that contains length of contigs", nargs=1)
parser.add_argument("-b", "--binsize", help="size of the intervals, in bp", nargs=1)
args = parser.parse_args()

file=args.file[0]
binsize=int(args.binsize[0])

fh=open(file)
for line in fh.readlines():
   (contig,size)=line[:-1].split('\t')
   size=int(size)
   remain=size % binsize
   numbins=0
   if size > binsize:
      numbins= int(size/binsize)
   for bin in range(numbins):
      start=1+bin*binsize
      end=(bin+1)*binsize
      print("{}\t{}\t{}".format(contig,str(start),str(end)))
   if remain > 1:
      start=1+numbins*binsize
      end=numbins*binsize+remain
      print("{}\t{}\t{}".format(contig,str(start),str(end)))

~                    
