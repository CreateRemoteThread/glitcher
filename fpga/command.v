module command(
    input clk,
    input sysclk,
    input rx_strobe,
    input [7:0] rx_byte,
    input tx_done,
    output tx_strobe,
    output [7:0] wr_byte,
    output o_test_led,
    input i_trig_orig,
    output o_glitch,
    output [7:0] o_output_mux,
    output [7:0] o_force_output,
    output o_arm_led,
    output o_waiting_led,
    output o_firing_led
);

    // use this to force an hard-force an output (i.e. power on-off).
    reg [7:0] r_force_output = 0;
    assign o_force_output = r_force_output;
    
    // wire w_test_led; // suppress errors, idk fix this later.
    reg [7:0] r_output_mux = 0;

    assign o_output_mux = r_output_mux;

    reg [31:0] r_CLK_EDGE_TARGET = 0;
    reg [31:0] r_ARMSTATE;
    
    reg [31:0] r_PULSEWIDTH = 0;
    reg [31:0] r_REPEAT = 0; // 31:16 = repeat count, 15:0 = repeat delay.
    
    reg [31:0] r_CLKTARGET;

    reg [3:0] r_state = 0;
    reg [7:0] r_cmdbuf = 0;
    reg [7:0] r_parambuf = 0;
    
    reg [7:0] r_cfgreg1 = 0;
    reg r_disarm = 1;

    reg r_usart_tx_queue;
    reg [7:0] r_usart_tx_queue_byte;

