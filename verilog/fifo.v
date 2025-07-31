module fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 16,
    parameter ADDR_WIDTH = $clog2(DEPTH)
)(
    input  wire                 clk,
    input  wire                 rst,       // Synchronous reset
    input  wire                 wr_en,     // Write enable
    input  wire                 rd_en,     // Read enable
    input  wire [DATA_WIDTH-1:0] din,      // Data in
    output reg  [DATA_WIDTH-1:0] dout,     // Data out
    output reg  [ADDR_WIDTH:0]  size,      // Number elements in fifo
    output wire                 full,
    output wire                 empty
);

    // Memory to store FIFO data
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Write and read pointers
    reg [ADDR_WIDTH:0] wr_ptr = 0;
    reg [ADDR_WIDTH:0] rd_ptr = 0;

    reg [ADDR_WIDTH:0] fifo_count = 0;

    assign full  = (fifo_count == DEPTH);
    assign empty = (fifo_count == 0);

    // Write logic
    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr] <= din;
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read logic
    always @(posedge clk) begin
        if (rst) begin
            rd_ptr <= 0;
            dout   <= 0;
        end else if (rd_en && !empty) begin
            dout <= mem[rd_ptr];
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Counter logic
    always @(posedge clk) begin
        if (rst) begin
            fifo_count <= 0;
        end else if (rd_en && !empty) begin
            fifo_count <= fifo_count - 1;
        end else if (wr_en && !full) begin
            fifo_count <= fifo_count + 1;
        end
    end
    
    always @(fifo_count) begin
        size <= fifo_count;
    end

endmodule
