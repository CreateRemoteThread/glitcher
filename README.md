# glitcher

![Glitcher Schematic](glitcher_kicad.png)

## Introduction

Glitcher is a homebrew fault injection system, built around a Pi Pico and CMOD A7, with a MAX4619 and an irf7807 providing multiplexer and crowbar mosfet style glitching respectively. Generous GPIO (FPGA + Pi Pico) + SMA outputs are available.

This project is heavily inspired by the ChipWhisperer set of products.

## Use

The Pi Pico is the simplest method of using this. Using a micro USB cable, access the MicroPython interface and use the glitcher library to control the FPGA's default firmware:

```
import glitcher

g = glitcher.Glitcher()
g.enablemux(True)                # enable max4619. crowbar always "on"
g.setmask(glitcher.SELECT_MOSFET)         # select mosfet for glitching
g.muxout(glitcher.SELECT_MUXA)            # switch x_out to x1
g.muxout(glitcher.SELECT_NONE)            # switch x_out to x0
g.rnr(delay=5,width=5)           # write delay/width, glitch output according to setmask
```

The Pi Pico uses only a serial port to talk to the FPGA at 9600bps, so you can swap it for some other uC / make a shield / whatever. Just replace self.u1 with a pyserial output if you want to use a control PC (enablemux is the only thing requiring the pi pico, just hardwire it idk).

Probably don't use g.muxout(0xF) - but do whatever you want.