module vga (
    input  logic clk50,
    input  logic rst_n,

    output logic vga_r,
    output logic vga_g,
    output logic vga_b,
    output logic h_sync,
    output logic v_sync
);

    logic clk_pixel;
    logic pll_locked;

    pll_pixel u_pll (
        .inclk0 (clk50),
        .areset (~rst_n),
        .c0     (clk_pixel),
        .locked (pll_locked)
    );


    logic       pixel_rst_request;
    logic [1:0] pixel_rst_pipe;
    logic       pixel_rst_n;

    assign pixel_rst_request = !rst_n || !pll_locked;

    always_ff @(posedge clk_pixel or posedge pixel_rst_request) begin
        if (pixel_rst_request)
            pixel_rst_pipe <= 2'b00;
        else
            pixel_rst_pipe <= {pixel_rst_pipe[0], 1'b1};
    end

    assign pixel_rst_n = pixel_rst_pipe[1];

    localparam int H_VISIBLE = 1024;
    localparam int H_FRONT_PORCH = 48;
    localparam int H_SYNC_PULSE = 96;
    localparam int H_BACK_PORCH = 144;
    localparam int H_TOTAL = H_VISIBLE + H_FRONT_PORCH + H_SYNC_PULSE + H_BACK_PORCH;

    localparam int V_VISIBLE     = 600;
    localparam int V_FRONT_PORCH = 3;
    localparam int V_SYNC_PULSE  = 10;
    localparam int V_BACK_PORCH  = 11;
    localparam int V_TOTAL = V_VISIBLE + V_FRONT_PORCH + V_SYNC_PULSE + V_BACK_PORCH;

    localparam int H_SYNC_START = H_VISIBLE + H_FRONT_PORCH;
    localparam int H_SYNC_END = H_SYNC_START + H_SYNC_PULSE;
    localparam int V_SYNC_START = V_VISIBLE + V_FRONT_PORCH;
    localparam int V_SYNC_END = V_SYNC_START + V_SYNC_PULSE;


    localparam int SQUARE_SIZE = 200;
    localparam int SQUARE_Y = 200;
    localparam int SQUARE_X0 = 250;
    localparam int X_MAX = H_VISIBLE - SQUARE_SIZE;

    logic [$clog2(H_TOTAL)-1:0] h_count;
    logic [$clog2(V_TOTAL)-1:0] v_count;
    logic  video_on;
    logic frame_tick;

    assign video_on   = (h_count < H_VISIBLE) && (v_count < V_VISIBLE);
    assign frame_tick = (h_count == '0) && (v_count == V_VISIBLE);

    always_ff @(posedge clk_pixel) begin
        if (!pixel_rst_n) begin
            h_count <= '0;
            v_count <= '0;
        end
        else if (h_count == H_TOTAL - 1) begin
            h_count <= '0;
            if (v_count == V_TOTAL - 1)
                v_count <= '0;
            else
                v_count <= v_count + 1'b1;
        end
        else begin
            h_count <= h_count + 1'b1;
        end
    end

    always_ff @(posedge clk_pixel) begin
        if (!pixel_rst_n) begin
            h_sync <= 1'b1;
            v_sync <= 1'b0;
        end
        else begin
            h_sync <= !((h_count >= H_SYNC_START) && (h_count < H_SYNC_END));
            v_sync <=   (v_count >= V_SYNC_START) && (v_count < V_SYNC_END);
        end
    end

    logic [$clog2(H_VISIBLE)-1:0] square_x;
    logic                         right_move;

    always_ff @(posedge clk_pixel) begin
        if (!pixel_rst_n) begin
            square_x   <= SQUARE_X0;
            right_move <= 1'b1;
        end
        else if (frame_tick) begin
            if (right_move) begin
                if (square_x == X_MAX) begin
                    right_move <= 1'b0;
                    square_x   <= square_x - 1'b1;
                end
                else begin
                    square_x <= square_x + 1'b1;
                end
            end
            else begin
                if (square_x == '0) begin
                    right_move <= 1'b1;
                    square_x   <= square_x + 1'b1;
                end
                else begin
                    square_x <= square_x - 1'b1;
                end
            end
        end
    end


    logic in_square;

    assign in_square = (h_count >= square_x) && (h_count < square_x + SQUARE_SIZE) &&
                       (v_count >= SQUARE_Y) && (v_count < SQUARE_Y + SQUARE_SIZE);

    always_ff @(posedge clk_pixel) begin
        if (!pixel_rst_n)
            {vga_r, vga_g, vga_b} <= 3'b000;
        else if (!video_on)
            {vga_r, vga_g, vga_b} <= 3'b000;
        else if (in_square)
            {vga_r, vga_g, vga_b} <= 3'b100;
        else
            {vga_r, vga_g, vga_b} <= 3'b000;
    end

endmodule