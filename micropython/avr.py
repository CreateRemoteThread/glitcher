from machine import UART, SPI, Pin
import time

class AVRTarget:
    def __init__(self):
        self.u1 = UART(1,tx=Pin(4),rx=Pin(5),baudrate=9600)
        self.u1.read()
        print("Initialized AVR Target (Tx:4, Rx:5)")
        
    def fire(self):
        self.u1.write(b"e")
        time.sleep(0.1)
        return self.u1.read()

class AVRProgrammer:
    def __init__(self,pin_sck=6,pin_mosi=7,pin_miso=4,pin_cs=14):
        self.p1 = SPI(0,baudrate=1000000,polarity=1,phase=1,bits=8,firstbit=SPI.MSB,sck=Pin(pin_sck),mosi=Pin(pin_mosi),miso=Pin(pin_miso))
        self.cs = Pin(pin_cs,Pin.OUT)
        self.cs.value(1)
        print("Initialized AVR programmer (sck=%d,mosi=%d,miso=%d,cs=%d)" % (pin_sck,pin_mosi,pin_miso,pin_cs))

    def enterProgramming(self):
        dx = bytearray(4)
        self.cs.value(0)
        self.p1.write_readinto(b"\xAC\x53\x00\x00",dx)
        print(":".join([hex(x) for x in dx]))

    def chipErase(self):
        dx = bytearray(4)
        self.p1.write_readinto(b"\xAC\x80\x00\x00",dx)
        print(":".join([hex(x) for x in dx]))

    # see atmega328p datasheet, not avr isp datasheet.
    def setLockbits(self,lckbit=0xF0):
        dx = bytearray(4)
        self.p1.write_readinto(b"\xAC\xE0\x00" + bytes([lckbit]),dx)
        print(":".join([hex(x) for x in dx]))

    def writeMemory(self,page_msb=0x00,page_lsb=0x00):
        dx = bytearray(4)
        mempage = bytearray(128)
        for i in range(0,128):
            mempage[i] = i
        self.p1.write_readinto(bytes([0x4c,page_msb,page_lsb,0]))
        self.p1.write(mempage)

    def readMemory(self,addr_b1,addr_b2):
        dx = bytearray(4)
        self.p1.write_readinto(bytes([0x20,addr_b1,addr_b2,0x00]),dx)
        print(dx) 
        dx = bytearray(4)
        self.p1.write_readinto(bytes([0x28,addr_b1,addr_b2,0x00]),dx)
        print(dx) 

    def exitProgramming(self):
        self.cs.value(1)

