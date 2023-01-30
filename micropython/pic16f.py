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

@asm_pio(out_init=[PIO.OUT_HIGH],sideset_init=[PIO.OUT_HIGH],out_shiftdir=PIO.SHIFT_RIGHT)
def clkbang():
  pull()
  set(x,7)
  label("bitloop")
  nop().side(1)
  out(pins,1)
  nop().side(0)
  nop()
  jmp(x_dec,"bitloop")
  set(x,7)
  # sideset(pindirs,0)
  label("readloop")
  nop().side(1)
  # in(pins,1)
  nop().side(0)
  nop()
  jmp(x_dec,"readloop") 
  nop()

def test():
  sm = StateMachine(0,clkbang,freq=1000000,out_base=Pin(14),sideset_base=Pin(15))
  sm.active(1)
  sm.put(0xAA)
  time.sleep(5.0)
  sm.active(0)

print("use pic16f.test() to try it")
