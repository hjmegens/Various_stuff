import matplotlib
matplotlib.use('Qt4Agg')
import matplotlib.pylab as plt
#from pylab import *
import numpy as np
import time
plt.ion()
plt.xlim(-1,8)
plt.ylim(-1.5,1.5)
txstart=time.time()
x=np.arange(0,2*np.pi,0.01)
line, = plt.plot(x,np.sin(x))
for i in np.arange(1,200):
    line.set_ydata(np.sin(x+i/10.0))
    plt.draw()
    plt.pause(0.005)
