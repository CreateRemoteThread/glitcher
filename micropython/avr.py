from machine import UART, Pin
import time

class AVRTarget:
    def __init__(self):
        self.u1 = UART(1,tx=Pin(4),rx=Pin(5))
        self.u1.read()
        print("Initialized AVR Target (Tx:4, Rx:5)")
        
    def fire(self):
        self.u1.write(b"e")
        time.sleep(0.1)
        return self.u1.read()
