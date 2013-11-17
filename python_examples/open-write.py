import sys
import re
filenm = sys.argv[1]
with open(filenm) as file:
	with open("testout"+filenm,'w') as file2:
		for line in file:
			line = line[:-1]
			array_tupple = line.split(":")
			tupple = re.findall(r'(.+):(.+):(.+)', line, re.M)
			print(tupple)
			print(line)
			line = re.subn(r'(colom[123])','COLOM5',line, count=2)
			print(line)
			#print(type(array_tupple))
			length = len(array_tupple)
			#print(length)
			i = 0
			while i < length-1:
				print(array_tupple[i]+'\t',end='')
				file2.write(array_tupple[i] + "\t")
				i += 1
			print(array_tupple[i])
			file2.write(array_tupple[i] + "\n")
			file2.write(tupple[0][0])

		
