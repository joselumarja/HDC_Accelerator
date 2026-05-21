`timescale 1ns/1ps

module serializer_tb;

    parameter IN_WIDTH  = 32;
    parameter OUT_WIDTH = 8;
    parameter DEPTH     = 8;
    parameter SEGMENTS  = IN_WIDTH / OUT_WIDTH;
    parameter ADDR_WIDTH = $clog2(DEPTH);

    reg clk, rst, start;
    wire busy, done;

    reg [IN_WIDTH-1:0] data_in;
    wire [OUT_WIDTH-1:0] fifo_din, fifo_dout;
    wire wr_en;
    wire [ADDR_WIDTH:0] size;
    wire full, empty;

    // FIFO dummy
    wire [OUT_WIDTH-1:0] fifo_dout = 0;
    reg rd_en = 0;
    
    //debug
    wire [2:0] state;

    fifo #(
        .DATA_WIDTH(OUT_WIDTH),
        .DEPTH(DEPTH)
    ) fifo_inst (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .din(fifo_din),
        .dout(fifo_dout),
        .size(size),
        .full(full),
        .empty(empty)
    );

    serializer #(
        .IN_WIDTH(IN_WIDTH),
        .OUT_WIDTH(OUT_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .data_in(data_in),
        .busy(busy),
        .done(done),
        .fifo_din(fifo_din),
        .wr_en(wr_en),
        .fifo_full(full),
        .state_debug(state)
    );

    always #5 clk = ~clk;
    
    // Variables internas
    integer i;

    initial begin
        clk = 0;
        rst = 1;
        start = 0;
        data_in = 32'hA1B2C3D4;
        
        $display("\n--- SERIALIZANDO DATOS ---");

        #10 rst = 0;
        #10 start = 1;
        #10 start = 0;

        wait(done);
        
        $display("\n--- LEYENDO DATOS ---");
        // Leer hasta que esté vacía
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(posedge clk);
            if (!empty) begin
                rd_en = 1;
                #2
                $display("Read: %d", fifo_dout);
                $display("Size: %d", size);
            end
        end
        rd_en = 0;

        @(posedge clk);
        $display("Size: %d", size);
        $display("EMPTY = %b (esperado: 1)", empty);

        $display("\n--- TEST COMPLETADO ---");
        
        $display("\n--- TEST SATURACIÓN FIFO ---");
        
        #10 start = 1;
        #10 start = 0;
        
        wait(done)
        
        #10
        
        #10 start = 1;
        #10 start = 0;
        
        wait(done)
        
        #10 start = 1;
        #10 start = 0;
        
        #30
        
        rd_en = 1;
        
        while(!empty) begin
            @(posedge clk);
            #2
            $display("Read: %d", fifo_dout);
            $display("Size: %d", size);
            
        end

        $display("\n--- SERIALIZER TEST COMPLETADO ---\n");
        
        #20
        
        $stop;
        
       
    end

endmodule
