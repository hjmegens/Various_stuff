import argparse
import sys
import os
import re

parser = argparse.ArgumentParser( description='converts between illumina genotype tabular report and plink')
parser.add_argument("-i", "--input_genotypes", help="input genotypes, in illumina report format", nargs=1)
parser.add_argument("-s", "--snp_list", help="table with snps and postions", nargs=1)
parser.add_argument("-o", "--output_stub", help="output stub name", nargs=1)
parser.add_argument("-t", "--transpose_ped", help="create tped and tfam in stead of regular ped and map", action="store_true")



def next_line(filename):
   try:
      fileh = open(filename)
      line = fileh.readline()[:-1]
      while line:
         yield line
         line = fileh.readline()[:-1]
   finally:
      fileh.close()

def make_snp_list(snpfilename):
   snplist=[]
   snporder={}
   snplist_i=next_line(snpfilename)
   next(snplist_i)
   next(snplist_i)
   counter=0
   for snp in snplist_i:
      parts=snp.split('\t')
      snplist.append(parts)
      snporder[parts[0]]=counter
      counter+=1
   return (snplist,snporder)

def genotypes(genotypefile,snplist,snpdict,filestub):
   if os.path.exists(filestub+'.ped'):
      os.remove(filestub+'.ped')
   allelecol1=3
   allelecol2=4
   genotype_i=next_line(genotypefile)
   indiv_dict={}
   indiv_snplist=[] 
   indiv_id=''
   
   for i in range(2):
      next(genotype_i)
   counter=0
   for genotype in genotype_i:
      parts=genotype.split('\t')
      if not parts[1] in indiv_dict.keys():
         if len(indiv_id) > 0:
            export_genotypes_ped(indiv_id,indiv_snplist,filestub)
         indiv_id=parts[1]
         indiv_dict[indiv_id]=counter
         indiv_snplist=[[part[0]] for part in snplist] 
         counter+=1
      if parts[0] in snpdict.keys():
         indiv_snplist[snpdict[parts[0]]].append([parts[allelecol1],parts[allelecol2]])
   
   export_genotypes_ped(indiv_id,indiv_snplist,filestub)
   return indiv_dict

def export_genotypes_ped(ind,genotypes,filestub):
   pedf=open(filestub+'.ped','a')
   part1='pop\t{}\t0\t0\t0\t0'.format(ind)
   part2='\t{}\t{}'
   print(part1,end='')
   pedf.write(part1)
   for genotype in genotypes:
      #print(part2.format(*genotype[1]),end='')
      pedf.write(part2.format(*genotype[1]))
   print()
   pedf.write('\n')
   pedf.close()

def export_map(filestub,snplist):
   mapf=open(filestub+'.map', 'w')
   for snp in snplist:
      snpformat='{}\t{}\t{}\t{}\n'.format(snp[1],snp[0],'0',snp[2])
      mapf.write(snpformat)
   mapf.close()

def export_tfam():
   pass

if __name__=="__main__":
   args = parser.parse_args()
   ingenotypes=args.input_genotypes[0]
   snpfile = args.snp_list[0]
   outstub = args.output_stub[0]
   do_tped=args.transpose_ped
   (snplist,snpcounter)=make_snp_list(snpfile)
   #print(snplist)   
   #print(snpcounter)
   export_map(outstub,snplist)
   indiv_dict=genotypes(ingenotypes,snplist,snpcounter,outstub)
   #print(snplist)
   print(indiv_dict)


