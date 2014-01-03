import sqlite3
import sys

def create_db(datafilename):
	conn = sqlite3.connect(datafilename)
	try:
		conn.executescript('''
drop table if exists Organism;

create table Organism(
	OrgID integer primary key,
	Genus text not null,
	Species text not null,
	Subspecies text
	);
	
	''')
		
	except sqlite3.OperationalError as err:
		print(err, file=sys.stderr)
		conn.rollback()
		raise
	
	conn.commit()


if __name__ == "__main__":
	create_db('rebase')


