import argparse
import sys
import os

# Data preparation:
# plink --noweb --file hm8_5 --recode12  --missing-genotype N --output-missing-genotype 0 --out hm8_5_recode12 --exclude ignoresnps.txt --geno 0.2
# cat hm8_5_recode12.ped | grep '^SCEL' >outgroups_sus_recode12.ped
# cat hm8_5_recode12.ped | grep '^SVSV' >>outgroups_sus_recode12.ped
# cat hm8_5_recode12.ped | grep '^SCEB' >>outgroups_sus_recode12.ped
# cp hm8_5_recode12.map outgroups_sus_recode12.map
# for CHROM in `seq 1 18`; do plink --noweb --file hm8_5_recode12 --chr $CHROM --recode  --missing-genotype 0 --output-missing-genotype 0 --out chr$CHROM; done
# for CHROM in `seq 1 18`; do plink --noweb --file outgroups_sus_recode12 --chr $CHROM --freq  --missing-genotype 0 --out outgroupfreq_chr$CHROM; done


parser = argparse.ArgumentParser( description='calculate heterozygosities for individuals in a ped file')
parser.add_argument("-f", "--pedfile_stub", help="name of pedfile stub", nargs=1)
parser.add_argument("-p", "--population", help="name of or string of names of population(s)", nargs=1)

args = parser.parse_args()
pedfile_stub=args.pedfile_stub[0]
pops=args.population[0].split(' ')

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

def remove_ped_if_already_present(label,pedfile_stub):
   for i in range(1,19):
      remove_file_if_exists(label+pedfile_stub+str(i)+'.ped')

def phase_with_shapeit(label,pedfile_stub):
   for i in range(1,19):
      remove_file_if_exists(label+pedfile_stub+str(i)+".phased.haps")
      remove_file_if_exists(label+pedfile_stub+str(i)+".phased.sample")

      shapeit_command="/cm/shared/apps/SHARED/shapeit/shapeit2.r769/shapeit --input-ped "+label+pedfile_stub+str(i)+'.ped '+label+pedfile_stub+str(i)+".map  -O "+label+pedfile_stub+str(i)+".phased --missing-code 0 -W 5"
      print(shapeit_command)
      os.system(shapeit_command)
      os.popen("rm shapeit_*")

def create_ped(pop,pedfile_stub,label):
   for i in range(1,19):
      remove_file_if_exists(label+pedfile_stub+str(i)+'_int.ped')
      remove_file_if_exists(label+pedfile_stub+str(i)+'_int.map')
      os.system('cat '+pedfile_stub+str(i)+'.ped | grep ^'+pop+' >>'+label+pedfile_stub+str(i)+'_int.ped')
      os.system('cp '+pedfile_stub+str(i)+'.map '+label+pedfile_stub+str(i)+'_int.map')
      os.system('plink --noweb --file '+label+pedfile_stub+str(i)+'_int --chr '+str(i)+' --recode --geno 0.1 --missing-genotype 0 --output-missing-genotype 0 --out '+label+pedfile_stub+str(i))
      #os.remove(label+pedfile_stub+str(i)+'_int.ped')
      #os.remove(label+pedfile_stub+str(i)+'_int.map')

def remove_file_if_exists(file):
   try:
         if os.stat(file):
            os.remove(file)
            print("removed old file: "+file)
   except OSError:
      pass

def make_snpinfo(label,pedfile_stub):
   remove_file_if_exists(label+"snp.info")
   for i in range(1,19):
      os.popen("cat "+label+pedfile_stub+str(i)+".phased.haps | awk '{print $2"+'" "$1" "$3" 1 2"}'+"' >>"+label+"snp.info")

def make_haplotype_file(label,pedfile_stub):
   for i in range(1,19):
      command='cut -f1,2 -d" " '+label+pedfile_stub+str(i)+".phased.sample | sed 's/ /_/' | awk '{print $0"+'"'+r'\n'+'"$0"1"}'+"' | sed 1d | sed 1d | sed 1d | sed 1d >"+label+pedfile_stub+str(i)+".duplo_inds"
      print(command)
      os.system(command)
      command="sed 's/ /"+r'\t'+"/' "+label+pedfile_stub+str(i)+".phased.haps | sed 's/ /"+r'\t'+"/' | sed 's/ /"+r'\t/'+"' | sed 's/ /"+r'\t'+"/' | sed 's/ /"+r'\t'+"/' | cut -f6 | java -jar  /cm/shared/apps/SHARED/beagle/beagle4.r1230/transpose.jar | sed 's/1/2/g' | sed 's/0/1/g' >"+label+pedfile_stub+str(i)+".haplo_inds"
      print(command)
      os.system(command)
      command="paste "+label+pedfile_stub+str(i)+".duplo_inds  "+label+pedfile_stub+str(i)+".haplo_inds  | sed 's/"+r'\t'+"/ /' >"+label+pedfile_stub+str(i)+".phased60K.hap"
      print(command)
      os.system(command)
   

def do_rehh(label,pedfile_stub):
   rscriptfile=open(label+"_rehh.R","w")
   
   rscriptfile.write("library(rehh)"+"\n")
   for i in range(1,19):
      rscriptfile.write("data<-data2haplohh(hap_file='"+label+pedfile_stub+str(i)+".phased60K.hap','"+label+"snp.info',chr.name="+str(i)+")\n")
      if i == 1:
         rscriptfile.write("res<-scan_hh(data)\nwg.res<-res\n")
      elif i > 1:
         rscriptfile.write("res<-scan_hh(data)\nwg.res<-rbind(wg.res,res)\n")
   rscriptfile.write("wg.ihs<-ihh2ihs(wg.res)\n")
   rscriptfile.write("write.table(wg.ihs$res.ihs, file='"+label+"iHS_60K.txt')\n")
   rscriptfile.write("pdf('"+label+"full_60K_REHH.pdf')\n")
   rscriptfile.write("par(mfrow=c(2,1))\nihsplot(wg.ihs$res.ihs,plot.pval=TRUE,ylim.scan=2,main='"+label+" iHS 60K')\ndev.off()\n")
   rscriptfile.write("png('"+label+"full_60K_REHH.png',width=2000, height=1800)\n")
   rscriptfile.write("par(mfrow=c(2,1))\nihsplot(wg.ihs$res.ihs,plot.pval=TRUE,ylim.scan=2,main='"+label+" iHS 60K')\ndev.off()\n")
   rscriptfile.close()
   os.system('R CMD BATCH '+label+'_rehh.R')

if __name__=="__main__":
   poplabel=''.join(pops)
   print(poplabel)
   remove_ped_if_already_present(poplabel,pedfile_stub)
   for pop in pops:
      print(pop)
      create_ped(pop,pedfile_stub,poplabel)
   phase_with_shapeit(poplabel,pedfile_stub)   
   make_snpinfo(poplabel,pedfile_stub)
   make_haplotype_file(poplabel,pedfile_stub)
   do_rehh(poplabel,pedfile_stub)
