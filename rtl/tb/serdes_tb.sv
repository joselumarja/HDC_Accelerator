`timescale 1ns/1ps

module serdes_tb;

    parameter WORD_WIDTH  = 32;
    parameter FIFO_WIDTH = 8;
    parameter DEPTH     = 16;
    parameter SEGMENTS  = WORD_WIDTH / FIFO_WIDTH;
    parameter ADDR_WIDTH = $clog2(DEPTH);

    reg clk, rst, serializer_start, deserializer_start;
    wire serializer_busy, serializer_done, deserializer_busy, deserializer_done;

    reg [WORD_WIDTH-1:0] data_in;
    wire [WORD_WIDTH-1:0] data_out;
    wire [FIFO_WIDTH-1:0] fifo_din, fifo_dout;
    wire wr_en, rd_en;
    wire [ADDR_WIDTH:0] size;
    wire full, empty;

    fifo #(
        .DATA_WIDTH(FIFO_WIDTH),
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
        .IN_WIDTH(WORD_WIDTH),
        .OUT_WIDTH(FIFO_WIDTH)
    ) serializer_dut (
        .clk(clk),
        .rst(rst),
        .start(serializer_start),
        .data_in(data_in),
        .busy(serializer_busy),
        .done(serializer_done),
        .fifo_din(fifo_din),
        .wr_en(wr_en),
        .fifo_full(full)
    );

    deserializer #(
        .IN_WIDTH(FIFO_WIDTH),
        .OUT_WIDTH(WORD_WIDTH)
    ) deserializer_dut (
        .clk(clk),
        .rst(rst),
        .start(deserializer_start),
        .data_out(data_out),
        .busy(deserializer_busy),
        .done(deserializer_done),
        .fifo_dout(fifo_dout),
        .rd_en(rd_en),
        .fifo_empty(empty)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 0;
        serializer_start = 0;
        deserializer_start = 0;

        data_in = 32'hA1B2C3D4;

        #10 serializer_start = 1;
        #10 serializer_start = 0;

        wait(serializer_done);

        $display("\n--- SERIALIZER TEST COMPLETADO ---\n");

        #10 deserializer_start = 1;
        #10 deserializer_start = 0;

        wait(deserializer_done);
        
        #20

        $display("\n--- DESERIALIZER TEST COMPLETADO ---");
        
        $display("\n--- SERDES SIMULTANEO ---");
        
        data_in = 32'hA5B6C7D8;
        rst = 1;
        
        #10
        
        rst = 0;
        
        #10
        
        serializer_start = 1;
        deserializer_start = 1;
        
        #10
        
        serializer_start = 0;
        deserializer_start = 0;
        
        wait(deserializer_done);
        
        $display("\n--- SERDES SIMULTANEO COMPLETADO ---");
        
        #15
        
        $stop;
    end

endmodule