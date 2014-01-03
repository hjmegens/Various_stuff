import sqlite3
import sys

def create_db(datafilename):
	conn = sqlite3.connect(datafilename)
	try:
		conn.executescript('''
DROP TABLE IF EXISTS Organism;
DROP TABLE IF EXISTS Reference;
DROP TABLE IF EXISTS Enzyme;
DROP TABLE IF EXISTS EnzymeReference;
	
create table Organism(
	OrgID integer primary key,
	Genus text not null,
	Species text not null,
	Subspecies text
	);
	
create table Reference(
	RefID integer primary key,
	Details text not null
	);
	
create table Enzyme(
	Name text primary key,
	Prototype text,
	OrgID integer not null references Organism(OrgID),
	Source text not null,
	RecogSeq text not null,
	TopCutPos integer,
	BottomCutPos integer,
	TopCutPos2 integer,
	BottomCutPos2 integer
	);
	
create table EnzymeReference(
	Enzyme text not null references Enzyme(Name),
	RefID integer not null references Reference(RefID),
	primary key(Enzyme, RefID)
	);
	''')
		
	except sqlite3.OperationalError as err:
		print(err, file=sys.stderr)
		conn.rollback()
		raise
	
	conn.commit()

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
		if len(fields[2])>3:
			print(fields)
		file.readline()
		return fields

def parse_organism(org):
	parts = org.split(' ')
	if len(parts) == 2:
		parts.append(None)
	elif len(parts) > 3:
		parts[2:] = ' '.join(parts[2:])
	return tuple(parts[:3])

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

def make_insert_string(tablename,n):
	return ('INSERT INTO '+ tablename + ' VALUES ' + '(' + ', '.join('?' * n) + ')')

STORE_STMTS={tablename: make_insert_string(tablename,ncols) for tablename,ncols in (('Organism',4),('Reference',2),('Enzyme',9),('EnzymeReference',2))}

def store_data(conn, tablename, data):
	try:
		
		#print(STORE_STMTS[tablename],data)
		conn.execute(STORE_STMTS[tablename],data)
		#conn.commit()
	except sqlite3.OperationalError as ex:
		print(ex)
		raise

def load_data(dbname, enzymes, references):
	try:
		conn = sqlite3.connect(dbname)
		load_reference_data(conn, references)
		organism_ids = load_organism_data(conn,enzymes)
		#print(organism_ids)
		load_enzyme_data(conn,enzymes,organism_ids)
		load_enzyme_reference_data(conn,enzymes)
		conn.commit()
	except sqlite3.OperationalError as ex:
		print(ex, file=sys.stderr)
		raise

def load_reference_data(conn, references):
	for refid, ref in references.items():
		#print(refid,ref)
		store_data(conn, 'Reference', (refid,ref))

def load_organism_data(conn, enzyme_data):
	organism_ids = {}
	for orgid, data in enumerate(enzyme_data.values()):
		org = data[2]
		if not org in organism_ids:
			store_data(conn, 'Organism',(orgid+1,)+org)
			organism_ids[org]=orgid+1
	return organism_ids

def load_enzyme_data(conn, enzymes, organism_ids):
	for data in enzymes.values():
		store_data(conn,'Enzyme',(data[0],data[1] or None,organism_ids[data[2]],data[3],data[4],0,0,0,0))

def load_enzyme_reference_data(conn,enzymes):
	for data in enzymes.values():
		for refid in data[7]:
			store_data(conn,'EnzymeReference',(data[0],refid))




	

if __name__ == "__main__":
	if len(sys.argv)<2:
		filename = 'link_allenz'
	elif len(sys.argv) == 2:
		filename = sys.argv[1]
	else:
		print('Usage: read_enzymes [filename]')
	enzymes, references = read_enzymes_from_file(filename)
	print('Read',len(enzymes), 'enzymes and', len(references), 'references')
	create_db('rebase')
	#print(enzymes)
	load_data('rebase',enzymes,references)
	#print(STORE_STMTS)


