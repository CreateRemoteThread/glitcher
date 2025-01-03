from machine import Pin
from time import sleep, sleep_ms, sleep_us, ticks_ms

# pio method turned out to be a huge fuckaround, so using this instead:
# https://github.com/SyedTahmidMahbub/q-dpico_picprog72/blob/main/prog72.py

MCLR_PIN = 13
PGD_PIN  = 14
PGC_PIN  = 15

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
            # print(x)
            key_byte = ICSP_STARTUP_KEY[x]
            for y in range(0,8):
                self.PGC.value(1)
                b = (key_byte >> y) & 1
                # if b == 1:
                #     out_stream += "1"
                # else:
                #     out_stream += "0"
                self.PGD.value(b)
                tsethold()
                self.PGC.value(0)
                tsethold()
        self.xbit()
        # print(out_stream)

    def command(self,x):
        x = x & 0x3f
        out_str = ""
        for _ in range(6):
            b = x & 1
            x = x >> 1
            self.PGC.value(1)
            self.PGD.value(b)
            tsethold()
            self.PGC.value(0)
            tsethold()
        # self.xbit()
        sleep_us(1)
        
    def write_data(self,x):
        # self.xbit()
        x = (x & 0x3fff) << 1
        for i in range(16):
            b = x & 1
            x = x >> 1
            self.PGC.value(1)
            self.PGD.value(b)
            tsethold()
            self.PGC.value(0)
            tsethold()
        # self.xbit()

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
        # self.xbit()
        return x >> 1

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
    print("ChipID again")
    sleep_ms(5)
    prg.command(0x06)
    prg.command(0x04)
    print(hex(prg.read_data()))
    # prg.write_data(0xffff)
    # for i in range(0,7):
    #     prg.command(0x06)
    # prg.command(0x04)
    # print("ChipID")
    # print(hex(prg.read_data()))
    prg.exitPrg()
    
    

