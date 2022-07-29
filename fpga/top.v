`timescale 1ns / 1ps

module top(
    input i_sysclk,
    input i_uart_rx,
    output o_uart_tx,
    input i_fpga3,
    input i_fpga4,
    output o_max4619_a,
    output o_max4619_b,
    output o_max4619_c,
    output o_k3,
    output test_led,     // A17
    output rgb_led_r,
    output rgb_led_g,
    output rgb_led_b,
    input i_trig,
    output o_glitch
    );
    
    assign rgb_led_r = 1'b1;
    assign rgb_led_g = 1'b1;
    assign rgb_led_b = 1'b1;
    
    wire [7:0] rx_reg;
    wire [7:0] tx_reg;
    wire w_rx_dv;
    wire w_tx_dv;
    wire w_tx_active;
    wire w_tx_done;
    
    reg [32:0] ctr;
    reg blink_status;
    
    wire w_sysclk;
    wire w_uartclk;
    wire w_clk_locked;
    wire w_reset;

    design_1_wrapper test_clkwiz(.clk_out_100mhz(w_sysclk),
                            .clk_out_10mhz(w_uartclk),
                            .locked_0(w_clk_locked),
                            .reset(w_reset),
                            .sys_clock(i_sysclk));

    // both of these run off 10mhz
    uart_rx m_uart_rx(w_uartclk,i_uart_rx,w_rx_dv,rx_reg);
    uart_tx m_uart_tx(w_uartclk,w_tx_dv,tx_reg,w_tx_active,o_uart_tx,w_tx_done);
    
    reg r_dummy;
    assign o_glitch = w_glitch;
    
    wire w_glitch;
    
    command cmd0(.clk(w_uartclk),
                 .sysclk(w_sysclk),
                 .rx_strobe(w_rx_dv),
                 .rx_byte(rx_reg),
                 .tx_done(w_tx_done),
                 .tx_strobe(w_tx_dv),
                 .wr_byte(tx_reg),
                 .w_test_led(test_led),
                 .i_trig(i_trig),
                 .o_glitch(w_glitch)
                 );

endmodule
