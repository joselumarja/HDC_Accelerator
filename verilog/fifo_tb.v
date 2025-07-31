`timescale 1ns/1ps

module fifo_tb;

    // Parámetros
    parameter DATA_WIDTH = 8;
    parameter DEPTH = 8;
    parameter ADDR_WIDTH = $clog2(DEPTH);

    // Señales de entrada
    reg clk;
    reg rst;
    reg wr_en;
    reg rd_en;
    reg [DATA_WIDTH-1:0] din;

    // Señales de salida
    wire [DATA_WIDTH-1:0] dout;
    wire [ADDR_WIDTH:0] size;
    wire full;
    wire empty;

    // Instancia de la FIFO
    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .din(din),
        .dout(dout),
        .size(size),
        .full(full),
        .empty(empty)
    );

    // Reloj
    always #5 clk = ~clk;

    // Variables internas
    integer i;

    initial begin
        // Inicialización
        clk = 0;
        rst = 1;
        wr_en = 0;
        rd_en = 0;
        din = 0;

        #20;
        rst = 0;

        $display("\n--- ESCRIBIENDO DATOS ---");
        // Escribir hasta que esté llena
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(posedge clk);
            if (!full) begin
                wr_en = 1;
                din = i;
                #2
                $display("Write: %d", din);
                $display("Size: %d", size);
            end
        end
        wr_en = 0;

        @(posedge clk);
        $display("Size: %d", size);
        $display("FULL = %b (esperado: 1)", full);

        #10;

        $display("\n--- LEYENDO DATOS ---");
        // Leer hasta que esté vacía
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(posedge clk);
            if (!empty) begin
                rd_en = 1;
                #2
                $display("Read: %d", dout);
                $display("Size: %d", size);
            end
        end
        rd_en = 0;

        @(posedge clk);
        $display("Size: %d", size);
        $display("EMPTY = %b (esperado: 1)", empty);

        $display("\n--- TEST COMPLETADO ---");
        $stop;
    end

endmodule
