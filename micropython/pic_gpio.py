from machine import Pin
import glitcher
from time import sleep, sleep_ms, sleep_us, ticks_ms
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
    
    def erase(self,sm_trigger=True):
        self.command(0x16)
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
                print("Kick!")
                # print(sm)
                # sm.active(1)
                sm.active(0)
                sm.put(65000)  # x_delay
                sm.put(40000)     # y_pulselen
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
g.muxout(glitcher.SELECT_NONE)

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

def test2():
    # global sm
    # print("sm is live")
    # sm = StateMachine(0,simpleInverter,freq=10000000,set_base=Pin(INVERTER_OUT,Pin.OUT),pull_thresh=8)
    # sm.active(1)
    trig_pin = Pin(10,Pin.OUT,value=0)
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
    print("Locking...")
    prg.cfgLock()
    sleep(0.01)
    print("Reading while locked...")
    print(hex(prg.readFrom(0x400)))
    # g.muxout(glitcher.SELECT_MUXB)
    print("Unlock with write 0x3FFF")
    # prg.cfgLock(payload=0x180)
    prg.erase(sm_trigger=True)
    sleep(3.0)
    # sm.active(0)
    # GL_OUT.init(GL_OUT.OUT,value=0)
    # sleep(0.5)
    # g.muxout(glitcher.SELECT_NONE)sm
    prg.cfgRead()
    # for i in range(0,5):
    #     sleep(0.05)
    print(hex(prg.readFrom(0x400)))
    prg.exitPrg()


