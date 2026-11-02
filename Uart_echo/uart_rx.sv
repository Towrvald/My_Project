module uart_rx #(
parameter int BAUD_RATE = 115200,
parameter int CLK_FREQ_HZ = 50_000_000
)
(
input logic         clk,
input logic         rst_n,
input logic         rx,
output logic        wr_dv,
output logic [7:0]  data,
output logic        frame_error
);

localparam int TIME_PER_BIT = (CLK_FREQ_HZ + (BAUD_RATE/2)) / BAUD_RATE;
localparam int WIDTH_COUNT = $clog2(TIME_PER_BIT);
localparam int LAST_COUNT = TIME_PER_BIT - 1;

logic [WIDTH_COUNT-1 : 0] count;
logic [2:0] bit_index;
logic [7:0] shreg;

typedef enum logic [2:0] {IDLE, START, DATA, STOP, ERROR} state_t;
state_t state;

logic rx_meta, rx_sync;
always_ff @(posedge clk)
begin
    if (!rst_n)
    begin
        rx_meta <= 1'b1;
        rx_sync <= 1'b1;
    end
    else
    begin
        rx_meta <= rx;
        rx_sync <= rx_meta;
    end
end

logic count_complete;
assign count_complete = (count == LAST_COUNT);
assign wr_dv = (state == STOP) && (rx_sync == 1'b1) && (count_complete); 

always_ff @(posedge clk)
begin
    if (!rst_n)
        begin
            shreg <= '0;
            data <= '0;
            bit_index <= '0;
            count <= '0;
            state <= IDLE;
        end
    else
        case (state)

        IDLE: if(rx_sync == 1'b0) state <= START;
        
        START:
        if (count == (LAST_COUNT/2))
        begin
            count <= '0;
            if(rx_sync == 1'b0) state <= DATA;
            else state <= IDLE;
        end
        else count <= count + 1'b1;

        DATA:
        if (count_complete)
        begin
            count <= '0;
            shreg[bit_index] <= rx_sync;
            bit_index <= bit_index + 1'b1;
            if (bit_index == 3'd7) state <= STOP;
        end
        else count <= count + 1'b1;

        STOP:
        if(count_complete)
        begin
            count <= '0;
            if (rx_sync == 1'b1) state <= IDLE;
            else state <= ERROR;
        end
        else 
        begin
            count <= count + 1'b1;
            data <= shreg;
        end

        ERROR: if (rx_sync == 1'b1) state <= IDLE;

        default: state <= IDLE;
        endcase
end

assign frame_error = (state == ERROR);

endmodule