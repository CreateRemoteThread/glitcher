# set_property PACKAGE_PIN C15 [get_ports i_uart_rx]
# set_property PACKAGE_PIN H1 [get_ports o_uart_tx]

set_property PACKAGE_PIN R3 [get_ports i_uart_rx]
set_property PACKAGE_PIN T3 [get_ports o_uart_tx]
set_property PACKAGE_PIN A16 [get_ports o_max4619_a]
set_property PACKAGE_PIN L3 [get_ports o_max4619_b]
set_property PACKAGE_PIN M3 [get_ports o_max4619_c]

# set_property PACKAGE_PIN B15 [get_ports o_glitch]
set_property PACKAGE_PIN U8 [get_ports o_glitch]
# set_property PACKAGE_PIN K3 [get_ports i_trig]
set_property PACKAGE_PIN V8 [get_ports i_trig]


set_property PACKAGE_PIN C17 [get_ports rgb_led_r]
set_property PACKAGE_PIN B16 [get_ports rgb_led_g]
set_property PACKAGE_PIN B17 [get_ports rgb_led_b]

set_property PACKAGE_PIN R2 [get_ports i_fpga3]
set_property PACKAGE_PIN T1 [get_ports i_fpga4]
set_property IOSTANDARD LVCMOS33 [get_ports i_fpga3]
set_property IOSTANDARD LVCMOS33 [get_ports i_fpga4]
set_property IOSTANDARD LVCMOS33 [get_ports i_uart_rx]

set_property IOSTANDARD LVCMOS33 [get_ports o_glitch]
set_property IOSTANDARD LVCMOS33 [get_ports i_trig]

set_property IOSTANDARD LVCMOS33 [get_ports rgb_led_r]
set_property IOSTANDARD LVCMOS33 [get_ports rgb_led_g]
set_property IOSTANDARD LVCMOS33 [get_ports rgb_led_b]

set_property IOSTANDARD LVCMOS33 [get_ports o_max4619_a]
set_property IOSTANDARD LVCMOS33 [get_ports o_max4619_b]
set_property IOSTANDARD LVCMOS33 [get_ports o_max4619_c]
set_property IOSTANDARD LVCMOS33 [get_ports o_uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports test_led]

set_property PACKAGE_PIN A17 [get_ports test_led]

set_property SLEW FAST [get_ports o_glitch]
set_property DRIVE 12 [get_ports o_glitch]


set_property PACKAGE_PIN N3 [get_ports o_n3]
set_property PACKAGE_PIN P3 [get_ports o_p3]
set_property PACKAGE_PIN M1 [get_ports o_m1]
set_property IOSTANDARD LVCMOS33 [get_ports o_m1]
set_property IOSTANDARD LVCMOS33 [get_ports o_n3]
set_property IOSTANDARD LVCMOS33 [get_ports o_p3]

set_property PACKAGE_PIN P1 [get_ports o_auxout]
set_property PACKAGE_PIN N2 [get_ports o_clkout]
set_property IOSTANDARD LVCMOS33 [get_ports o_auxout]
set_property IOSTANDARD LVCMOS33 [get_ports o_clkout]

