import sys
import random
import time
import matplotlib.pyplot as pyplot
import numpy as np
aantalsommen=int(sys.argv[1])
teller = 1
resultaten = []
starttot = time.time()
aantalgoed=0
sys.stderr.write("\x1b[2J\x1b[H")
while teller < aantalsommen+1:
   print('\n')
   sys.stderr.flush()
   uitkomst="goed"
   teller += 1
   getal1 = random.randint(1,10)
   getal2 = random.randint(1,10)
   som = getal1 * getal2
   somstring=str(getal1)+' x '+str(getal2)+' = '
   sys.stdout.write(somstring)
   sys.stdout.flush()
   start = time.time()

   getal = int(sys.stdin.readline().rstrip())
   print('jouw antwoord was '+str(getal))

   if getal == som:
      print('het antwoord is goed!')
      aantalgoed+=1
   else:
      print ('helaas, het antwoord is fout!'+"\n"+'Het antwoord moest zijn '+str(som))
      uitkomst='fout'

   end = time.time()
   print("Over deze som heb je {:3.2f} seconden gedaan.".format(end - start))
   tijd = end-start

   resultaten.append([somstring,som,getal,tijd,uitkomst])

print('\n------------------------\n')
endtot = time.time()
tijdtot = endtot-starttot
#resultaten_matrix=np.matrix(resultaten)
print("Tijd in totaal: {:3.2f} seconden".format(tijdtot))
procentgoed=(aantalgoed/aantalsommen)*100
print("% goed: {:3.2f}".format(procentgoed))
for resultaat in resultaten:
   print('{:>10} {:3d}, jouw antwoord {:3d} in {:3.2f} seconden was {:5}'.format(*resultaat))
#print(resultaten_matrix)
#pyplot.plot(resultaten_matrix[:,0],resultaten_matrix[:,1])
