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
    output test_led     // A17
    );
    
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
    
    command cmd0(.clk(w_uartclk),
                 .rx_strobe(w_rx_dv),
                 .rx_byte(rx_reg),
                 .tx_done(w_tx_done),
                 .tx_strobe(w_tx_dv),
                 .wr_byte(tx_reg),
                 .w_test_led(test_led)
                 );
    
    /*
    assign o_k3 = blink_status;
    
    always @(posedge w_sysclk) begin
        if (ctr == 0'h00010000) begin
        blink_status <= 1 - blink_status;
            ctr <= 0'h00000000;
        end else begin
            ctr <= ctr + 1;
        end
    end
    */
    
endmodule
