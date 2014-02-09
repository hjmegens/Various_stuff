import sys
import sqlite3
filenm = sys.argv[1]
conn = sqlite3.connect('turkey_schema.db')

with open(filenm) as file:
   line1 = file.readline()[:-1].split('\t')
   line2 = file.readline()[:-1].split('\t')
   print(line1[1])
   table = line1[1]
   conn.execute('delete from '+line1[1])
   for line in file:
      line =  line[:-1].split('\t')
      print(line)
      conn.execute('insert into '+ table + '('+', '.join(line2)+') values('+', '.join('?'*len(line2))+')',line)
   conn.commit()
   results = conn.execute('select * from '+table)
   for qline in results:
      print(qline)

