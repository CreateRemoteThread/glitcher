`timescale 1ns / 1ps

/*
because idk how to use vivado: cmod a7-35t uses mx25l3273f
*/

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
    output o_clkout,
    input i_wforce
    );
    
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
    
    wire w_clk_40mhz;

    // clock wizard (10,100,40mhz outputs)
    assign w_reset = 0;
    design_1_wrapper test_clkwiz(.clk_out_100mhz(w_sysclk),
                            .clk_out_10mhz(w_uartclk),
                            .clk_out_40mhz(w_clk_40mhz),
                            .locked_0(w_clk_locked),
                            .sys_clock(i_sysclk));

    // UART, off the 10mhz clock.
    uart_rx m_uart_rx(w_uartclk,i_uart_rx,w_rx_dv,rx_reg);
    uart_tx m_uart_tx(w_uartclk,w_tx_dv,tx_reg,w_tx_active,o_uart_tx,w_tx_done);
    
    reg r_dummy;
    wire w_glitch;
    wire w_glitch_real = w_glitch | i_wforce;
    
    // low speed clock generator + glitcher
    wire [31:0] w_clk_ctrl;
    wire w_clkglitch;
    arbclk(.reset(w_reset),
           .clkin(w_clk_40mhz),
           .clkout(o_clkout),
           .ctrl(w_clk_ctrl),
           .clkin_100mhz(w_sysclk),
           .glitch_in(w_clkglitch)
           );

    assign o_glitch =    (w_glitch_real & w_output_mux[0]) | w_force_output[0];
    assign o_max4619_a = (w_glitch_real & w_output_mux[1]) | w_force_output[1];
    assign o_max4619_b = (w_glitch_real & w_output_mux[2]) | w_force_output[2];
    assign o_max4619_c = (w_glitch_real & w_output_mux[3]) | w_force_output[3];
    assign o_auxout =    (w_glitch_real & w_output_mux[4]) | w_force_output[4];
    assign w_clkglitch = (w_glitch_real & w_output_mux[5]) | w_force_output[5];

    wire w_rgbled_r;
    wire w_rgbled_g;
    wire w_rgbled_b;
    
    /*
    command processor
    */
    command cmd0(.clk(w_uartclk),
                 .sysclk(w_sysclk),
                 .rx_strobe(w_rx_dv),
                 .rx_byte(rx_reg),
                 .tx_done(w_tx_done),
                 .tx_strobe(w_tx_dv),
                 .wr_byte(tx_reg),
                 .i_trig_orig(i_trig),
                 .o_glitch(w_glitch),
                 .o_force_output(w_force_output),
                 .o_output_mux(w_output_mux),
                 .o_arm_led(w_rgbled_r),
                 .o_waiting_led(w_rgbled_g),
                 .o_firing_led(w_rgbled_b),
                 .o_test_led(test_led),
                 .o_clk_ctrl(w_clk_ctrl)
                 );
                 
    /*
    light control
    */
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
