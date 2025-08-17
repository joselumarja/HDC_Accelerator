`timescale 1ns/1ps

module deserializer_tb;

    parameter IN_WIDTH  = 32;
    parameter OUT_WIDTH = 8;
    parameter DEPTH     = 16;
    parameter SEGMENTS  = IN_WIDTH / OUT_WIDTH;
    parameter ADDR_WIDTH = $clog2(DEPTH);

    reg clk, rst, start;
    wire busy, done;

    wire [IN_WIDTH-1:0] data_out;
    reg [OUT_WIDTH-1:0] fifo_din = 0;
    reg wr_en = 0;
    reg  [OUT_WIDTH-1:0] fifo_dout;
    wire rd_en;
    wire [ADDR_WIDTH:0] size;
    wire full, empty;

    // FIFO con datos predefinidos
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

    deserializer #(
        .IN_WIDTH(IN_WIDTH),
        .OUT_WIDTH(OUT_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .data_out(data_out),
        .busy(busy),
        .done(done),
        .fifo_dout(fifo_dout),
        .rd_en(rd_en),
        .fifo_empty(empty)
    );

    always #5 clk = ~clk;

    integer i;
    
    initial begin
        clk = 0;
        rst = 0;
        start = 0;
        
        $display("\n--- ESCRIBIENDO DATOS ---");
        // Escribir hasta que esté llena
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(posedge clk);
            if (!full) begin
                wr_en = 1;
                fifo_din = i;
                #2
                $display("Write: %d", fifo_din);
                $display("Size: %d", size);
            end
        end
        wr_en = 0;

        @(posedge clk);
        $display("Size: %d", size);
        $display("FULL = %b (esperado: 1)", full);

        #10 start = 1;

        wait(done);

        $display("\n--- DESERIALIZER TEST COMPLETADO ---");
        $display("Resultado: %h", data_out);
        $stop;
    end

endmodule
