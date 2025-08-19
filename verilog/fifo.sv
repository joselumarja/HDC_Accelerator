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
    output reg                 full,
    output reg                 empty,
    output wire [ADDR_WIDTH-1:0] wr_ptr_debug,
    output wire [ADDR_WIDTH-1:0] rd_ptr_debug
    
);

    // Memory to store FIFO data
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Write and read pointers
    reg [ADDR_WIDTH-1:0] wr_ptr = 0;
    reg [ADDR_WIDTH-1:0] rd_ptr = 0;

    reg [ADDR_WIDTH:0] fifo_count = 0;
    
    
    //debug
    assign wr_ptr_debug = wr_ptr;
    assign rd_ptr_debug = rd_ptr;
    
    // Signal logic
    always @(posedge clk) begin
        if(rst) begin
            full <= 0;
            empty <= 1;
            size <= 0;
        end else begin
            full  <= (fifo_count == DEPTH);
            empty <= (fifo_count == 0);
            size <= fifo_count;
        end
    end

    // Write logic
    always @(posedge clk) begin
        if (!rst && wr_en && !(fifo_count==DEPTH)) begin
            mem[wr_ptr] <= din;
        end
    end

    // Read logic
    always @(posedge clk) begin
        if (rst) begin
            dout   <= 0;
        end else if (rd_en && !(fifo_count==0)) begin
            dout <= mem[rd_ptr];
        end
    end
    
    // Pointer logic
    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            
        end else begin
        
            if(wr_en && !(fifo_count==DEPTH)) begin
                if(wr_ptr == (DEPTH-1))
                    wr_ptr <= 0;
                else
                    wr_ptr <= wr_ptr + 1;
            end
            
            if(rd_en && !(fifo_count==0)) begin
                if(rd_ptr == (DEPTH-1))
                    rd_ptr <= 0;
                else
                    rd_ptr <= rd_ptr + 1;
            end
        end
    end
    
    
    // Counter logic
    always @(posedge clk) begin
        if (rst) begin
            fifo_count <= 0;
        end else begin
            case ({wr_en && !(fifo_count==DEPTH), rd_en && !(fifo_count==0)})
                2'b10: begin
                    fifo_count <= fifo_count + 1; // Solo escritura
                end
                2'b01: begin 
                    fifo_count <= fifo_count - 1; // Solo lectura
                end
                /*2'b11: begin
                    fifo_count <= fifo_count;     // Lectura y escritura simultánea → el tamaño no cambia
                end*/
                default: begin 
                    fifo_count <= fifo_count;   // Sin operaciones o Lectura y escritura simultanea
                end
            endcase
        end
        
    end


endmodule
