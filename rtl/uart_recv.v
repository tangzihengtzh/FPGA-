module uart_receiver (
    input wire sys_clk,
    input wire sys_rst,
    input wire uart_rxd,
    output reg [7:0] rx_data,
    output reg uart_done,
    output reg recv_flag    //测试标志用，可用于连接LED观察状态机是否发生变化
);
    parameter buadrate = 9600;
    localparam CLK_FREQ = 50000000;
    localparam BIT_PERIOD = CLK_FREQ / buadrate; // 5208 cycles

    localparam IDLE = 4'b0000;
    localparam START = 4'b0001;
    localparam DATA = 4'b0010;
    localparam STOP = 4'b0011;

    reg [3:0] state = IDLE;
    reg [31:0] bit_cnt = 0;
    reg [3:0] bit_idx = 0;
    reg bit_flag = 0;

    always @(posedge sys_clk or negedge sys_rst) begin
        if (!sys_rst) begin
            state <= IDLE;
            recv_flag <= 1;
            uart_done <= 0;
            bit_cnt <= 0;
            bit_idx <= 0;
            rx_data <= 8'b11111111;
        end else begin
            case (state)
                IDLE: begin
                    if (uart_rxd == 0) begin
                        state <= START;
                        bit_cnt <= 0;
                    end
                end
                START: begin
                    recv_flag <= 0;
                    if (bit_cnt == (BIT_PERIOD/2)) begin
                        state <= DATA;
                        bit_cnt <= 0;
                        bit_idx <= 0;
                    end else begin
                        bit_cnt <= bit_cnt + 1;
                    end
                end
                DATA: begin
                    if (bit_cnt < BIT_PERIOD) begin
                        bit_cnt <= bit_cnt + 1;
                    end else begin
                        bit_cnt <= 0;
                        rx_data[bit_idx] <= uart_rxd;
                        if (bit_idx == 7) begin
                            state <= STOP;
                        end else begin
                            bit_idx <= bit_idx + 1;
                        end
                    end
                end
                STOP: begin
                        recv_flag <= 1;
                    if (bit_cnt < BIT_PERIOD) begin
                        bit_cnt <= bit_cnt + 1;
                    end else begin
                        state <= IDLE;
                        uart_done <= 1;
                    end
                end
            endcase
        end
    end
endmodule



