module top
(
input logic     clk,
input logic     rst_n_key,
input logic     rx_pin,
output logic    tx_pin
);

localparam int BAUD_RATE = 115200;
localparam int CLK_FREQ_HZ = 50_000_000;

logic rst_n_key_meta, rst_n_key_sync;

always_ff @(posedge clk)
begin
    rst_n_key_meta <= rst_n_key;
    rst_n_key_sync <= rst_n_key_meta;
end


logic wr_dv;
logic [7:0] wr_data;

uart_rx 
#(
    .BAUD_RATE (BAUD_RATE),
    .CLK_FREQ_HZ (CLK_FREQ_HZ)
) 
uart_reciver 
(
    .clk(clk),
    .rx(rx_pin),
    .rst_n(rst_n_key_sync),
    .wr_dv(wr_dv),
    .data(wr_data)
);

logic rd_en;
logic [7:0] read_data;
logic read_data_valid;

uart_tx
#(
    .BAUD_RATE (BAUD_RATE),
    .CLK_FREQ_HZ (CLK_FREQ_HZ)
)
uart_transmitter
(
    .clk(clk),
    .rst_n(rst_n_key_sync),
    .read_data(read_data),
    .rd_data_valid(read_data_valid),
    .rd_en(rd_en),
    .tx(tx_pin)
);

fifo fifo_buffer
(
    .clk(clk),
    .rst_n(rst_n_key_sync),
    .write_data_valid(wr_dv),
    .write_data(wr_data),
    .read_enable(rd_en),
    .read_data(read_data),
    .read_data_valid(read_data_valid)
);
endmodule