import sys
from pg8000 import DBAPI
filenm = sys.argv[1]
conn = DBAPI.connect(host='localhost',database='test1',user='test',password='test')
cursor = conn.cursor()
with open(filenm) as file:
	line1 = file.readline()[:-1].split('\t')
	line2 = file.readline()[:-1].split('\t')
	print(line1[1])
	table = line1[1]
	try:
		cursor.execute('delete from '+line1[1])
		conn.commit()
	finally:
		pass

	for line in file:
		line =  line[:-1].split('\t')
		print(line)
		cursor.execute('insert into '+ table + ' values(%s,%s)',line)
	conn.commit()
	cursor.execute('select * from '+table)
	results = cursor.fetchall()
	for qline in results:
		print(qline)
cursor.close()
conn.close()

# http://pybrary.net/pg8000/interactiveexample.html
