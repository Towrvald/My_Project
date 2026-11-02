module ps2_top
(
input logic clk,
input logic clk_ps2,
input logic rst_n,
input logic ps2_data,
output logic tx_pin
);

logic rst_n_meta, rst_n_sync;

always_ff @(posedge clk)
begin
    rst_n_meta <= rst_n;
    rst_n_sync <= rst_n_meta;
end



logic [7:0] temp_data;
logic temp_data_valid;

ps2_receiver ps2_data_input 
(
.clk        (clk),
.clk_ps2    (clk_ps2),
.data_ps2   (ps2_data),
.rst_n      (rst_n_sync),
.data       (temp_data),
.data_valid (temp_data_valid)
);

logic [7:0] data_to_fifo;
logic data_to_fifo_valid;

ps2_data_processing scan_code_set2
(
.clk                (clk),
.rst_n              (rst_n_sync),
.ps2_data           (temp_data),
.ps2_data_valid     (temp_data_valid),
.ascii_data         (data_to_fifo),
.ascii_data_valid   (data_to_fifo_valid)
);


logic [7:0] data_to_tx_pin;
logic data_to_tx_pin_valid;
logic uart_tx_ready;


fifo 
#(
.WIDTH(8),
.DEPTH(64)
)
fifo_exemplar
(
.clk                (clk),
.rst_n              (rst_n_sync),
.write_data_valid   (data_to_fifo_valid),
.read_enable        (uart_tx_ready),
.write_data         (data_to_fifo),
.read_data          (data_to_tx_pin),
.read_data_valid    (data_to_tx_pin_valid)
);

uart_tx
#(
.BAUD_RATE(115_200),
.CLK_FREQ_HZ(50_000_000)
) 
uart_tx_exemplar
(
.clk            (clk), 
.rst_n          (rst_n_sync),
.read_data      (data_to_tx_pin), 
.rd_data_valid  (data_to_tx_pin_valid), 
.rd_en          (uart_tx_ready), 
.tx             (tx_pin)
);
endmodule