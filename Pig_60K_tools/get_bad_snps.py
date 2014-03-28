import argparse
import sys
import os
 
parser = argparse.ArgumentParser( description='calculate heterozygosities for individuals in a ped file')
parser.add_argument("-m", "--mapfile", help="name of mapfile", nargs=1)
 
args = parser.parse_args()
map=args.mapfile[0]
mapfile=open(map)
mapdict=dict()
for line in mapfile.readlines():
   (chrom,snp,cm,pos)=elements=line[:-1].split('\t')
   if chrom+'_'+pos in mapdict.keys():
      print(chrom+'\t'+pos+'\t'+snp)
      print(chrom+'\t'+pos+'\t'+mapdict[chrom+'_'+pos])
   else:
      mapdict[chrom+'_'+pos]=snp


   
   
