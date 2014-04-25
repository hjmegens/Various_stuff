import argparse
import sys
import os
import re
import gzip

#X	51054777	.	C	.	.	PASS	END=51054812;BLOCKAVG_min30p3a	GT:DP:GQX:MQ	0/0:14:42:60
#X	51054813	.	T	.	.	PASS	.	GT:DP:GQX:MQ	0/0:19:57:60
#X	51054814	.	G	.	.	PASS	.	GT:DP:GQX:MQ	0/0:19:26:60
#X	51054815	.	T	.	.	PASS	END=51054883;BLOCKAVG_min30p3a	GT:DP:GQX:MQ	0/0:16:48:60
#X	51054884	.	C	.	.	PASS	END=51054903;BLOCKAVG_min30p3a	GT:DP:GQX:MQ	0/0:19:54:60
#X	51054904	.	T	C	769	PASS	DP=20;Dels=0.00;FS=0.000;HaplotypeScore=0.0000;MLEAC=2;MLEAF=1.00;MQ=60;MQ0=0;QD=38.45;S
#B=-3.920e+02	GT:AD:DP:GQ:PL:MQ:GQX	1/1:0,20:20:60:802,60,0:60:60
#X	51054905	.	T	.	.	PASS	END=51054956;BLOCKAVG_min30p3a	GT:DP:GQX:MQ	0/0:17:51:60
#X	51054957	.	A	.	.	PASS	END=51054991;BLOCKAVG_min30p3a	GT:DP:GQX:MQ	0/0:14:42:58


parser = argparse.ArgumentParser( description='some description')
parser.add_argument("-s", "--snplist", help="input snplist stub", nargs=1)
parser.add_argument("-i", "--individual_list", help="input individual name file", nargs=1)
parser.add_argument("-o", "--output_stub", help="stub of output name", nargs=1)
parser.add_argument("-r", "--ref_bases", help="file containing reference bases per snp", nargs=1)
parser.add_argument("-m", "--method", help="method, tabix or direct", nargs=1)
parser.add_argument("-d", "--directory", help="directory where gvcfs are located", type=str, default='')
parser.add_argument("-p", "--postfix", help="postfix of gvcf", nargs=1)
parser.add_argument("-x", "--make_matrix", help="create matrix from vcf tags", action="store_true")
parser.add_argument("-R", "--rs_annotation", help="do annotation of rs numbers", action="store_true")

args = parser.parse_args()

def return_snplist(stub):
   snplist=list()
   fh=open(stub)
   for line in fh.readlines():
      snplist.append(line[:-1].split("\t"))
   fh.close()
   return snplist

def return_refbases(file):
   refdict=dict()
   fh=open(file)
   for line in fh.readlines():
      (snp,refallele)=line[:-1].split("\t")
      refdict[snp]=refallele
   fh.close()
   return refdict

def make_map_file(stub,snps,allgt):
   fh=open(stub+".map","w")
   gt=allgt[0]
   for i in range(1,len(gt)):
      snp=snps[i-1]
      alleles=set()
      for j in range(len(allgt)):
         (allele1,allele2)=allgt[j][i]
         if allele1 != 'N':
            alleles.add(allele1)
            alleles.add(allele2)
      if len(alleles) < 3:
         fh.write(snp[1]+"\t"+snp[0]+"\t0\t"+snp[2]+"\n")

def get_inds(file):
   fh=open(file)
   inds=list()
   for line in fh.readlines():
      inds.append(line[:-1])
   fh.close()
   return inds

def return_snps_per_individual_tabix(ind,snplist,directory,postfix,refdict):
   print(ind)
   gt=list()
   gt.append([ind])
   mx=list()
   mx.append([ind])
   for snp in snplist:
      refstate=refdict[snp[0]]
      command="tabix "+directory+ind+postfix+" "+snp[1]+":"+snp[2]+"-"+snp[2]
      snpfromvcf=os.popen(command).read()[:-1].split("\t")
#     print(snpfromvcf)
#     print(len(snpfromvcf))
#     print(snp,refstate,geno,altallele)
      (gt,mx)=append_alleles(gt,snpfromvcf,refstate,mx)
#     print(len(gt))
   return (gt,mx)

def write_pedfile(allgt,stub,snplist):
   fh=open(stub+".ped","w")
   gt=allgt[0]
   locuslist=list()
   for i in range(1,len(gt)):
      alleles=set()
      for j in range(len(allgt)):
         (allele1,allele2)=allgt[j][i]
         if allele1 != 'N':
            alleles.add(allele1)
            alleles.add(allele2)
      if len(alleles) < 3:
         locuslist.append(i)   
      else:
         print("OMITING SNP",i)
   
   for gt in allgt:
      fh.write("DUM\t"+gt[0][0]+"\t0\t0\t0\t0")
      for i in locuslist:
         fh.write("\t"+gt[i][0]+"\t"+gt[i][1])
      fh.write("\n")
   fh.close()
   make_map_file(outfilestub,snplist,allgt)


def write_matrix(allgt,stub,snplist,allmx,rsdict,refdict):
   #CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	AS01F01  ...
   fh=open(stub+".mx","w")
   fh.write("#{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}".format('#CHROM','POS','ID','REF','ALT','QUAL','FILTER','INFO','FORMAT'))
   for i in range(len(allmx)):
      fh.write("\t{}".format(allmx[i][0][0]))
   fh.write('\n')
   lenallmx=len(allmx)
   gt=allgt[0]
   for i in range(1,len(gt)):
      alleles=set()
      for j in range(len(allgt)):
         (allele1,allele2)=allgt[j][i]
         if allele1 != 'N':
            alleles.add(allele1)
            alleles.add(allele2)
      if len(alleles) < 3:
         snp=snplist[i-1]
         alleles=list(alleles)
         if len(alleles)==2:
            alt=alleles[0]
            if refdict[snp[0]]==alleles[0]:
               alt=alleles[1]
            fh.write("{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}".format(snp[1],snp[2],snp[0],refdict[snp[0]],alt,'.','.','.','.'))
            for j in range(lenallmx):
              fh.write("\t"+allmx[j][i][0])
            fh.write("\n")

      else:
         print("OMITING SNP",i)
   fh.close()

