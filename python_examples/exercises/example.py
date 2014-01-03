def read_regions (filename):
    with open(filename) as file:
        return [line[:-1].split(',') for line in file]

def next_sequence(filename):
    with open(filename) as file:
        seq = ''
        name = file.readline()
        name = name[1:-1]
        line = file.readline()
        while line:
            while line and line[0] != '>':
                seq += line[:-1]
                line = file.readline()
            yield (name,seq)
            seq = ''
            name = line[1:-1]
            line = file.readline()

def extract_slice_from_seqs(file1,file2):
    regions = read_regions(file1)
    seqs = next_sequence(file2)
    for seq in seqs:
        for region in regions:
            if region[0] == seq[0]:
                start = int(region[2])-1
		end = int(region[3])
                print '>'+region[0]+'-'+region[1]+'\n'+seq[1][start:end]

extract_slice_from_seqs('example.txt','example.fa')
