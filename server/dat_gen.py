#!/usr/bin/python

for i in xrange(1, 32):
    if len(str(i)) == 1:
        dt = "0{i}".format(i=i)
    else:
        dt = i
    print "2017-01-{dt}".format(dt=dt)
