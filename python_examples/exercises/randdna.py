import random
randdna=''
#for i in range(100000000):
#  randdna=randdna+'ACGT'[random.randint(0,3)]

randdna= ''.join(['ACGT'[random.randint(0,3)] for i in range(10000000)])
#print(randdna)
randdna=list(randdna)
for i in range(0,len(randdna),10):
  randdna[i:i+3]=list('XYZ')
randdna=''.join(randdna)
#print(randdna)
print(randdna.count('X'))
