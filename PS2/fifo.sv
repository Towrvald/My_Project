module fifo #(
    parameter int WIDTH = 8,
    parameter int DEPTH = 64
)(
    input  logic             clk,
    input  logic             rst_n,
    input  logic             write_data_valid,
    input  logic             read_enable,
    input  logic [WIDTH-1:0] write_data,
    output logic [WIDTH-1:0] read_data,
    output logic             read_data_valid,
    output logic             Full,
    output logic             Empty
);

    localparam int AW = $clog2(DEPTH);   // разрядность адреса

    logic [AW:0] wr_ptr, rd_ptr;         // на 1 бит шире: старший бит — номер круга
    logic [WIDTH-1:0] mem [0:DEPTH-1];
    logic wr_ok, rd_ok;

    assign wr_ok = write_data_valid && !Full;
    assign rd_ok = read_enable && !Empty;

    // 1. Память: только mem и read_data, без сброса (M9K)
    always_ff @(posedge clk)
    begin
        if (wr_ok) mem[wr_ptr[AW-1:0]] <= write_data;
        if (rd_ok) read_data <= mem[rd_ptr[AW-1:0]];
    end

    // 2. Указатели и read_data_valid: со сбросом
    always_ff @(posedge clk)
    begin
        if (!rst_n)
        begin
            wr_ptr          <= '0;
            rd_ptr          <= '0;
            read_data_valid <= 1'b0;
        end
        else
        begin
            if (wr_ok) wr_ptr <= wr_ptr + 1'b1;
            if (rd_ok) rd_ptr <= rd_ptr + 1'b1;
            read_data_valid <= rd_ok;
        end
    end

    // 3. Флаги: комбинационные, сброс не нужен
    always_comb
    begin
        Empty = (wr_ptr == rd_ptr);
        Full  = (wr_ptr[AW] != rd_ptr[AW]) && (wr_ptr[AW-1:0] == rd_ptr[AW-1:0]);
    end

endmodule