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
    output wire  [ADDR_WIDTH:0]  size,      // Number elements in fifo
    output wire                 full,
    output wire                 empty,
    output wire [ADDR_WIDTH:0] wr_ptr_debug,
    output wire [ADDR_WIDTH:0] rd_ptr_debug
    
);

    // Memory to store FIFO data
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Write and read pointers
    reg [ADDR_WIDTH:0] wr_ptr = 0;
    reg [ADDR_WIDTH:0] rd_ptr = 0;

    reg [ADDR_WIDTH:0] fifo_count = 0;

    assign full  = (fifo_count == DEPTH);
    assign empty = (fifo_count == 0);
    assign size = fifo_count;
    
    //debug
    assign wr_ptr_debug = wr_ptr;
    assign rd_ptr_debug = rd_ptr;

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
        end else begin
            case ({wr_en && !full, rd_en && !empty})
                2'b10: fifo_count <= fifo_count + 1; // Solo escritura
                2'b01: fifo_count <= fifo_count - 1; // Solo lectura
                2'b11: fifo_count <= fifo_count;     // Lectura y escritura simultánea → el tamaño no cambia
                default: fifo_count <= fifo_count;   // Sin operaciones
            endcase
        end
    end


endmodule
