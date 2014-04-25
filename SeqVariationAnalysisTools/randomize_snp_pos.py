import sys
import argparse
import random
import scipy.stats as stats
import numpy as np

parser = argparse.ArgumentParser( description='some description')
parser.add_argument("-f", "--file", help="file that contains length of contigs", nargs=1)
parser.add_argument("-q", "--qtlfile", help="file that contains qtls", nargs=1)
parser.add_argument("-c", "--column_with_qtltypes", help="column in qtlfile to use for qtltypes", nargs=1)
parser.add_argument("-s", "--snpfile", help="file that contains snps", nargs=1)
parser.add_argument("-b", "--binsize", help="size of the intervals, in bp", nargs=1)
parser.add_argument("-n", "--numreps", help="number of replicates", nargs=1)
args = parser.parse_args()

class test_overlap:

   def __init__(self,contigsizefilenm,snpfilenm,qtlfilenm,column,numreps=100,binsize=10000):
      self.contigsizefilenm=contigsizefilenm
      self.snpfilenm=snpfilenm
      self.qtlfilenm=qtlfilenm
      self.numreps=numreps
      self.binsize=binsize
      self.column=column
      self.bins=list()
      self._return_bins()
      self.qtls=list()
      self.qtltypes=set()
      self._return_qtls()
      self.snps=list()
      self._get_snppos()
      self.snpoverlap=dict()
      self.snpoverlappermuted=dict()
   
   def set_numreps(self,numreps):
      self.numreps=numreps
  
   def _return_bins(self):
      fh=open(self.contigsizefilenm)
      for line in fh.readlines():
         (contig,size)=line[:-1].split('\t')
         size=int(size)
         remain=size % self.binsize
         numbins=0
         if size > self.binsize:
            numbins= int(size/self.binsize)
         for bin in range(numbins):
            start=1+bin*self.binsize
            end=(bin+1)*self.binsize
            self.bins.append([contig,start,end])
            #print("{}\t{}\t{}".format(contig,str(start),str(end)))
         if remain > 1:
            start=1+numbins*self.binsize
            end=numbins*self.binsize+remain
            self.bins.append([contig,start,end])
            #print("{}\t{}\t{}".format(contig,str(start),str(end)))

      print('number of bins: ',len(self.bins))

   def _return_qtls(self):
      fh=open(self.qtlfilenm)
      for line in fh.readlines():
         parts=line[:-1].split('\t')
         self.qtls.append([parts[0],parts[1],parts[2],parts[self.column]])
         self.qtltypes.add(parts[self.column])
      fh.close()

   def genome_coverage(self):
      self.typedict={qtltype:0 for qtltype in self.qtltypes}
      
      fh=open(self.qtlfilenm)
      for line in fh.readlines():
         parts=line[:-1].split('\t')
         self.typedict[parts[3]]+=int(parts[2])-int(parts[1])
      fh.close()
      for qtltype in self.typedict.keys():
         print(qtltype,self.typedict[qtltype])
 
      
   def check_overlap(self,snppos,qtltype):
      hit=0 
      for qtl in self.qtls:
         if qtl[0] == snppos[0] and (int(snppos[1])<int(qtl[2]) and int(snppos[1])>int(qtl[1])) and qtl[3] == qtltype:
            hit=1
      return hit
   
   def _get_snppos(self):
      fh=open(self.snpfilenm)
      for line in fh.readlines():
         parts=line[:-1].split('\t')
         self.snps.append([parts[0],parts[1]])
      fh.close()
      
   def _overlap(self,snps,qtltype):
      total=0
      for snp in snps:
         total+=self.check_overlap(snp,qtltype)
      return total

   def find_overlap(self):
      for qtltype in self.qtltypes:
         total=self._overlap(self.snps,qtltype)
         self.snpoverlap[qtltype]=total
         print(qtltype,total)

   def find_overlaps_permuted_allqtltypes(self):
      for qtltype in self.qtltypes:
         self.find_overlaps(qtltype)

   def find_overlaps(self,qtltype):
      roverlaps=list()
      for i in range(self.numreps):
         rbins=random.sample(self.bins,len(self.snps))
         rsnps=list()
         for rbin in rbins:
            offset=random.randint(0,self.binsize)
            rsnps.append([rbin[0],rbin[1]+offset])
         roverlaps.append(self._overlap(rsnps,qtltype))
      
      self.snpoverlappermuted[qtltype]=roverlaps

   def print_permutation_results(self):
      for key in self.snpoverlappermuted.keys():
         #print(key,self.snpoverlap[key])
         #print(key,self.snpoverlappermuted[key])
         percentile=stats.percentileofscore(self.snpoverlappermuted[key], self.snpoverlap[key])
         meanoverlap= np.mean(self.snpoverlappermuted[key])
         numiters=len(self.snpoverlappermuted[key])
         print('{}\t{:d}\t{:.2f}\t{:d}\t{:.4f}'.format(key,self.snpoverlap[key],meanoverlap,numiters,1-(percentile/100)))


if __name__ == '__main__':
   
   contigsizefilenm=args.file[0]
   
   snpfilenm=args.snpfile[0]
   qtlfilenm=args.qtlfile[0]
   numreps=int(args.numreps[0])
   binsize=int(args.binsize[0])
   qtlcolumn=int(args.column_with_qtltypes[0])
      
   overlaptester=test_overlap(contigsizefilenm,snpfilenm,qtlfilenm,qtlcolumn,numreps,binsize)
   print('numreps: ',overlaptester.numreps)
   
   overlaptester.find_overlap()
   qtltypes=overlaptester.qtltypes
   for qtltype in qtltypes:
      if overlaptester.snpoverlap[qtltype]>0:
         
        overlaptester.find_overlaps(qtltype)
   
   #overlaptester.find_overlaps_permuted_allqtltypes()
   #overlaptester.print_permutation_results()
   
   #overlaptester.set_numreps(100)
   #print('numreps: ',overlaptester.numreps)
   #overlaptester.find_overlaps("Meat_&_Carcass_Quality_eQTL")
   overlaptester.print_permutation_results()


