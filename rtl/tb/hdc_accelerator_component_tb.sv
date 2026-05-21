`timescale 1ns/1ps

module hdc_accelerator_component_tb;

    // Parámetros
    parameter DATA_WIDTH = 8;
    parameter DEPTH = 16;
    parameter ADDR_WIDTH = $clog2(DEPTH);
    
    //Señales generales
    reg ap_clk, ap_rst, ap_start;
    wire ap_done, ap_ready, ap_idle;
    reg [31:0] vector_size;
    reg [1:0] sel_op;

    // Señales FIFO A
    reg fifo_A_wr_en;
    wire fifo_A_rd_en;
    reg [DATA_WIDTH-1:0] fifo_A_din;
    wire [DATA_WIDTH-1:0] fifo_A_dout;
    wire [ADDR_WIDTH:0] fifo_A_size;
    wire fifo_A_full;
    wire fifo_A_empty;

    // Señales FIFO B
    reg fifo_B_wr_en;
    wire fifo_B_rd_en;
    reg [DATA_WIDTH-1:0] fifo_B_din;
    wire [DATA_WIDTH-1:0] fifo_B_dout;
    wire [ADDR_WIDTH:0] fifo_B_size;
    wire fifo_B_full;
    wire fifo_B_empty;

    // Señales FIFO C
    wire fifo_C_wr_en;
    reg fifo_C_rd_en;
    wire [DATA_WIDTH-1:0] fifo_C_din;
    wire [DATA_WIDTH-1:0] fifo_C_dout;
    wire [ADDR_WIDTH:0] fifo_C_size;
    wire fifo_C_full;
    wire fifo_C_empty;


    // Alias para el componente
    wire fifo_A_empty_n = ~fifo_A_empty;
    wire fifo_B_empty_n = ~fifo_B_empty;
    wire fifo_C_full_n  = ~fifo_C_full;

    // Generación de reloj
    always #5 ap_clk = ~ap_clk;

    // FIFO A
    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) fifo_A (
        .clk(ap_clk),
        .rst(ap_rst),
        .wr_en(fifo_A_wr_en),
        .rd_en(fifo_A_rd_en),
        .din(fifo_A_din),
        .dout(fifo_A_dout),
        .size(fifo_A_size),
        .full(fifo_A_full),
        .empty(fifo_A_empty)
    );

    // FIFO B
    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) fifo_B (
        .clk(ap_clk),
        .rst(ap_rst),
        .wr_en(fifo_B_wr_en),
        .rd_en(fifo_B_rd_en),
        .din(fifo_B_din),
        .dout(fifo_B_dout),
        .size(fifo_B_size),
        .full(fifo_B_full),
        .empty(fifo_B_empty)
    );

    // FIFO C
    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) fifo_C (
        .clk(ap_clk),
        .rst(ap_rst),
        .wr_en(fifo_C_wr_en),
        .rd_en(fifo_C_rd_en),
        .din(fifo_C_din),
        .dout(fifo_C_dout),
        .size(fifo_C_size),
        .full(fifo_C_full),
        .empty(fifo_C_empty)
    );


    // Instancia del componente HLS
    hdc_accelerator_component dut (
        .vector_size(vector_size),
        .sel_op(sel_op),
        .fifo_A_dout(fifo_A_dout),
        .fifo_A_empty_n(fifo_A_empty_n),
        .fifo_A_read(fifo_A_rd_en),
        .fifo_B_dout(fifo_B_dout),
        .fifo_B_empty_n(fifo_B_empty_n),
        .fifo_B_read(fifo_B_rd_en),
        .fifo_C_din(fifo_C_din),
        .fifo_C_full_n(fifo_C_full_n),
        .fifo_C_write(fifo_C_wr_en),
        .ap_clk(ap_clk),
        .ap_rst(ap_rst),
        .ap_start(ap_start),
        .ap_done(ap_done),
        .ap_ready(ap_ready),
        .ap_idle(ap_idle)
    );

    // Variables auxiliares
    integer i;

    // Inicialización y prueba
    initial begin
        // Reset inicial
        ap_clk = 0;
        ap_rst = 1;
        ap_start = 0;
        fifo_A_wr_en = 0;
        fifo_B_wr_en = 0;
        fifo_C_rd_en = 0;
        fifo_A_din = 0;
        fifo_B_din = 0;
        vector_size = 16;
        sel_op = 2'b11; // Cambia según la operación deseada

        #20;
        ap_rst = 0;

        // Precargar las FIFOs A y B con datos de prueba
        for (i = 0; i < vector_size; i = i + 1) begin
            @(posedge ap_clk);
            fifo_A_wr_en = 1;
            fifo_B_wr_en = 1;
            fifo_A_din = 8'hFF;
            if(i%2 == 0)
                fifo_B_din = 8'h00;
            else
                fifo_B_din = 8'hFF;
        end
        
        @(posedge ap_clk)
        fifo_A_wr_en = 0;
        fifo_B_wr_en = 0;

        @(posedge ap_clk);
        ap_start = 1;
        
        @(posedge ap_clk);
        ap_start = 0;

        // Esperar a que termine
        wait (ap_done);
        
        fifo_C_rd_en = 1;

        $display("---- RESULTADOS EN FIFO C ----");
        for (i = 0; i < vector_size; i = i + 1) begin
            @(posedge ap_clk);
            $display("Read: %d", fifo_C_dout);
        end
        
        fifo_C_rd_en = 0;

        $display("---- TEST FINALIZADO ----");
        
        #20;
        
        $display("---- TEST PRECARGA INCOMPLETA ----");
        
        @(posedge ap_clk);
        ap_rst = 1;
        
        @(posedge ap_clk)
        ap_rst = 0;
        
        for (i = 0; i < vector_size/2; i = i + 1) begin
            @(posedge ap_clk);
            fifo_A_wr_en = 1;
            fifo_B_wr_en = 1;
            fifo_A_din = 8'hFF;
            if(i%2 == 0)
                fifo_B_din = 8'h00;
            else
                fifo_B_din = 8'hFF;
        end
        
        @(posedge ap_clk);
        ap_start = 1;
        fifo_A_wr_en = 0;
        fifo_B_wr_en = 0;
        
        @(posedge ap_clk);
        ap_start = 0;
        
        #150
        
        for (i = 0; i < vector_size/2; i = i + 1) begin
            @(posedge ap_clk);
            fifo_A_wr_en <= 1;
            fifo_B_wr_en <= 1;
            fifo_A_din = 8'hFF;
            if(i%2 == 0)
                fifo_B_din = 8'h00;
            else
                fifo_B_din = 8'hFF;
        end
        
        @(posedge ap_clk)
        fifo_A_wr_en <= 0;
        fifo_B_wr_en <= 0;
        
        wait (ap_done);
        
        #20
        
        $stop;
    end

endmodule