`define STATE_IDLE 0
`define STATE_WAITPARAM 1
`define STATE_WAITDATA 2

`define CMD_PING 8'h1
`define CMD_READ 8'h2
`define CMD_WRITE 8'h3
`define CMD_ARM 8'h4
`define CMD_DISARM 8'h5
`define CMD_CHECKSTATE 8'h6

`define PARAM_CLKEDGES 8'h1
`define PARAM_ARMSTATE 8'h2
`define PARAM_REPEAT 8'h3
`define PARAM_PULSEWIDTH 8'h4
`define PARAM_EDGETGT 8'h5
`define PARAM_OUTPUTMUX 8'h6
`define PARAM_FORCEOUTPUT 8'h7
`define PARAM_CFGREG1 8'h8

`define RESP_ACK 8'hAA
`define RESP_NACK 8'hFF

    reg r_write_strobe;
    reg r_test_led = 0;
    
    reg [31:0] r_edgectr = 0;
    reg [31:0] r_edgetgt = 0;

    always @(posedge rx_strobe) begin
        if (r_state == `STATE_IDLE) begin
            if(rx_byte[7:0] == `CMD_PING) begin
                r_usart_tx_queue_byte[7:0] <= `RESP_ACK;
                r_usart_tx_queue <= 1 - r_usart_tx_queue;
                // r_test_led <= 1 - r_test_led;
            end else if(rx_byte[7:0] == `CMD_CHECKSTATE) begin
                r_usart_tx_queue_byte[7:4] <= 4'b0;
                r_usart_tx_queue_byte[3:0] <= r_gl_state[3:0];
                r_usart_tx_queue <= 1 - r_usart_tx_queue;
            end else if(rx_byte[7:0] == `CMD_ARM) begin
                r_disarm <= 0;
                r_usart_tx_queue_byte[7:0] <= `RESP_ACK;
                r_usart_tx_queue <= 1 - r_usart_tx_queue;
            end else if(rx_byte[7:0] == `CMD_DISARM) begin
                r_disarm <= 1;
                r_usart_tx_queue_byte[7:0] <=  `RESP_ACK;
                r_usart_tx_queue <= 1 - r_usart_tx_queue;
                // r_test_led <= 0;
            end else if ((rx_byte[7:0] == `CMD_READ) ||  (rx_byte[7:0] == `CMD_WRITE)) begin
                r_state <= `STATE_WAITPARAM;
                r_cmdbuf[7:0] <= rx_byte[7:0];
            end else begin
                r_usart_tx_queue_byte[7:0] <= `RESP_NACK;
                r_usart_tx_queue <= 1 - r_usart_tx_queue;
                r_state <= `STATE_IDLE;
            end
        end
        else if (r_state == `STATE_WAITPARAM) begin
            r_parambuf[7:0] <= rx_byte[7:0];
            r_state <= `STATE_WAITDATA;
        end
        else if(r_state == `STATE_WAITDATA) begin
            if (r_cmdbuf == `CMD_READ) begin
                if ((r_parambuf == `PARAM_CLKEDGES) && (rx_byte < 4)) begin
                    r_usart_tx_queue_byte[7:0] <= r_CLK_EDGE_TARGET[8 * rx_byte +:8];
                    r_usart_tx_queue <= 1 - r_usart_tx_queue;
                end else if ((r_parambuf == `PARAM_ARMSTATE) && (rx_byte < 4)) begin
                    r_usart_tx_queue_byte[7:0] <= r_ARMSTATE[8 * rx_byte +:8];
                    r_usart_tx_queue <= 1 - r_usart_tx_queue;
                end else if ((r_parambuf == `PARAM_REPEAT) && (rx_byte < 4))begin
                    r_usart_tx_queue_byte[7:0] <= r_REPEAT[8 * rx_byte +:8];
                    r_usart_tx_queue <= 1 - r_usart_tx_queue;
                end else if ((r_parambuf == `PARAM_PULSEWIDTH) && (rx_byte < 4)) begin
                    r_usart_tx_queue_byte[7:0] <= r_PULSEWIDTH[8 * rx_byte +:8];
                    r_usart_tx_queue <= 1 - r_usart_tx_queue;
                end else begin
                    r_usart_tx_queue_byte[7:0] <= `RESP_NACK;
                    r_usart_tx_queue <= 1 - r_usart_tx_queue;
                end
            end else if (r_cmdbuf == `CMD_WRITE) begin
                if (r_parambuf[7:4] == `PARAM_CLKEDGES) begin
                    r_CLK_EDGE_TARGET[8 * r_parambuf[3:0] +:8] <= rx_byte;
                    r_usart_tx_queue_byte[7:0] <= `RESP_ACK;
                    r_usart_tx_queue <= 1 - r_usart_tx_queue;
                end else if (r_parambuf[7:4] == `PARAM_EDGETGT) begin
                    r_edgetgt[8 * r_parambuf[3:0] +:8] <= rx_byte;
                    r_usart_tx_queue_byte[7:0] <= `RESP_ACK;
                    r_usart_tx_queue <= 1 - r_usart_tx_queue;
                end else if (r_parambuf[7:4] == `PARAM_CFGREG1) begin
                    r_cfgreg1[7:0] <= rx_byte;
                    r_usart_tx_queue_byte[7:0] <= `RESP_ACK;
                    r_usart_tx_queue <= 1 - r_usart_tx_queue;
                end else if (r_parambuf[7:4] == `PARAM_ARMSTATE) begin
                    r_ARMSTATE[r_parambuf[3:0] +:8] <= rx_byte;
                    r_usart_tx_queue_byte[7:0] <= `RESP_ACK;
                    r_usart_tx_queue <= 1 - r_usart_tx_queue;
                end else if (r_parambuf[7:4] == `PARAM_REPEAT) begin
                    r_REPEAT[8 * r_parambuf[3:0] +:8] <= rx_byte;
                    r_usart_tx_queue_byte[7:0] <= `RESP_ACK;
                    r_usart_tx_queue <= 1 - r_usart_tx_queue;
                end else if (r_parambuf[7:4] == `PARAM_PULSEWIDTH) begin
                    r_PULSEWIDTH[8 * r_parambuf[3:0] +:8] <= rx_byte;
                    r_usart_tx_queue_byte[7:0] <= `RESP_ACK;
                    r_usart_tx_queue <= 1 - r_usart_tx_queue;
                end else if (r_parambuf[7:4] == `PARAM_OUTPUTMUX) begin
                    r_output_mux <= rx_byte[7:0];
                    r_usart_tx_queue_byte[7:0] <= `RESP_ACK;
                    r_usart_tx_queue <= 1 - r_usart_tx_queue;
                end else if (r_parambuf[7:4] == `PARAM_FORCEOUTPUT) begin
                    r_force_output <= rx_byte[7:0];
                    r_usart_tx_queue_byte[7:0] <= `RESP_ACK;
                    r_usart_tx_queue <= 1 - r_usart_tx_queue;
                end else begin
                    r_usart_tx_queue_byte[7:0] <= `RESP_NACK;
                    r_usart_tx_queue <= 1 - r_usart_tx_queue;
                end
            end else begin
                r_usart_tx_queue_byte[7:0] <= `RESP_NACK;
                r_usart_tx_queue <= 1 - r_usart_tx_queue;
            end
            // no command is more than 3 bytes.
            r_state <= `STATE_IDLE;
        end
    end

    reg [2:0] wr_strobe = 0;
    assign tx_strobe = wr_strobe[1] | wr_strobe[0];
    assign wr_byte[7:0] = r_usart_tx_queue_byte[7:0];

    reg r_usart_tx_lastqueue = 0;
    always @(posedge clk) begin
        if (r_usart_tx_lastqueue != r_usart_tx_queue) begin
            wr_strobe <= 2;
            r_usart_tx_lastqueue <= 1 - r_usart_tx_lastqueue; // pulse uart clk for 1 cycle.
            // wr_byte[7:0] <= r_usart_tx_queue_byte[7:0];
        end else begin
            if (wr_strobe != 0) begin
                wr_strobe <= wr_strobe - 1;
            end
        end
    end

    // glitch_Ctr, pulse_width
    reg [31:0] r_gl_ctr = 0;
    reg [31:0] r_gl_pulse = 0;
    reg [3:0] r_gl_state = 0;
    
    wire [31:0] w_REPEAT_WAIT;
    assign w_REPEAT_WAIT[31:16] = 16'b0;
    assign w_REPEAT_WAIT[15:0] = r_REPEAT[15:0];

    reg [15:0] r_gl_rptcount = 0;

`define GL_IDLE 4'h0
`define GL_ARMED 4'h1
`define GL_WAITING 4'h2
`define GL_FIRING 4'h3
`define GL_COOLDOWN 4'h4

    wire w_manual_arm = (r_ARMSTATE[0] == 1'b1);
    // reg last_trig = 1'b0;
    // wire w_trig = (i_trig || w_manual_arm);
    
    reg r_last_trig = 1'b0;
    
    // falling 
    wire i_trig = i_trig_orig ^ r_cfgreg1[0];
    wire w_real_trig = ((i_trig == 1) && (r_last_trig == 0));

    assign o_test_led = w_manual_arm;
    assign o_glitch = (r_gl_state == `GL_FIRING);
    
    assign o_arm_led = (r_gl_state == `GL_ARMED);
    assign o_waiting_led = (r_gl_state == `GL_WAITING);
    assign o_firing_led = (r_gl_state == `GL_FIRING);// = r_cfgreg1[0]; // 
    
    always @(posedge sysclk) begin
        r_last_trig <= i_trig;
        if (r_disarm == 1) begin
            r_gl_state <= `GL_IDLE;
            r_gl_ctr <= 0;
            r_gl_pulse <= 0;
            r_gl_rptcount <= 0;
            r_edgectr <= 0;
        end else if (r_disarm == 1 && r_gl_state == `GL_COOLDOWN) begin
            // fix for avr trigger high lock bug
            // 31-dec-22 : seems redundant, investigate why i put this here
            r_gl_state <= `GL_IDLE;
            r_gl_ctr <= 0;
            r_gl_pulse <= 0;
            r_gl_rptcount <= 0;
            r_edgectr <= 0;
        end else if (r_disarm == 0 && r_gl_state == `GL_IDLE) begin
            r_gl_state <= `GL_ARMED;
            r_gl_ctr <= 0;
            r_gl_pulse <= 0;
            r_gl_rptcount <= 0;
        end else if (r_gl_state == `GL_ARMED) begin
            if (w_manual_arm == 1) begin
                // force arming state, manually fire
                r_gl_state <= `GL_WAITING;
            end else begin
                if (w_real_trig == 1) begin
                    if (r_edgectr == r_edgetgt) begin
                    r_gl_state <= `GL_WAITING;
                    end else begin
                        r_edgectr <= r_edgectr + 1;
                    end
                end
            end
        end else if (r_gl_state == `GL_WAITING) begin
            if (r_gl_ctr[31:0] == r_CLK_EDGE_TARGET[31:0]) begin
                r_gl_state <= `GL_FIRING;
            end else begin
                r_gl_ctr <= r_gl_ctr + 1;
            end
        end else if(r_gl_state == `GL_FIRING) begin
            if (r_gl_pulse[31:0] == r_PULSEWIDTH[31:0]) begin
                if (r_gl_rptcount[15:0] == r_REPEAT[31:16]) begin
                    // finished, cooldown
                    r_gl_state <= `GL_COOLDOWN;
                    r_gl_ctr <= 0;
                    r_gl_pulse <= 0;
                    r_gl_rptcount <= 0;
                    r_edgectr <= 0;
                end else begin
                    // refire.
                    r_gl_state <= `GL_WAITING;
                    r_gl_ctr <= r_CLK_EDGE_TARGET - w_REPEAT_WAIT;
                    r_gl_pulse <= 0;
                    r_gl_rptcount <= r_gl_rptcount + 1;
                end
            end else begin
                r_gl_pulse <= r_gl_pulse + 1;
            end
        end
    end

endmodule
