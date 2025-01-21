# Notes

Glitcher is primarily used via the MicroPython interface on the Raspberry Pi Pico. This allows for a number of things to be initialized without 

## AVR Glitcher

```import glitcher
import avr
import time

a = avr.AVRTarget()
g = glitcher.Glitcher()
g.setmask(glitcher.SELECT_MOSFET)
g.enablemux(1)
resetter = Pin(6,Pin.OUT)
resetter.value(1)

for i in range(110,130):
    if i % 5 == 0:
        print(i)
    for x in range(1,5):
        de = i
        g.setrepeat(num=2,delay=9)
        g.rnr(delay=de,width=7)
        f = a.fire()
        if f != b'62500\r\n':
            print("%d:%s" % (de,f))
            resetter.value(0)
            time.sleep(0.5)
            resetter.value(1)
            time.sleep(0.1)
            a.u1.read()
        time.sleep(0.2)```

