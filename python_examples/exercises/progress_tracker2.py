from progressbar import *               # just a simple progress bar
from time import *

widgets = ['Test: ', Percentage(), ' ', Bar(marker='-',left='[',right=']'),
           ' ', ETA(), ' ', FileTransferSpeed()] #see docs for other options

pbar = ProgressBar(widgets=widgets, maxval=500)
pbar.start()

for i in range(1,500+1,1):
    # here do something long at each iteration
    sleep(0.1)
    pbar.update(i) #this adds a little symbol at each iteration
pbar.finish()
print
