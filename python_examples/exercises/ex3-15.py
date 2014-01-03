def read_FASTA(filename):
    with open(filename) as file:
        contents = file.read()
    entries = contents.split('>')[1:]
    partitioned_entries = [entry.partition('\n') for entry in entries]
    pairs = [(entry[0],entry[2]) for entry in partitioned_entries]
    pairs2 = [(pair[0],pair[1].replace('\n','')) for pair in pairs]
    result = [(pair[0].split('|'),pair[1])for pair in pairs2]
    return pairs2

results = read_FASTA('example.txt')
print(type(results))
#print([(result[0][0],result[1]) for result in results if result[0][0].find('eq2')<0])
#print([(result[0][0],result[1]) for result in results if result[0][0].find('eq2')>0])
print([(result[0],result[1]) for result in results if result[0].find('eq2')<0])
print([(result[0],result[1]) for result in results if result[0].find('eq2')>0])
