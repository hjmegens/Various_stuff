#!/usr/bin/python
import fileinput
import sys
def count_bases(filename):
    dna = 'ACGTN'
    dna += dna.lower()
    hash= {key: 0 for key in dna}
    with open(filename) as file:
        line=file.readline()
        while line:
             line=file.readline()
             #print(line)
             #print(type(line))
             for base in dna:
                #pass
                hash[base]+=line.count(base)
    return hash

print(sys.argv[1])
hash = count_bases(sys.argv[1]) 
for keys in hash:
    print(keys,hash[keys])
