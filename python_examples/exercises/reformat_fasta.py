import argparse
import sys
import os

parser = argparse.ArgumentParser( description='reformat fasta files per desired length of lines')
parser.add_argument("-l", "--length", help="length of each fasta line", nargs=1)

args = parser.parse_args()
length=int(args.length[0])

seqs = sys.stdin.read().split('>')[1:]
seqs = [ element.split('\n',1) for element in seqs]
seqs = [[element[0],element[1].replace('\n','')] for element in seqs]
for seq in seqs:
  print('>',seq[0], sep='')
  for i in range(0,len(seq[1]),length):
    print(seq[1][i:i+length])



