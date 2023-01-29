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
    def __init__(self,pin_sck=6,pin_mosi=7,pin_miso=4,pin_cs=14,pin_trig=15):
        self.pin_sck = pin_sck
        self.pin_mosi = pin_mosi
        self.pin_miso = pin_miso
        self.pin_cs = pin_cs
        self.pin_trig = pin_trig
        print("Created AVRProgrammer object. Use enterProgramming to begin")
        pass

    def enterProgramming(self):
        self.p1 = SPI(0,baudrate=1000000,polarity=1,phase=1,bits=8,firstbit=SPI.MSB,sck=Pin(self.pin_sck),mosi=Pin(self.pin_mosi),miso=Pin(self.pin_miso))
        self.cs = Pin(self.pin_cs,Pin.OUT)
        self.cs.value(1)
        self.trig = Pin(self.pin_trig,Pin.OUT)
        self.trig.value(0)
        print("Initialized AVR programmer (sck=%d,mosi=%d,miso=%d,cs=%d)" % (self.pin_sck,self.pin_mosi,self.pin_miso,self.pin_cs))
        dx = bytearray(4)
        self.cs.value(0)
        self.p1.write_readinto(b"\xAC\x53\x00\x00",dx)
        print(":".join([hex(x) for x in dx]))

    def fillMemory(self):
        for faddr_high in range(0,0xFF):
            for faddr_low in range(0,0xFF):
                self.writeMemory(addr_low=faddr_low,addr_high=faddr_high,data_low=0x12,data_high=0x34)

    def writeMemory(self,addr_low=0x00,addr_high=0x00,data_low=0x00,data_high=0x00):
        self.p1.write(bytes([0x40,addr_high,addr_low,data_low]))
        self.p1.write(bytes([0x48,addr_high,addr_low,data_high]))
        self.p1.write(bytes([0x4C,addr_high,addr_low,0x00]))

    def chipErase(self):
        dx = bytearray(4)
        self.trig.value(1)
        self.p1.write_readinto(b"\xAC\x80\x00\x00",dx)
        self.trig.value(0)
        print(":".join([hex(x) for x in dx]))

    # see atmega328p datasheet, not avr isp datasheet.
    def setLockbits(self,lckbit=0xF0):
        dx = bytearray(4)
        self.p1.write_readinto(b"\xAC\xE0\x00" + bytes([lckbit]),dx)
        print(":".join([hex(x) for x in dx]))

    def readMemory(self,addr_b1,addr_b2):
        dx = bytearray(4)
        self.p1.write_readinto(bytes([0x20,addr_b1,addr_b2,0x00]),dx)
        print(":".join([hex(x) for x in dx]))
        dx = bytearray(4)
        self.p1.write_readinto(bytes([0x28,addr_b1,addr_b2,0x00]),dx)
        print(":".join([hex(x) for x in dx]))

    def exitProgramming(self):
        self.cs.value(1)
