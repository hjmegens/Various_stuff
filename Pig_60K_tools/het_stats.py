import argparse
import sys
import os

parser = argparse.ArgumentParser( description='calculate heterozygosities for individuals in a ped file')
parser.add_argument("-p", "--pedfile", help="name of pedfile", nargs=1)

args = parser.parse_args()
ped=args.pedfile[0]

def pedfile_to_list_of_lists(pedfile):
  flist=[]
  with open(pedfile) as pedf:
    for l in pedf.readlines():
      l=l.rstrip().split()
      flist.append(l[:])
  return flist

def calc_het(geno):
   het=0
   hom=0
   for i in range(0,len(geno),2):
      pair=geno[i:i+2]
      if pair[0] == pair[1] and pair[0] != 'N':
         hom+=1
      elif pair[0] != pair[1] and pair[0] != 'N':
         het+=1
   obshet=het/(het+hom)
   return [obshet,het,hom]

if __name__=="__main__":
  allgenos=pedfile_to_list_of_lists(ped)
  hets=[]
  #print(allgenos[20][0:20])
  #print(calc_het(allgenos[20][6:20]))
  for genos in allgenos:
     het=calc_het(genos[6:])
     print(genos[0],genos[1],het[0],het[1],het[2],sep='\t')


