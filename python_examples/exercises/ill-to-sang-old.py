
#!/usr/bin/env python
#Daniel Klevebring, 2010-04-07
# encoding: utf-8
"""
fqi2fqs.py.py
Converts illumina 1.3+ fastq to sanger fastq. Does not depend on biopython or galaxy. Does not perform error-checking.
Version 1.1

"""
import sys
import gzip

def main(argv=None):
if argv is None:
argv = sys.argv

if len(argv) < 2:
print "This script converts illumina 1.3+ fastq to sanger fastq. It does not depend on biopython or galaxy."
print "NOTE! This is a pretty stupid script that does not perform any checking to make sure the infile is "
print "illumina 1.3+ fastq. Neither can it handle newlines or comments in the infile. "
print
print "USAGE: fqi2fqs.py infile.fastq_illumina.gz | gzip > outfile.fastq_sanger.gz"
sys.exit(1)

fin = gzip.open( argv[1], 'rb' )

while True:
line1 = fin.readline()
line2 = fin.readline()
line3 = fin.readline()
line4 = fin.readline().rstrip()

if not line1: break #we're at EOF

print line1,
print line2,
print line3,

for q in list(line4):
sys.stdout.write( chr( ord(q) - 31 ) ) #this converts from illumina 1.3+ to sanger phred scores

print #to add a newline after the new qual has been printed

if __name__ == "__main__": main()

# $Q = 10 * log(1 + 10 ** (ord($sq) - 64) / 10.0)) / log(10);
