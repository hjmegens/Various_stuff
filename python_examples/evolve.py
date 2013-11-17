import matplotlib
matplotlib.use('Qt4Agg')
import matplotlib.pylab as plt
import numpy as np

import random
randdna=''
#for i in range(100000000):
#  randdna=randdna+'ACGT'[random.randint(0,3)]
def mutate(base,prob):
  a = random.random()
  if a > 1-prob:
    base = 'acgt'[random.randint(0,3)]
  return base

def mutate_gc(base,prob):
  a = random.random()
  if a > 1-prob:
    base = 'acgtacgtat'[random.randint(0,9)]
  return base

def mutated_string(dna):
  #rdl = list(dna)
  index=0
  for i in dna:
    dna[index]=(mutate_gc(i,0.01))
    index+=1
  return dna

def sample_seqs(dnalist,numseqs=100):
  keep=[]
  dnanewlist=[]
  numseqs=random.randint(50,100)
  for i in range(numseqs):
    keep.append(random.randint(0,len(dnalist)-1))
  for i in keep:
    dnanewlist.append(dnalist[i])
  return numseqs,dnanewlist

def gc_content(dna):
  dnastring=''.join(dna)
  g = dnastring.upper().count('G')
  c = dnastring.upper().count('C')
  gc = (g+c)/len(dnastring)
  return gc

randdna= ''.join(['ACGT'[random.randint(0,3)] for i in range(1000)])
#print(randdna)
randdna=list(randdna)
#for i in range(0,len(randdna),10):
#  randdna[i:i+3]=list('XYZ')
randdna=''.join(randdna)
#print('>gen1',randdna,sep="\n") # moet weer terug
mutstring=('00',list(randdna))
dnalist=[]
for i in range(0,99):
  #print(i)
  newstring=mutated_string(mutstring[1][:])
  #print('>gen'+str(i),''.join(newstring),sep='\n')
  dnalist.append((mutstring[0]+'{:02d}'.format(i),newstring[:]))

numseqs,dnalist=sample_seqs(dnalist)
for seq in dnalist:
  #print('>'+seq[0],''.join(seq[1]),sep='\n')
  pass

plt.ion()
plt.subplot(211)
plt.xlim(0,510)
plt.ylim(0.35,0.55)
x=[0]
y=[0.5]
y2=[0.5]
line, = plt.plot(np.array(x),np.array(y),label='plotname',linewidth=2)
plt.xlabel('generation')
plt.ylabel('GC content')
plt.title('Evolution of GC')
plt.subplot(212)
line2, = plt.plot(np.array(x),np.array(y2),label='plotname',linewidth=2)
plt.xlabel('generation')
plt.ylabel('size')
plt.title('pop size')
plt.xlim(0,100)
plt.ylim(0,110)
#plt.subplot(222)

for i in range(0,999):
  gc=0
  for j in range(0,len(dnalist)):
    dnalist[j]=(dnalist[j][0]+'{:02d}'.format(j),mutated_string(dnalist[j][1][:]))
    gc+=gc_content(dnalist[j][1])
  gccont=gc/len(dnalist)
  numseqs,dnalist = sample_seqs(dnalist)
  x.append(i)
  y.append(gccont)
  y2.append(numseqs)
  print(numseqs,gccont, sep='\t')
  line.set_xdata(np.array(x))
  line.set_ydata(np.array(y))
  line2.set_xdata(np.array(x))
  line2.set_ydata(np.array(y2))
  if (i>500):
    plt.subplot(211)
    plt.xlim(i-500,i+10)
  if (i>100):
    plt.subplot(212)
    plt.xlim(i-100,i+10)
  plt.draw()
  plt.pause(0.005)


for i in dnalist:
  #print('>'+i[0],''.join(i[1]),sep='\n')
  pass

