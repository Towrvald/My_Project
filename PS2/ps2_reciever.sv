module ps2_receiver
(
input logic         clk,
input logic         clk_ps2,
input logic         data_ps2,
input logic         rst_n,
output logic [7:0]  data,
output logic        data_valid
);

logic [7:0] buffer; // сюда записываем приходящий байт
logic [2:0] bit_index;
logic parity_ok;
logic clk_ps2_fall; // прозишёл спад фронта тактового сигнала от клавиатуры?

logic clk_ps2_meta, clk_ps2_sync, clk_ps2_prev; //тактовый сигнал от ps асинхронен с нашим тактовым сигналом
logic data_ps2_meta, data_ps2_sync;

always_ff @(posedge clk) //синхронизатор
begin
    if(!rst_n)
    begin
        clk_ps2_meta <= 1'b1;
        clk_ps2_sync <= 1'b1;
        clk_ps2_prev <= 1'b1;
        data_ps2_meta <= 1'b1;
        data_ps2_sync <= 1'b1;
    end
    else
    begin
        clk_ps2_meta <= clk_ps2;
        clk_ps2_sync <= clk_ps2_meta;
        clk_ps2_prev <= clk_ps2_sync;
        data_ps2_meta <= data_ps2;
        data_ps2_sync <= data_ps2_meta;
    end
end

assign clk_ps2_fall = (clk_ps2_prev && (!clk_ps2_sync));



typedef enum logic [1:0] 
{
    WAIT_START_BIT,
    GETTING_DATA,
    GETTING_PARITY_BIT,
    GETTING_STOP_BIT
} state_t;

state_t state;


always_ff @(posedge clk)
begin
    if(!rst_n)
    begin
        state <= WAIT_START_BIT;
        buffer <= '0;
        bit_index <= '0;
        parity_ok <= 1'b0;
    end

    else
    case(state)

    WAIT_START_BIT:
    if(clk_ps2_fall) state <= (!data_ps2_sync) ? GETTING_DATA : WAIT_START_BIT;

    GETTING_DATA:
    if(clk_ps2_fall)
    begin
        buffer[bit_index] <= data_ps2_sync;
        bit_index <= bit_index + 1'b1;
        if (bit_index == 3'd7) state <= GETTING_PARITY_BIT;
    end

    GETTING_PARITY_BIT:
    if(clk_ps2_fall)
    begin
        parity_ok <= (^buffer) ^ data_ps2_sync;
        state <= GETTING_STOP_BIT;
    end
    
    GETTING_STOP_BIT:
    if(clk_ps2_fall)
    begin
        state <= WAIT_START_BIT;
        buffer <= '0;
        parity_ok <= 1'b0;
    end


    default: state <= WAIT_START_BIT;
    endcase
end

assign data_valid = (state == GETTING_STOP_BIT) && (data_ps2_sync) && (parity_ok) && (clk_ps2_fall);
assign data = buffer;

endmodule   