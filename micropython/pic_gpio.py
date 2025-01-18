from machine import Pin
import glitcher
from time import sleep, sleep_ms, sleep_us, ticks_ms
import random
from rp2 import PIO,StateMachine,asm_pio

# pio method turned out to be a huge fuckaround, so using this instead:
# https://github.com/SyedTahmidMahbub/q-dpico_picprog72/blob/main/prog72.py
# This is for pic16f1788 with the mchp key and xbit, check before you re-use

MCLR_PIN = 13
PGD_PIN  = 14
PGC_PIN  = 15

INVERTER_IN = 6
INVERTER_OUT = 12

# simpleInverter: x is the delay, y is pulse duration
@asm_pio(set_init=[PIO.OUT_LOW])
def simpleInverter():
    wrap_target()
    pull()
    mov(x,osr)
    pull()
    mov(y,osr)
    wait(0,pin,0)
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
sm = StateMachine(0,simpleInverter,freq=40000000,in_base=pin_in, set_base=pin_set,pull_thresh=32)

# sm.active(1)

@micropython.asm_thumb
def tsethold():
    nop()
    nop()
    nop()
    nop()
    nop()
    nop()
    nop()
    nop()
    nop()
    nop()
    nop()
    nop()
    nop()

class PICProgrammer:
    def __init__(self):
        self.PGD = Pin(PGD_PIN, Pin.IN)
        self.PGC = Pin(PGC_PIN, Pin.IN)
        self.MCLR = Pin(MCLR_PIN, Pin.OUT, value=1)

    def enterPrg(self):
        self.MCLR.value(0)
        self.PGD.init(self.PGD.OUT,value=0)
        self.PGC.init(self.PGC.OUT,value=0)
        sleep_us(1)
    def exitPrg(self):
        self.PGD.init(self.PGD.IN)
        self.PGC.init(self.PGC.IN)
        self.MCLR.value(1)
    
    def erase(self,addr=None,sm_trigger=True):
        if addr is None:
            self.command(0x00)
            self.write_data(0x3FFF)
        else:
            self.command(0x16)
            for i in range(0,addr):
                self.command(0x06)
                sleep_us(5)
            # self.write_data(0x3FFF)
        self.command(0x09,sm_trigger=sm_trigger)
    
    def cfgRead(self):
        self.command(0x00)
        self.write_data(0x0004)
        for i in range(0,7):
            self.command(0x06)
        self.command(0x04)
        print("cfg read")
        print(hex(self.read_data()))
    
    def cfgLock(self,payload=None):
        self.command(0x00)
        if payload is None:
            self.write_data(0x0004)
        else:
            self.write_data(payload)
        for i in range(0,7):
            self.command(0x06)
        self.command(0x08)

    def cfgUnlock(self):
        self.command(0x00)
        self.write_data(0x0180)
        for i in range(0,7):
            self.command(0x06)
        self.command(0x08)
          
    def xbit(self):
        self.PGC.value(1)
        self.PGD.value(0)
        tsethold()
        self.PGC.value(0)
        tsethold()
        
    def sendKey(self):
        out_stream = ""
        ICSP_STARTUP_KEY = [0b1001101,0b1000011,0b1001000,0b1010000]
        for x in range(3,-1,-1):
            key_byte = ICSP_STARTUP_KEY[x]
            for y in range(0,8):
                self.PGC.value(1)
                b = (key_byte >> y) & 1
                self.PGD.value(b)
                tsethold()
                self.PGC.value(0)
                tsethold()
        self.xbit()

    def setParams(self,delay=65700,pulse=4000):
        self.delay = delay
        self.pulse = pulse

    def command(self,x,sm_trigger=False):
        global sm
        x = x & 0x3f
        out_str = ""
        for _ in range(6):
            b = x & 1
            x = x >> 1
            self.PGC.value(1)
            self.PGD.value(b)
            tsethold()
            if _ == 5 and sm_trigger is True:
                # print("Kick!")
                # print(sm)
                # sm.active(1)
                sm.active(0)
                sm.put(self.delay)  # x_delay
                sm.put(self.pulse)     # y_pulselen
                sm.active(1)
                # sleep_us(50)
            self.PGC.value(0)
            tsethold()
        sleep_us(1)
        
    def writeTo(self,addr,data):
        self.command(0x16)
        for i in range(0,addr):
            self.command(0x06)
            sleep_us(5)
        self.command(0x02)
        self.write_data(data)
        sleep_us(20)
        self.command(0x08)
        sleep_ms(5)
        
    def failureCheck(self,addrStart,addrEnd):
        self.command(0x16)
        for i in range(0,addrStart):
            self.command(0x06)
            sleep_us(5)
        x = addrStart
        blabla = False
        while x < addrEnd:
            self.command(0x04)
            d = self.read_data()
            if d != 0 and d != 0x3FFF:
                print("ADDR 0x%04x DATA 0x%04x" % (x,d))
                blabla = True
            x += 1
            self.command(0x06)
            sleep_us(5)
        return blabla
    
    def readFrom(self,addr):
        self.command(0x16)
        for i in range(0,addr):
            self.command(0x06)
            sleep_us(5)
        self.command(0x04)
        return self.read_data()
    
    def write_data(self,x):
        x = (x & 0x3fff) << 1
        for i in range(16):
            b = x & 1
            x = x >> 1
            self.PGC.value(1)
            self.PGD.value(b)
            tsethold()
            self.PGC.value(0)
            tsethold()

    def read_data(self):
        x = 0
        self.PGD.init(self.PGD.IN,Pin.PULL_DOWN)
        for _ in range(16):
            self.PGC.value(1)
            tsethold()
            self.PGC.value(0)
            b = self.PGD.value()
            tsethold()
            x = x >> 1 | (b << 15)
        self.PGD.init(self.PGD.OUT)
        return x >> 1

