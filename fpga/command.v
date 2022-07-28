module command(
  input clk,
  input rx_strobe,
  input [7:0] rx_byte,
  input tx_done,
  output tx_strobe,
  output [7:0] wr_byte,
  output w_test_led
  );  

reg [32:0] r_CLK_EDGE_TARGET = 0;
reg [32:0] r_IO_EDGE_TARGET = 0;
reg [32:0] r_NS_EDGE_TARGET = 0;
reg [32:0] r_PULSEWIDTH = 0;

reg [3:0] r_state = 0;
reg [7:0] r_cmdbuf = 0;
reg [7:0] r_parambuf = 0;

reg r_disarm = 0;

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

`define PARAM_CLKEDGES 8'h1
`define PARAM_IOEDGES 8'h2
`define PARAM_NSEDGES 8'h3
`define PARAM_PULSEWIDTH 8'h4

`define RESP_ACK 8'hAA
`define RESP_NACK 8'hFF

reg r_write_strobe;

reg r_test_led = 0;
assign w_test_led = r_test_led;

always @(posedge rx_strobe) begin
    if (r_state == `STATE_IDLE) begin
        if(rx_byte[7:0] == `CMD_PING) begin
            r_usart_tx_queue_byte[7:0] <= `RESP_ACK;
            r_usart_tx_queue <= 1 - r_usart_tx_queue;
            r_test_led <= 1 - r_test_led;
            // wr_strobe <= 1 - wr_strobe;
            // wr_byte <= `RESP_ACK;
        end else if(rx_byte[7:0] == `CMD_ARM) begin
            r_disarm <= 0;
            // r_usart_tx_queue_byte[7:0] <= rx_byte[7:0];
            r_usart_tx_queue_byte[7:0] <= `RESP_ACK;
            r_usart_tx_queue <= 1 - r_usart_tx_queue;
        end else if(rx_byte[7:0] == `CMD_DISARM) begin
            r_disarm <= 1;
            // r_usart_tx_queue_byte[7:0] <= rx_byte[7:0];
            r_usart_tx_queue_byte[7:0] <= 8'h21;
            r_usart_tx_queue <= 1 - r_usart_tx_queue;
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
            end else if ((r_parambuf == `PARAM_IOEDGES) && (rx_byte < 4)) begin
                r_usart_tx_queue_byte[7:0] <= r_IO_EDGE_TARGET[8 * rx_byte +:8];
                r_usart_tx_queue <= 1 - r_usart_tx_queue;    
            end else if ((r_parambuf == `PARAM_NSEDGES) && (rx_byte < 4)) begin
                r_usart_tx_queue_byte[7:0] <= r_NS_EDGE_TARGET[8 * rx_byte +:8];
                r_usart_tx_queue <= 1 - r_usart_tx_queue;   
end else if ((r_parambuf == `PARAM_NSEDGES) && (rx_byte < 4)) begin
                r_usart_tx_queue_byte[7:0] <= r_NS_EDGE_TARGET[8 * rx_byte +:8];
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
            end else if (r_parambuf[7:4] == `PARAM_IOEDGES) begin
                r_IO_EDGE_TARGET[8 * r_parambuf[3:0] +:8] <= rx_byte;
                r_usart_tx_queue_byte[7:0] <= `RESP_ACK;
                r_usart_tx_queue <= 1 - r_usart_tx_queue;
            end else if (r_parambuf[7:4] == `PARAM_NSEDGES) begin
                r_NS_EDGE_TARGET[8 * r_parambuf[3:0] +:8] <= rx_byte;
                r_usart_tx_queue_byte[7:0] <= `RESP_ACK;
                r_usart_tx_queue <= 1 - r_usart_tx_queue;   
            end else if (r_parambuf[7:4] == `PARAM_PULSEWIDTH) begin
                r_PULSEWIDTH[8 * r_parambuf[3:0] +:8] <= rx_byte;
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

endmodule
