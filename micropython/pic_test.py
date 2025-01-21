from machine import Pin, UART
import glitcher
from time import sleep, sleep_ms, sleep_us, ticks_ms
import random
from rp2 import PIO,StateMachine,asm_pio

# REMEMBER TO SET BOREN TO OFF
# uart glitch characterisation test
# banana firwmare

INVERTER_IN = 6
INVERTER_OUT = 12

# simpleInverter: x is the delay, y is pulse duration
@asm_pio(set_init=[PIO.OUT_LOW])
def simpleInverter():
    wait(0,pin,0)
    wrap_target()
    pull()
    mov(x,osr)
    pull()
    mov(y,osr)
    wait(1,pin,0)
    label("loop_wait")
    jmp(x_dec,"loop_wait")
    set(pins,1)
    label("loop_pulse")
    jmp(y_dec,"loop_pulse")
    set(pins,0)
    wrap()

DELAY_X = 30
PULSE_Y = 15

pin_in = Pin(INVERTER_IN, Pin.IN)
pin_set = Pin(INVERTER_OUT)
sm = StateMachine(0,simpleInverter,freq=80000000,in_base=pin_in, set_base=pin_set,pull_thresh=32)

g = glitcher.Glitcher()
g.enablemux(True)
g.setmask(glitcher.SELECT_MUXA | glitcher.SELECT_MUXB)

def oneTest(delay,pulse):
    sm.active(0)
    sm.put(delay)  # x_delay
    sm.put(pulse)     # y_pulselen
    sm.active(1)

def fuzzLoop():
    u1 = UART(1,tx=Pin(4),rx=Pin(5),baudrate=9600)
    print(u1.read())
    results = []
    for i in range(0,500):
        fuzzptr = random.randint(1000,10000)
        pulselen = random.randint(25,40 * 2)
        oneTest(fuzzptr,pulselen)
        u1.write(b"e")
        print("ptr %d len %d" % (fuzzptr,pulselen))
        sleep(3.0)
        d = u1.read()
        if d != b'banana 6250\r\n' and d != b'banana 6250\r\n\n'  and b'restart' not in d:
            print("WIN")
            results.append( (fuzzptr,pulselen,d) )
        print(d)
    if len(results) == 0:
        print("No wins, bad luck :(")
    for (fp,pl,data) in results:
        print(b"position %d, pulse %d, result %s" % (fp,pl,data))


