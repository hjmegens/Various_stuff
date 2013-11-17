import sys
import random
import time
import matplotlib.pyplot as pyplot
import numpy as np

teller = 1
resultaten = []
while teller < 11:
   teller += 1
   getal1 = random.randint(1,10)
   getal2 = random.randint(1,10)
   som = getal1 * getal2

   print(str(getal1)+' x '+str(getal2)+' = ')
   start = time.time()

   getal = sys.stdin.readline().rstrip()
   print('jouw antwoord was '+str(getal))

   if int(getal) == som:
      print('het antwoord is goed!')
   else:
      print ('helaas, het antwoord is fout!'+"\n"+'Het antwoord moest zijn '+str(som))

   end = time.time()
   print(end - start)
   tijd = end-start
   resultaten.append([som,tijd])

resultaten_matrix=np.matrix(resultaten)
print(resultaten_matrix)
pyplot.plot(resultaten_matrix[:,0],resultaten_matrix[:,1])
