import argparse
import sys
import os
import re
import gzip

# a few example lines from input-vcf:
# #CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	Sample_10B	Sample_11B	Sample_12B	Sample_13C	Sample_14C	Sample_15C	Sample_16C	Sample_17C	Sample_18C	Sample_19D	Sample_1A	Sample_20D	Sample_21D	Sample_22D	Sample_23D	Sample_24D	Sample_2A	Sample_3A	Sample_4A	Sample_5A	Sample_6A	Sample_7B	Sample_8B	Sample_9B	Sample_E17	Sample_E18	Sample_E19	Sample_E20	Sample_E22	Sample_E23	Sample_E24	Sample_E25	Sample_E28	Sample_F17	Sample_F18	Sample_F19	Sample_F21	Sample_F22	Sample_F23	Sample_F24	Sample_F25	Sample_F29	Sample_G16	Sample_G17	Sample_G18	Sample_G19	Sample_G20	Sample_G21

# 1	26	.	T	A	84.09	.	AC=8;AF=0.095;AN=84;BaseQRankSum=-1.212;DP=128;Dels=0.00;FS=4.149;HaplotypeScore=1.0624;InbreedingCoeff=0.3236;MLEAC=5;MLEAF=0.060;MQ=36.76;MQ0=0;MQRankSum=-1.037;QD=16.82;ReadPosRankSum=-2.824	GT:AD:DP:GQ:PL	./.	0/0:8,0:8:24:0,24,300	0/0:3,0:3:6:0,6,69	0/0:6,0:6:18:0,18,239	0/0:13,0:13:39:0,39,501	0/0:2,0:2:6:0,6,77	0/0:3,0:3:9:0,9,119	0/0:5,0:5:15:0,15,195	0/0:3,0:3:9:0,9,111	0/0:5,0:5:15:0,15,195	0/0:2,0:2:6:0,6,80	0/0:3,0:3:9:0,9,117	0/0:5,0:5:15:0,15,191	0/0:5,0:5:15:0,15,195	0/0:2,0:2:6:0,6,76	0/0:8,0:8:24:0,24,295	0/0:3,0:3:6:0,6,72	0/0:2,0:2:6:0,6,79	1/1:0,1:1:3:39,3,0	0/0:3,0:3:9:0,9,111	0/0:5,0:5:15:0,15,195	0/0:6,0:6:18:0,18,232	0/0:3,0:3:9:0,9,119	./.	0/0:1,0:1:3:0,3,39	./.	./.	0/0:3,0:3:9:0,9,116	0/0:1,0:1:3:0,3,40	./.	1/1:0,1:1:3:34,3,0	0/0:2,0:2:6:0,6,80	./.	0/0:3,0:3:9:0,9,119	0/0:1,0:1:3:0,3,36	0/0:1,0:1:3:0,3,36	0/0:1,0:1:3:0,3,40	1/1:0,2:2:6:65,6,0	0/0:2,0:2:6:0,6,79	0/0:1,0:1:3:0,3,36	1/1:0,1:1:3:28,3,0	0/0:2,0:2:6:0,6,76	0/0:2,0:2:6:0,6,71	0/0:2,0:2:6:0,6,65	0/0:1,0:1:3:0,3,35	0/0:2,0:2:6:0,6,79	0/0:1,0:1:3:0,3,40	0/0:2,0:2:6:0,6,77

# example usage:
# python stats_from_vcf.py -f all.UG.raw2.vcf.gz >genotypestats3.txt
# note that input-vcf is (block) compressed.

parser = argparse.ArgumentParser( description='Computes a bunch of statistics per SNP and per individual from a multiple individual VCF file')
parser.add_argument("-f", "--filename", help="input filename", nargs=1)

args = parser.parse_args()


def read_stdin():
   line = sys.stdin.readline()[:-1]
   while line:
     if not re.search('^(#+)',line):
        yield line
     line = sys.stdin.readline()[:-1]

def read_from_zipfile(filename):
    try:
        fileh = gzip.open(filename)
        line = fileh.readline()[:-1].decode('utf-8')
        #print(line)
        while line:
           yield line
           line = fileh.readline()[:-1].decode('utf-8')
    finally:
        fileh.close()

def results_per_line(results,components,samples):
   for i in range(9,len(samples)+9):
      parts=components[i].split(':')
      if len(parts)>1 and parts[0]!='./.':
         if int(parts[3])>19 and int(parts[2]) < 2*samples[i-9][1] and int(parts[2]) > 4:
            if parts[0]=='0/0':
               results[2]+=1
               samples[i-9][2]+=1
            elif parts[0]=='0/1':
               results[3]+=1
               samples[i-9][3]+=1
            elif parts[0]=='1/1':
               results[4]+=1
               samples[i-9][2]+=1
   return (results,samples)