def append_alleles(gt,snpfromvcf,refstate,mx):
   if len(snpfromvcf)>1:
      parts=snpfromvcf[9].split(":",1)
      geno=parts[0]
      nongeno=str()
      if len(parts)>1:
         nongeno=parts[1]
         
      altallele=snpfromvcf[4]
      refallele=snpfromvcf[3]
      vcfchrom=snpfromvcf[0]
      vcfpos=snpfromvcf[1]
      if altallele != '.' and refallele != refstate:
         print("WARNING: disagreement between ref-alleles - ")
         print(snpfromvcf)
         gt.append(["N","N"])
         mx.append(['./.'])
#     print(snp,refstate,geno,altallele)
      elif geno == './.':
         gt.append(["N","N"])
         mx.append(['./.'])
      elif geno == '0/0':
         gt.append([refstate,refstate])
         mx.append([refstate+'/'+refstate+':'+nongeno])
      elif geno == '0/1' and len(altallele)==1:
         gt.append([refstate,altallele])
         mx.append([refstate+'/'+altallele+':'+nongeno])
      elif geno == '1/1' and len(altallele)==1:
         gt.append([altallele,altallele])
         mx.append([altallele+'/'+altallele+':'+nongeno])
      else:
         gt.append(["N","N"])
         mx.append(['./.'])

   else:
      gt.append(["N","N"])
      mx.append(['./.'])
      print("WARNING: no line found!")
   return (gt,mx)

def get_vcf_line_components(line):
   snpfromvcf=line.split("\t")
   geno='./.'
   altallele='.'
   refallele='Q'
   vcfchrom='0'
   vcfpos='0'
   if len(snpfromvcf)>1:
      geno=snpfromvcf[9].split(":")[0]
      refallele=snpfromvcf[3]
      vcfchrom=snpfromvcf[0]
      vcfpos=snpfromvcf[1]
   return [vcfchrom,vcfpos,refallele,altallele]

def return_snps_per_individual_gvcfdirect(ind,snplist,directory,postfix,refdict):
   gt=list()
   gt.append([ind])
   mx=list()
   mx.append([ind])
   print(ind)
   try:
      fileh = gzip.open(directory+ind+postfix)
      line = fileh.readline()[:-1].decode('utf-8')
      previousline=''
      while line.startswith('#'):
         line = fileh.readline()[:-1].decode('utf-8')
      components=get_vcf_line_components(line)
      for snp in snplist:
         refstate=refdict[snp[0]]
         #print(snp,components)
         while line and (components[0]!=snp[1] or int(components[1])<int(snp[2])):
            previousline=line
            line = fileh.readline()[:-1].decode('utf-8')
            #print(line)
            components=get_vcf_line_components(line)

         if int(components[1])==int(snp[2]):
            snpfromvcf=line.split("\t")
            (gt,mx)=append_alleles(gt,snpfromvcf,refstate,mx)
         elif int(components[1]) > int(snp[2]):
             snpfromvcf=previousline.split("\t")
             state=snpfromvcf[7].split(";")[0]
             if state.startswith('END'):
                blockend=int(state.split('=')[1])
                #print("blockend:",blockend)
                if int(snp[2]) <= blockend:
                   #print("blockend within bounds")
                   (gt,mx)=append_alleles(gt,snpfromvcf,refstate,mx)
                else:   
                   #print("blockend OUT OF bounds")
                   (gt,mx)=append_alleles(gt,[''],refstate,mx)
             else:
                (gt,mx)=append_alleles(gt,[''],refstate,mx)
                
         else:
            (gt,mx)=append_alleles(gt,[''],refstate,mx)
         #print(gt)
   finally:
        fileh.close()
   return (gt,mx)

def get_rs_numbers(rsdict):
   fh=open('dbsnp_tmp.vcf')
   for line in fh.readlines():
      parts=line[:-1].split('\t')
      rsdict[parts[0]+"_"+parts[1]]=parts[2]
   fh.close()

if __name__ == '__main__':
   snpstub=args.snplist[0]
   directory=args.directory
   mxflag=args.make_matrix
   postfix=args.postfix[0]
   individuals_file=args.individual_list[0]
   outfilestub=args.output_stub[0]
   ref_bases_file=args.ref_bases[0]
   method=args.method[0]
   rsflag=args.rs_annotation
   rsdict=dict()
   if rsflag:
      rsdict=get_rs_numbers
      
   snplist=return_snplist(snpstub)
   print(len(snplist))
   refdict=return_refbases(ref_bases_file)
   print(len(refdict))
   inds = get_inds(individuals_file)
   allgt=list()
   allmx=list()
   for ind in inds:
      if method == 'tabix':
         (gt,mx)=return_snps_per_individual_tabix(ind,snplist,directory,postfix,refdict)
      elif method == 'direct':
         (gt,mx)=return_snps_per_individual_gvcfdirect(ind,snplist,directory,postfix,refdict)
      #print(len(gt),gt)
      allgt.append(gt)
      if mxflag:
         allmx.append(mx)
   write_pedfile(allgt,outfilestub,snplist)
   write_matrix(allgt,outfilestub,snplist,allmx,rsdict,refdict)
   
   

