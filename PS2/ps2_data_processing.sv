module ps2_data_processing 
(
input logic         clk,
input logic         rst_n,
input logic [7:0]   ps2_data,
input logic         ps2_data_valid,
output logic [7:0]  ascii_data,
output logic        ascii_data_valid
);

// Блок 1: Проверяем есть ли служебный байт F0
localparam int F0_byte = 8'hF0;
logic F0_buffer; 

always_ff @(posedge clk)
begin
    if (!rst_n) F0_buffer <= 1'b0;
    else if (ps2_data_valid && (ps2_data == F0_byte)) F0_buffer <= 1'b1;
    else if (ps2_data_valid) F0_buffer <= 1'b0;
end
// Конец блока 1

//Блок 2: Проверяем нажат ли сейчас shift
localparam int shift_byte = 8'h12;
logic shift_buffer;

always_ff @(posedge clk)
begin
    if (!rst_n) shift_buffer <= 1'b0;
    else if (ps2_data_valid && (ps2_data == shift_byte))  shift_buffer <= 1'b1;
    else if (ps2_data_valid) shift_buffer <= 1'b0;
end
// Конец блока 2

// Блок 3: Переводим байты Scan code set 2 в символы ASCII
always_comb
begin
    if (ps2_data_valid && !F0_buffer)
    begin
        ascii_data_valid = 1'b1;
        case(ps2_data)
        8'h16: ascii_data = "1";
        8'h1E: ascii_data = "2";
        8'h26: ascii_data = "3";
        8'h25: ascii_data = "4";
        8'h2E: ascii_data = "5";
        8'h36: ascii_data = "6";
        8'h3D: ascii_data = "7";
        8'h3E: ascii_data = "8";
        8'h46: ascii_data = "9";
        8'h45: ascii_data = "0";
        8'h15: ascii_data = "q";
        8'h1D: ascii_data = "w";
        8'h24: ascii_data = "e";
        8'h2D: ascii_data = "r";
        8'h2C: ascii_data = "t";
        8'h35: ascii_data = "y";
        8'h3C: ascii_data = "u";
        8'h43: ascii_data = "i";
        8'h44: ascii_data = "o";
        8'h4D: ascii_data = "p";
        8'h1C: ascii_data = "a";
        8'h1B: ascii_data = "s";
        8'h23: ascii_data = "d";
        8'h2B: ascii_data = "f";
        8'h34: ascii_data = "g";
        8'h33: ascii_data = "h";
        8'h3B: ascii_data = "j";
        8'h42: ascii_data = "k";
        8'h4B: ascii_data = "l";
        8'h1A: ascii_data = "z";
        8'h22: ascii_data = "x";
        8'h21: ascii_data = "c";
        8'h2A: ascii_data = "v";
        8'h32: ascii_data = "b";
        8'h31: ascii_data = "n";
        8'h3A: ascii_data = "m";
        8'h29: ascii_data = " ";
        8'h4C: ascii_data = ";";
        8'h5A: ascii_data = 8'h0A;
        default: 
        begin
            ascii_data = '0;
            ascii_data_valid = 1'b0;
        end
        endcase
    end
    else 
    begin
        ascii_data_valid = 1'b0;
        ascii_data = '0;
    end
end

// Конец блока 3
endmodule