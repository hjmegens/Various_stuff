from decimal import *
D=Decimal
getcontext().prec=100000
p=sum(D(1)/16**k*(D(4)/(8*k+1)-D(2)/(8*k+4)-D(1)/(8*k+5)-D(1)/(8*k+6))for k in range(411))
print(str(p)[:100002])
