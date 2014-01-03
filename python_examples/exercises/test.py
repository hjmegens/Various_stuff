import sys

mystring = '1234'
for i in mystring:
   print('letter: '+i+'\n',end='')

mylist = [int(l)+int(l) for l in mystring[:-1]]
print(mylist)
mylist2 = list(mystring)
print(mylist2)
