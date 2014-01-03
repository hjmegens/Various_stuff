import sys

def read_enzymes_from_file(filename):
	with open(filename) as file:
		skip_intro(file)
		return (get_enzymes(file),get_references(file))

def skip_intro(file):
	line=''
	while not line.startswith('<REFERENCES>'):
		#print(line)
		line = file.readline()
	while len(line) > 1:
		#print(len(line),line)
		line = file.readline()
	return line

def get_enzymes(src):
	enzymes = {}
	enzyme = next_enzyme(src)
	while enzyme:
		enzymes[enzyme[0]]=enzyme
		enzyme = next_enzyme(src)
	return enzymes

def read_field(file):
	return file.readline()[3:-1]

def read_other_fields(file):
	return [read_field(file) for n in range(7)]

def next_enzyme(file):
	name = read_field(file)
	if name:
		fields = [name]+read_other_fields(file)
		fields[2] = parse_organism(fields[2])
		fields[7] = [int(num) for num in fields[7].split(',')]
		file.readline()
		return fields

def parse_organism(org):
	parts = org.split(' ')
	if len(parts) == 2:
		parts.append(None)
	elif len(parts) > 3:
		parts[2:] = ' '.join(parts[2:])
	return tuple(parts)

def skip_reference_heading(file):
	line = file.readline()
	while not line.startswith('References:'):
		line = file.readline()
	file.readline()

def next_reference(file):
	line = file.readline()
	if len(line) < 2:
		return (None,None)
	else:
		return (int(line[:4]),line[7:-1])

def get_references(file):
	refs = {}
	skip_reference_heading(file)
	refnum, ref = next_reference(file)
	while refnum:
		refs[refnum]=ref
		refnum,ref = next_reference(file)
	return refs

if __name__ == "__main__":
	if len(sys.argv)<2:
		filename = 'link_allenz'
	elif len(sys.argv) == 2:
		filename = sys.argv[1]
	else:
		print('Usage: read_enzymes [filename]')
	enzymes, references = read_enzymes_from_file(filename)
	print('Read',len(enzymes), 'enzymes and', len(references), 'references')


