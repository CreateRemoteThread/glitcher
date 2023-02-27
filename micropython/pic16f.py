from machine import Pin
from rp2 import PIO,StateMachine,asm_pio
import time

# todo: vampire

# too slow idk
def gpiobang():
  ispclk = Pin(14,Pin.OUT)
  ispdat = Pin(15,Pin.OUT)
  ispclk.value(1)
  ispdat.value(1)
  for i in range(0,8):
    ispclk.value(1)
    ispdat.value(0)
    ispclk.value(0)

# set x at the start of the SM.
@asm_pio(out_init=[PIO.INPUT],sideset_init=[PIO.OUT_HIGH],out_shiftdir=PIO.SHIFT_RIGHT)
def clkbang():
  set(pindirs,1)
  pull()
  label("bitloop")
  nop().side(1)
  out(pins,1)
  nop().side(0)
  nop()
  jmp(x_dec,"bitloop")

def test():
  sm = StateMachine(0,clkbang,freq=1000000,out_base=Pin(14),sideset_base=Pin(15))
  sm.exec("set x, 7")  # BITS_OUT
  # sm.exec("set y, 23") # BITS_IN
  sm.active(1)
  sm.put(0xAA)
  time.sleep(5.0)
  # print(sm.get())
  sm.active(0)

print("use pic16f.test() to try it")
