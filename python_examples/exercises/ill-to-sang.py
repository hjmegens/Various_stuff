import sys

def next_sequence(filename):
    with open(filename) as file:
        line = file.readline()
        while line:
            if line and line[0] == '@':
                line1 = line
                line2 = file.readline()
                line3 = file.readline()
                line4 = file.readline()
            yield (line1,line2,line3,line4)
            line = file.readline()

def convert_illumina_to_sanger(file):
    seqs = next_sequence(file)
    for seq in seqs:
         qs = seq[3][0:-1]
         Qs = [chr(ord(q)-31) for q in qs]
         Q = ''.join(Qs)
         print seq[0]+seq[1]+seq[2]+Q

convert_illumina_to_sanger(sys.argv[1])