def get_closest_var(vars,varsindex,var,vartype):
   #posvar=varlist.index(var)
   posvar=varsindex[var[0]+'_'+var[1]]
   coord=int(varlist[posvar][1])
   match = False
   diff=-1
   indexval=posvar
   upI=-1
   while upI<0 and indexval<len(varlist):
      indexval+=1
      if var[0] != varlist[indexval][0]:
         break
      if varlist[indexval][2] == vartype:
         upI=int(varlist[indexval][1])
   indexval=posvar
   lowI=-1
   while lowI<0 and indexval>0:
      indexval -= 1
      if var[0] != varlist[indexval][0]:
         break
      if varlist[indexval][2] == vartype:
         lowI=int(varlist[indexval][1])
   if lowI<0 and upI>0:
      diff=upI-coord
   elif lowI>0 and upI<0:
      diff=coord-lowI
   elif lowI>0 and upI>0:
      diff=min([coord-lowI,upI-coord])
   return diff

def get_stats_for_all(lines,samples,varlist,varsindex):

   print('{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}'.format('chrom','coord','ref_allele','alt_allele','num_hom_ref','num_het','num_hom_nonref','genotyped_prop','num_ref_alleles','num_nonref_alleles','prop_ref_alleles','prop_nonref_alleles','obshet','exphet','closest_indel','closest_snp'))
   for line in lines:
      #print(line)
      if not re.search('^(#+)',line):
         components=line.split('\t')
         numsamps=len(components[9:])
         results=[components[0:2],components[3:5],0,0,0]
         genotypeprop=0
         nonref=0
         nonrefprop=0
         ref=0
         refprop=0
         exphet=0
         obshet=0
         closestindel=0
         closestsnp=0
         var=[components[0],components[1],'var']
         if len(results[1][0])==1 and len(results[1][1])==1:
            var[2]='S'
         else:
            var[2]='I'
          
         if var[2]=='S':
            closestindel=get_closest_var(varlist,varsindex,var,'I')
            closestsnp=get_closest_var(varlist,varsindex,var,'S')

         (results,samples)=results_per_line(results,components,samples)
         ref=2*results[2]+results[3]
         nonref=2*results[4]+results[3]
         genotypeprop=(results[2]+results[3]+results[4])/numsamps
         if (ref+nonref)>0:
            refprop=ref/(ref+nonref)
            nonrefprop=nonref/(ref+nonref)
            obshet=results[3]/(results[2]+results[3]+results[4])
            exphet=2*(refprop*nonrefprop)
            if len(results[1][0])==1 and len(results[1][1])==1:
               print('{}\t{}\t{}\t{}\t{}\t{}\t{}\t{:.4f}\t{}\t{}\t{:.4f}\t{:.4f}\t{:.4f}\t{:.4f}\t{}\t{}'.format(results[0][0],results[0][1],results[1][0],results[1][1],results[2],results[3],results[4],genotypeprop,ref,nonref,refprop,nonrefprop,obshet,exphet,closestindel,closestsnp))

def get_list_of_samples(file):
   lines=read_from_zipfile(filename)
   for line in lines:
      if re.search('^#CHROM',line):
         return line.split('\t')[9:]
         break

def get_depth_of_samples(filename,samples):
   counter=0
   intsampledepth=[[0,0] for i in range(len(samples))]
   lines=read_from_zipfile(filename)
   indels=[]
   for line in lines:
      #print(line)
      if not re.search('^(#+)',line):
         components=line.split('\t')
         numsamps=len(samples)
         
         for i in range(9,len(samples)+9):
           parts=components[i].split(':')
           if parts[0]!='./.':
              intsampledepth[i-9][0]+=int(parts[2])
              intsampledepth[i-9][1]+=1
         counter+=1
      if counter>20000:
         break
   for i in range(len(samples)):
      avgdepth=intsampledepth[i][0]/intsampledepth[i][1]
      samples[i][1]=avgdepth
          
   return samples,indels


def get_var_list(filename,samples):
   counter=0
   intsampledepth=[[0,0] for i in range(len(samples))]
   lines=read_from_zipfile(filename)
   indels=[]
   varindex={}
   indexval=0
   for line in lines:
      #print(line)
      if not re.search('^(#+)',line):
         components=line.split('\t')
         chrom=components[0]
         coord=components[1]
         refallele=components[3]
         altallele=components[4]
         if len(refallele)>1 or len(altallele)>1:
            indels.append([chrom,coord,'I'])
            indexval+=1
         elif len(refallele)==1 and len(altallele)==1:
            indels.append([chrom,coord,'S'])
            varindex[chrom+'_'+coord]=indexval
            indexval+=1
   return (indels,varindex)


if __name__ == '__main__':
   filename=args.filename[0]
   #lines=read_stdin()
   sample_list=get_list_of_samples(filename)
   samples=[[sample,0,0,0,0] for sample in sample_list]
#   print(samples)
   (varlist,varsindex)=get_var_list(filename,samples)
   depths=get_depth_of_samples(filename,samples)
   lines=read_from_zipfile(filename)
   get_stats_for_all(lines,samples,varlist,varsindex)
   statsfile=open('statsfile4.'+filename+'.txt','w')
   for sample in samples:
      statsfile.write('{}\t{:.4f}\t{}\t{}\t{}'.format(sample[0],sample[1],sample[2],sample[3],sample[4])+'\n')
   statsfile.close()


