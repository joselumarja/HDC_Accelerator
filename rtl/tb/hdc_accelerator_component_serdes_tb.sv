`timescale 1ns/1ps

module hdc_accelerator_component_serdes_tb;

    // Parámetros
    parameter DEPTH = 16;
    parameter WORD_WIDTH  = 32;
    parameter FIFO_WIDTH = 8;
    parameter SEGMENTS  = WORD_WIDTH / FIFO_WIDTH;
    parameter ADDR_WIDTH = $clog2(DEPTH);
    
    //Señales generales
    reg ap_clk, ap_rst, ap_start;
    wire ap_done, ap_ready, ap_idle;
    reg [31:0] vector_size;
    reg [1:0] sel_op;

    // Señales FIFO A
    wire fifo_A_wr_en;
    wire fifo_A_rd_en;
    wire [FIFO_WIDTH-1:0] fifo_A_din;
    wire [FIFO_WIDTH-1:0] fifo_A_dout;
    wire [ADDR_WIDTH:0] fifo_A_size;
    wire fifo_A_full;
    wire fifo_A_empty;
    
    //Señales Serializador A
    reg serializer_A_start;
    wire serializer_A_busy;
    wire serializer_A_done;
    reg [WORD_WIDTH-1:0] data_A_in;

    // Señales FIFO B
    wire fifo_B_wr_en;
    wire fifo_B_rd_en;
    wire [FIFO_WIDTH-1:0] fifo_B_din;
    wire [FIFO_WIDTH-1:0] fifo_B_dout;
    wire [ADDR_WIDTH:0] fifo_B_size;
    wire fifo_B_full;
    wire fifo_B_empty;
    
    //Señales Serializador B
    reg serializer_B_start;
    wire serializer_B_busy;
    wire serializer_B_done;
    reg [WORD_WIDTH-1:0] data_B_in;

    // Señales FIFO C
    wire fifo_C_wr_en;
    wire fifo_C_rd_en;
    wire [FIFO_WIDTH-1:0] fifo_C_din;
    wire [FIFO_WIDTH-1:0] fifo_C_dout;
    wire [ADDR_WIDTH:0] fifo_C_size;
    wire fifo_C_full;
    wire fifo_C_empty;
    
    //Señales Deserializador C
    reg deserializer_C_start;
    wire deserializer_C_busy;
    wire deserializer_C_done;
    wire [WORD_WIDTH-1:0] data_C_out;


    // Alias para el componente
    wire fifo_A_empty_n = ~fifo_A_empty;
    wire fifo_B_empty_n = ~fifo_B_empty;
    wire fifo_C_full_n  = ~fifo_C_full;
    
    
    //debug
    wire [2:0] state;
    wire [$clog2(SEGMENTS):0] segment_cnt;

    // Generación de reloj
    always #5 ap_clk = ~ap_clk;

    // FIFO A
    fifo #(
        .DATA_WIDTH(FIFO_WIDTH),
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
    
    serializer #(
        .IN_WIDTH(WORD_WIDTH),
        .OUT_WIDTH(FIFO_WIDTH)
    ) serializer_A_dut (
        .clk(ap_clk),
        .rst(ap_rst),
        .start(serializer_A_start),
        .data_in(data_A_in),
        .busy(serializer_A_busy),
        .done(serializer_A_done),
        .fifo_din(fifo_A_din),
        .wr_en(fifo_A_wr_en),
        .fifo_full(fifo_A_full)
    );

    // FIFO B
    fifo #(
        .DATA_WIDTH(FIFO_WIDTH),
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
    
    serializer #(
        .IN_WIDTH(WORD_WIDTH),
        .OUT_WIDTH(FIFO_WIDTH)
    ) serializer_B_dut (
        .clk(ap_clk),
        .rst(ap_rst),
        .start(serializer_B_start),
        .data_in(data_B_in),
        .busy(serializer_B_busy),
        .done(serializer_B_done),
        .fifo_din(fifo_B_din),
        .wr_en(fifo_B_wr_en),
        .fifo_full(fifo_B_full)
    );

    // FIFO C
    fifo #(
        .DATA_WIDTH(FIFO_WIDTH),
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

    deserializer #(
        .IN_WIDTH(FIFO_WIDTH),
        .OUT_WIDTH(WORD_WIDTH)
    ) deserializer_C_dut (
        .clk(ap_clk),
        .rst(ap_rst),
        .start(deserializer_C_start),
        .data_out(data_C_out),
        .busy(deserializer_C_busy),
        .done(deserializer_C_done),
        .fifo_dout(fifo_C_dout),
        .rd_en(fifo_C_rd_en),
        .fifo_empty(fifo_C_empty),
        .state_debug(state),
        .segment_cnt_debug(segment_cnt)
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
        vector_size = 16;
        sel_op = 2'b00; // Cambia según la operación deseada

        #20;
        ap_rst = 0;
        
        serializer_A_start = 0;
        serializer_B_start = 0;
        deserializer_C_start = 0;

        data_A_in = 32'hA1B2C3D4;
        data_B_in = 32'h00000000;

        @(posedge ap_clk)
        
        serializer_A_start = 1;
        serializer_B_start = 1;
        
        @(posedge ap_clk) 
        
        serializer_A_start = 0;
        serializer_B_start = 0;

        wait(serializer_A_done);
        
        @(posedge ap_clk) 
        
        serializer_A_start = 1;
        serializer_B_start = 1;
        
        @(posedge ap_clk) 
        
        serializer_A_start = 0;
        serializer_B_start = 0;
        
        wait(serializer_A_done);
        
        @(posedge ap_clk) 
        
        serializer_A_start = 1;
        serializer_B_start = 1;
        
        @(posedge ap_clk) 
        
        serializer_A_start = 0;
        serializer_B_start = 0;

        wait(serializer_A_done);
        
        @(posedge ap_clk) 
        
        serializer_A_start = 1;
        serializer_B_start = 1;
        
        @(posedge ap_clk) 
        
        serializer_A_start = 0;
        serializer_B_start = 0;

        wait(serializer_A_done);
        
        ap_start = 1;
        
        @(posedge ap_clk)
        
        ap_start = 0;
        
        wait(ap_done);
        
        #10
        
        @(posedge ap_clk) 
        
        deserializer_C_start = 1;
        
        @(posedge ap_clk) 
        
        deserializer_C_start = 0;
        
        wait(deserializer_C_done);
        
        @(posedge ap_clk) 
        
        deserializer_C_start = 1;
        
        @(posedge ap_clk) 
        
        deserializer_C_start = 0;
        
        wait(deserializer_C_done);
        
        @(posedge ap_clk) 
        
        deserializer_C_start = 1;
        
        @(posedge ap_clk) 
        
        deserializer_C_start = 0;
        
        wait(deserializer_C_done);
        
        @(posedge ap_clk) 
        
        deserializer_C_start = 1;
        
        @(posedge ap_clk) 
        
        deserializer_C_start = 0;
        
        wait(deserializer_C_done);
        
        #10
        
        $stop;
    end

endmodule