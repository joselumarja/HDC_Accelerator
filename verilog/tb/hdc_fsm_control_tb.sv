`timescale 1ns/1ps

module hdc_fsm_control_tb;

    // Parámetros
    parameter FIFO_DEPTH = 16;
    parameter DATA_WIDTH  = 32;
    parameter ADDR_WIDTH  = 32;
    parameter FIFO_DATA_WIDTH = 8;
    parameter FIFO_ADDR_WIDTH = $clog2(FIFO_DEPTH);
    
    //Señales generales
    reg clk, rst;
    
    // Señales FSM
    reg start;
    reg [ADDR_WIDTH-1:0] addr_A, addr_B, addr_C;
    reg [ADDR_WIDTH-1:0] vector_size, vector_B_size;
    wire busy, done;
    
    // Señales Master OBI simulado
    wire obi_transference_start;
    wire obi_transference_rw;
    wire [ADDR_WIDTH-1:0] obi_transference_addr;
    wire [DATA_WIDTH-1:0] obi_transference_wdata;
    wire [DATA_WIDTH-1:0] obi_transference_rdata;
    wire obi_transference_done;
    wire obi_transference_busy;

    // Señales FIFO A
    wire fifo_A_wr_en;
    wire fifo_A_rd_en;
    wire [FIFO_DATA_WIDTH-1:0] fifo_A_din;
    wire [FIFO_DATA_WIDTH-1:0] fifo_A_dout;
    wire [FIFO_ADDR_WIDTH:0] fifo_A_size;
    wire fifo_A_full;
    wire fifo_A_empty;
    
    //Señales Serializador A
    reg serializer_A_start;
    wire serializer_A_busy;
    wire serializer_A_done;
    reg [DATA_WIDTH-1:0] data_A_in;

    // Señales FIFO B
    wire fifo_B_wr_en;
    wire fifo_B_rd_en;
    wire [FIFO_DATA_WIDTH-1:0] fifo_B_din;
    wire [FIFO_DATA_WIDTH-1:0] fifo_B_dout;
    wire [FIFO_ADDR_WIDTH:0] fifo_B_size;
    wire fifo_B_full;
    wire fifo_B_empty;
    
    //Señales Serializador B
    reg serializer_B_start;
    wire serializer_B_busy;
    wire serializer_B_done;
    reg [DATA_WIDTH-1:0] data_B_in;

    // Señales FIFO C
    wire fifo_C_wr_en;
    wire fifo_C_rd_en;
    wire [FIFO_DATA_WIDTH-1:0] fifo_C_din;
    wire [FIFO_DATA_WIDTH-1:0] fifo_C_dout;
    wire [FIFO_ADDR_WIDTH:0] fifo_C_size;
    wire fifo_C_full;
    wire fifo_C_empty;
    
    //Señales Deserializador C
    reg deserializer_C_start;
    wire deserializer_C_busy;
    wire deserializer_C_done;
    wire [DATA_WIDTH-1:0] data_C_out;

    //Señales del componente HLS
    //reg ap_start;
    wire ap_done, ap_ready, ap_idle;
    reg [31:0] component_iterations;
    reg [1:0] sel_op;

    // Alias para el componente
    wire fifo_A_empty_n = ~fifo_A_empty;
    wire fifo_B_empty_n = ~fifo_B_empty;
    wire fifo_C_full_n  = ~fifo_C_full;
    
   
    //debug
    wire [3:0] state_debug;
    wire [2:0] fifo_debug;
    wire [2:0] vector_finish_debug;
    
    // Generación de reloj
    always #5 clk = ~clk;
    
    //FSM
    hdc_fsm_control #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) dut (
        .clk(clk),
        .rst(rst),
    
        .start(start),
        .addr_A(addr_A),
        .addr_B(addr_B),
        .addr_C(addr_C),
        .vector_size(vector_size),
        .vector_B_size(vector_B_size),
        .busy(busy),
        .done(done),
    
        .obi_transference_start(obi_transference_start),
        .obi_transference_rw(obi_transference_rw),
        .obi_transference_addr(obi_transference_addr),
        .obi_transference_wdata(obi_transference_wdata),
        .obi_transference_rdata(obi_transference_rdata),
        .obi_transference_done(obi_transference_done),
        .obi_transference_busy(obi_transference_busy),
    
        .fifo_A_size(fifo_A_size),
        .fifo_B_size(fifo_B_size),
        .fifo_C_size(fifo_C_size),
    
        .serializer_A_start(serializer_A_start),
        .serializer_A_data_in(data_A_in),
        .serializer_A_busy(serializer_A_busy),
        .serializer_A_done(serializer_A_done),
    
        .serializer_B_start(serializer_B_start),
        .serializer_B_data_in(data_B_in),
        .serializer_B_busy(serializer_B_busy),
        .serializer_B_done(serializer_B_done),
    
        .deserializer_C_start(deserializer_C_start),
        .deserializer_C_data_out(data_C_out),
        .deserializer_C_busy(deserializer_C_busy),
        .deserializer_C_done(deserializer_C_done),
    
        .state_debug(state_debug),
        .fifo_debug(fifo_debug),
        .vector_finish_debug(vector_finish_debug)
    );


    // OBI Master
    obi_master_simulated_if #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) obi_master_if (
        .clk(clk),
        .rst(rst),
        .start(obi_transference_start),
        .rw(obi_transference_rw),
        .addr(obi_transference_addr),
        .wdata(obi_transference_wdata),
        .rdata(obi_transference_rdata),
        .done(obi_transference_done),
        .busy(obi_transference_busy)
    );

    // FIFO A
    fifo #(
        .DATA_WIDTH(FIFO_DATA_WIDTH),
        .DEPTH(FIFO_DEPTH)
    ) fifo_A (
        .clk(clk),
        .rst(rst),
        .wr_en(fifo_A_wr_en),
        .rd_en(fifo_A_rd_en),
        .din(fifo_A_din),
        .dout(fifo_A_dout),
        .size(fifo_A_size),
        .full(fifo_A_full),
        .empty(fifo_A_empty)
    );
    
    serializer #(
        .IN_WIDTH(DATA_WIDTH),
        .OUT_WIDTH(FIFO_DATA_WIDTH)
    ) serializer_A_dut (
        .clk(clk),
        .rst(rst),
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
        .DATA_WIDTH(FIFO_DATA_WIDTH),
        .DEPTH(FIFO_DEPTH)
    ) fifo_B (
        .clk(clk),
        .rst(rst),
        .wr_en(fifo_B_wr_en),
        .rd_en(fifo_B_rd_en),
        .din(fifo_B_din),
        .dout(fifo_B_dout),
        .size(fifo_B_size),
        .full(fifo_B_full),
        .empty(fifo_B_empty)
    );
    
    serializer #(
        .IN_WIDTH(DATA_WIDTH),
        .OUT_WIDTH(FIFO_DATA_WIDTH)
    ) serializer_B_dut (
        .clk(clk),
        .rst(rst),
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
        .DATA_WIDTH(FIFO_DATA_WIDTH),
        .DEPTH(FIFO_DEPTH)
    ) fifo_C (
        .clk(clk),
        .rst(rst),
        .wr_en(fifo_C_wr_en),
        .rd_en(fifo_C_rd_en),
        .din(fifo_C_din),
        .dout(fifo_C_dout),
        .size(fifo_C_size),
        .full(fifo_C_full),
        .empty(fifo_C_empty)
    );

    deserializer #(
        .IN_WIDTH(FIFO_DATA_WIDTH),
        .OUT_WIDTH(DATA_WIDTH)
    ) deserializer_C_dut (
        .clk(clk),
        .rst(rst),
        .start(deserializer_C_start),
        .data_out(data_C_out),
        .busy(deserializer_C_busy),
        .done(deserializer_C_done),
        .fifo_dout(fifo_C_dout),
        .rd_en(fifo_C_rd_en),
        .fifo_empty(fifo_C_empty)
    );


    // Instancia del componente HLS
    hdc_accelerator_component hls_component_dut (
        .vector_size(component_iterations),
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
        .ap_clk(clk),
        .ap_rst(rst),
        .ap_start(start),
        .ap_done(ap_done),
        .ap_ready(ap_ready),
        .ap_idle(ap_idle)
    );
    
    // Variables auxiliares
    integer i;

    // Inicialización y prueba
    initial begin
        // Reset inicial
        clk = 0;
        rst = 1;
        start = 0;
        vector_size = 64;
        vector_B_size = vector_size;
        sel_op = 2'b00; // Cambia según la operación deseada
        
        addr_A = 32'h0000_0000;
        addr_B = 32'h0000_0100;
        addr_C = 32'h0000_0200;
        
        component_iterations = vector_size / FIFO_DATA_WIDTH;

        #20;
        rst = 0;
        
        start = 1;

        @(posedge clk)
        
        start = 0;
        
        wait(done)
        
        #10
        
        $stop;
    end

endmodule