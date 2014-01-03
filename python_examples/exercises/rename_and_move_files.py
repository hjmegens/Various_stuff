import argparse
import sys
import os
import re

parser = argparse.ArgumentParser( description='Aligns fasta file and returns stats per aligned base')
parser.add_argument("-t", "--translatetable", help="translatetable", nargs=1)

def rename():
  translist = translatetable(transfile)
  fqlist = fq_filelist()
  fqhash={}
  for fq in fqlist:
    print(fq)
    for element in translist:
      rex = element[1]+'_\w+-\d+(_\d)'
      nwfqname=re.sub(rex,element[3]+'_'+element[2]+'_'+element[0]+'_'+element[1]+r'\1', fq)
      if (nwfqname != fq):
        fqhash[fq]=nwfqname
  for item in fqhash.keys():
    print(item+' ---> '+fqhash[item])
    os.rename(item,fqhash[item])

def move():
  translist = translatetable(transfile)
  fqlist = fq_filelist()
  for element in translist:
    try:
      os.stat(element[3])
    except OSError:
      os.mkdir(element[3]) 
    
    for fq in fqlist:
      if fq.startswith(element[3]):
        os.rename(fq,element[3]+'/'+fq)

def fq_filelist():
  fqlist=os.popen('ls *.fq.gz').read().split('\n')
  return fqlist

def translatetable(trans_file):
  flist=[]
  with open(trans_file) as trans:
    for l in trans.readlines():
      l=l.rstrip().split()
      flist.append([l[0],l[1],l[2],l[3]])
  return flist



args = parser.parse_args()
transfile=args.translatetable[0]

if __name__=="__main__":
  rename()
  move()