g = glitcher.Glitcher()
g.enablemux(True)
g.setmask(glitcher.SELECT_MUXB)
# g.muxout(glitcher.SELECT_NONE)

def test():
    addr = 0x120
    prg = PICProgrammer()
    prg.enterPrg()
    prg.sendKey()
    prg.command(0x00)
    prg.write_data(0x3FFF)
    for i in range(0,6):
        prg.command(0x06)
    prg.command(0x04)
    print("ChipID")
    print(hex(prg.read_data()))
    prg.writeTo(0x0400,0x4444)
    print(hex(prg.readFrom(0x400)))
    print(hex(prg.readFrom(0x400)))
    prg.exitPrg()

def fuzztest(fixed_delay = None):
    prg = PICProgrammer()
    prg.enterPrg()
    prg.sendKey()
    prg.command(0x00)
    prg.write_data(0x3FFF)
    for i in range(0,6):
        prg.command(0x06)
    prg.command(0x04)
    cid = prg.read_data()
    if cid != 0x302b:
        print("Target burnt, chipid failed")
        return None
    prg.writeTo(0x0400,0x4444)   # Prep target data
    prg.writeTo(0x0800,0x4444)
    data = prg.readFrom(0x400)
    if data != 0x444:
        r_delay = 67100
    else:
        if fixed_delay is None:
            r_delay = random.randint(66000,67100)
        else:
            r_delay = fixed_delay
    prg.cfgLock()
    sleep(0.01)
    prg.cfgUnlock()
    sleep(1.0)
    if fixed_delay == 67100:
        r_pulse = 1
    else:
        r_pulse = random.randint(35,85)
    # print("R_DELAY = %d, R_PULSE = %d" % (r_delay,r_pulse))
    prg.setParams(delay=r_delay,pulse=r_pulse)
    prg.erase(addr=0x500,sm_trigger=True)
    sleep(1.0)
    www = prg.failureCheck(0x200,0x1000)
    data1 = prg.readFrom(0x400)
    data2 = prg.readFrom(0x800)
    prg.exitPrg()
    return (r_delay,r_pulse,data1,data2,www)

def fuzzloop():
    for f_delay in range(63000,64000,15):
        x = fuzztest(fixed_delay=f_delay)
        if x is None:
            print("Chip burned")
            return
        else:
            (r_delay,r_pulse,data1,data2,www) = x
            print("Attempt %d, Delay: %d, Pulse: %d, Fetch1: 0x%04x, Fetch2: 0x%04x" % (f_delay,r_delay,r_pulse,data1,data2))
            if (data1 != 0 and data1 != 0x3FFF) or (data2 != 0 and data2 != 0x3FFF):
                print("Win")
                # return
            elif www:
                print("win")
                # return
            elif data1 != data2:
                print("Kinda win")
            if data1 == 0 and data2 == 0:
                fuzztest(fixed_delay=67100)

def test2():
    prg = PICProgrammer()
    prg.enterPrg()
    prg.sendKey()
    prg.command(0x00)
    prg.write_data(0x3FFF)
    for i in range(0,6):
        prg.command(0x06)
    prg.command(0x04)
    print("ChipID")
    print(hex(prg.read_data()))
    prg.writeTo(0x0400,0x4444)
    prg.writeTo(0x0800,0x4444)
    # prg.writeTo(0x1400,0x4444)
    print(hex(prg.readFrom(0x400)))
    print("Locking...")
    prg.cfgLock()
    sleep(0.01)
    print("Reading while locked...")
    print(hex(prg.readFrom(0x400)))
    # g.muxout(glitcher.SELECT_MUXB)
    print("Unlock with write 0x3FFF")
    prg.cfgUnlock()
    sleep(1.0)
    # 15000 for read / prep stage?
    # 62000 for flash access
    # random.randint(60900,61100) for flash init.
    r_delay = random.randint(66000,67100)
    r_pulse = random.randint(35,55)
    print("R_DELAY = %d, R_PULSE = %d" % (r_delay,r_pulse))
    prg.setParams(delay=r_delay,pulse=r_pulse)
    prg.erase(addr=0x500,sm_trigger=True)
    sleep(1.0)
    print(hex(prg.readFrom(0x400)))
    print(hex(prg.readFrom(0x800)))
    prg.exitPrg()


