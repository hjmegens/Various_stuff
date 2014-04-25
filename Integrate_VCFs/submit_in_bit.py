import sys
import argparse
import os
import time
parser = argparse.ArgumentParser( description='some description')

parser.add_argument("-f", "--file", help="file that contains intervals", nargs=1)
#parser.add_argument("-b", "--binsize", help="size of the intervals, in bp", nargs=1)
args = parser.parse_args()

file=args.file[0]
#binsize=int(args.binsize[0])
intervals=list()
fh=open(file)
intervals=[line[:-1].split('\t') for line in fh.readlines()]
fh.close()
numintervals=len(intervals)
i=0
while i < numintervals:
   numjobs=os.popen("squeue | grep all_vcf | wc -l").read()
   print(numjobs)
   print("number of running all_vcf jobs: "+str(numjobs))
   if int(numjobs)<11:
      print(intervals[i])
      command="sbatch do_vcf_intervals_allbams.sh "+str(intervals[i][0])+" "+str(intervals[i][1])+" "+intervals[i][2]
      print(command)
      os.system(command)
      i+=1
      print("less than 10 jobs currently running")
      print(str(i))
   else:
      print("more than 10 jobs currently running")  
   time.sleep(10)
   
   
