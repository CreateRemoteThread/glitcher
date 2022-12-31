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
    output test_led,     // A17
    output rgb_led_r,
    output rgb_led_g,
    output rgb_led_b,
    input i_trig,
    output o_glitch,
    output o_m1,
    output o_n3,
    output o_p3,
    output o_auxout,
    output o_clkout
    );
    
    // sma's up top. auxout closest to FPGA.
    // assign o_auxout = 1;
    assign o_clkout = 1;
    
    // LEDs. 1 is "off".
    assign o_m1 = 1;
    assign o_n3 = 1;
    assign o_p3 = 1;
    
    /*
    signal_test sig1(
        .o_sig1(o_m1),
        .o_sig2(o_n3),
        .o_sig3(o_p3),
        .clk(w_uartclk)
    );
    */
    
    // output_mux can glitch ALL the max4619 ports.
    wire [7:0] w_output_mux;
    wire [7:0] w_force_output;
    
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
    
    // this is active high, i checked the xilinx ip picture thingy
    assign w_reset = 0;

    design_1_wrapper test_clkwiz(.clk_out_100mhz(w_sysclk),
                            .clk_out_10mhz(w_uartclk),
                            .locked_0(w_clk_locked),
                            .reset(w_reset),
                            .sys_clock(i_sysclk));

    // both of these run off 10mhz
    uart_rx m_uart_rx(w_uartclk,i_uart_rx,w_rx_dv,rx_reg);
    uart_tx m_uart_tx(w_uartclk,w_tx_dv,tx_reg,w_tx_active,o_uart_tx,w_tx_done);
    
    reg r_dummy;
    wire w_glitch;
    
    assign o_glitch =    (w_glitch & w_output_mux[0]) | w_force_output[0];
    assign o_max4619_a = (w_glitch & w_output_mux[1]) | w_force_output[1];
    assign o_max4619_b = (w_glitch & w_output_mux[2]) | w_force_output[2];
    assign o_max4619_c = (w_glitch & w_output_mux[3]) | w_force_output[3];
    assign o_auxout =    (w_glitch & w_output_mux[4]) | w_force_output[4];
   

    wire w_rgbled_r;
    wire w_rgbled_g;
    wire w_rgbled_b;
    
    command cmd0(.clk(w_uartclk),
                 .sysclk(w_sysclk),
                 .rx_strobe(w_rx_dv),
                 .rx_byte(rx_reg),
                 .tx_done(w_tx_done),
                 .tx_strobe(w_tx_dv),
                 .wr_byte(tx_reg),
                 .i_trig(i_trig),
                 .o_glitch(w_glitch),
                 .o_force_output(w_force_output),
                 .o_output_mux(w_output_mux),
                 .o_arm_led(w_rgbled_r),
                 .o_waiting_led(w_rgbled_g),
                 .o_firing_led(w_rgbled_b),
                 .o_test_led(test_led)
                 );
                 
    pwm pwm0(.clk(w_uartclk),
             .enable(w_rgbled_r),
             .duty(4'b1110),
             .pwm_out(rgb_led_r)
             );
             
    pwm pwm1(.clk(w_uartclk),
             .enable(w_rgbled_g),
             .duty(4'b1110),
             .pwm_out(rgb_led_g)
             );
             
    pwm pwm2(.clk(w_uartclk),
             .enable(w_rgbled_b),
             .duty(4'b1110),
             .pwm_out(rgb_led_b)
             );
endmodule
