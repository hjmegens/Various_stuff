import argparse
import sys
import os
import re

parser = argparse.ArgumentParser( description='creates a new name for a sequence file name that is more consistent')
parser.add_argument("-f", "--filename", help="input filename", nargs=1)

args = parser.parse_args()
oldname=args.filename[0]
parts=oldname.split('_R')
parts2=parts[1].split('.',1)
parts3=parts2[0].split('_')
newname=parts[0]+'_'+parts3[1]+'_R'+parts3[0]+'.'+parts2[1]
print(oldname+' ---> '+newname)
os.rename(oldname,newname)
