module uart_tx #(
parameter int BAUD_RATE = 115200,
parameter int CLK_FREQ_HZ = 50_000_000
)
(
input logic               clk, // тактовая частота
input logic             rst_n, // сброс
input logic [7:0]   read_data, // данные, которые нужно передать
input logic     rd_data_valid, // подтверждение, что передаваемые к отправке данные дейтсвительны
output logic            rd_en, // готовность приёмника передавать данные
output logic               tx // линия передачи данных
);

localparam int time_per_bit = (CLK_FREQ_HZ + (BAUD_RATE/2))/BAUD_RATE; // время на передачу одного бита в тактах
localparam int width_count = $clog2(time_per_bit); // ширина счётчика
localparam int last_count = time_per_bit - 1;

logic [width_count - 1 : 0] count; //будет каждый раз считать до time_per_bit
logic count_complete;
assign count_complete = (count == last_count); //1, если счётчик досчитал до time_per_bit
logic [7 : 0] shreg; //сдвиговый регистр, через который будем передавать данные на tx
logic [2:0] bit_index; // индекс передваемого бита

typedef enum logic [1:0] {
IDLE, //ожидаем данные для передачи
START, // пришёл rd_data_valid, передаём стартовый бит 0
DATA, // после стартового бита передаём байт данных read_data
STOP // передаём стоп-бит
} state_t;
state_t state;

assign rd_en = (state == IDLE) && !rd_data_valid;

always_ff @(posedge clk)
begin
    if (!rst_n)
        begin
            count <= '0;
            state <= IDLE;
            shreg <= '0;
            bit_index <= '0;
            tx <= 1'b1;
        end
    else
        case (state)

        IDLE:
        if(rd_data_valid)
        begin
            shreg <= read_data;
            tx <= 1'b0;
            state <= START;
        end

        START:
        if (count_complete)
        begin
            count <= '0;
            state <= DATA;
            tx <= shreg[bit_index]; //На следующий такт уже передаём первый бит данных
        end
        else count <= count + 1'b1;

        DATA:
        if (count_complete)
        begin  
            count <= '0;
            if (bit_index == 3'd7)
                begin
                    bit_index <= '0;
                    tx <= 1'b1;
                    state <= STOP;
                end
            else 
            begin
                bit_index <= bit_index + 1'b1;
                tx <= shreg[bit_index + 1'b1];
            end
        end
        else count <= count + 1'b1;

        STOP:
        if (count_complete)
        begin
            count <= '0;
            state <= IDLE;
        end
        else count <= count + 1'b1;

        default: state <= IDLE;
        endcase
end



endmodule