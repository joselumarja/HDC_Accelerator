// Testbench para hdc_accelerator_top

`timescale 1ns / 1ps

module hdc_accelerator_tb;

    // Parámetros del DUT
    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;
    parameter FIFO_DEPTH = 32;
    parameter FIFO_DATA_WIDTH = 8;
    parameter FIFO_ADDR_WIDTH = $clog2(FIFO_DEPTH);
    parameter READ_THRESHOLD = 4;

    // Señales
    logic clk;
    logic rst_n;

    // Slave OBI
    logic                  slv_obi_req_i;
    logic                  slv_obi_we_i;
    logic [ADDR_WIDTH-1:0] slv_obi_addr_i;
    logic [DATA_WIDTH-1:0] slv_obi_wdata_i;
    logic [DATA_WIDTH-1:0] slv_obi_rdata_o;
    logic                  slv_obi_gnt_o;
    logic                  slv_obi_rvalid_o;

    // Master OBI
    logic                  mst_obi_req_o;
    logic                  mst_obi_we_o;
    logic [ADDR_WIDTH-1:0] mst_obi_addr_o;
    logic [DATA_WIDTH-1:0] mst_obi_wdata_o;
    logic [DATA_WIDTH/8-1:0] mst_obi_be_o;
    logic                  mst_obi_gnt_i;
    logic [DATA_WIDTH-1:0] mst_obi_rdata_i;
    logic                  mst_obi_rvalid_i;

    // Memoria simulada
    localparam MEM_DEPTH = 16;
    logic [DATA_WIDTH-1:0] memory [0:MEM_DEPTH-1];

    // Clock
    always #5 clk = ~clk;

    // Instancia del DUT
    hdc_accelerator_top #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH),
        .FIFO_DATA_WIDTH(FIFO_DATA_WIDTH),
        .FIFO_ADDR_WIDTH(FIFO_ADDR_WIDTH),
        .READ_THRESHOLD(READ_THRESHOLD)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),

        .slv_obi_req_i(slv_obi_req_i),
        .slv_obi_we_i(slv_obi_we_i),
        .slv_obi_addr_i(slv_obi_addr_i),
        .slv_obi_wdata_i(slv_obi_wdata_i),
        .slv_obi_rdata_o(slv_obi_rdata_o),
        .slv_obi_gnt_o(slv_obi_gnt_o),
        .slv_obi_rvalid_o(slv_obi_rvalid_o),

        .mst_obi_req_o(mst_obi_req_o),
        .mst_obi_we_o(mst_obi_we_o),
        .mst_obi_addr_o(mst_obi_addr_o),
        .mst_obi_wdata_o(mst_obi_wdata_o),
        .mst_obi_be_o(mst_obi_be_o),
        .mst_obi_gnt_i(mst_obi_gnt_i),
        .mst_obi_rdata_i(mst_obi_rdata_i),
        .mst_obi_rvalid_i(mst_obi_rvalid_i)
    );

    // Tareas de escritura y lectura OBI slave
    task automatic write_reg(input logic [ADDR_WIDTH-1:0] addr, input logic [DATA_WIDTH-1:0] data);
        begin
            slv_obi_addr_i  = addr;
            slv_obi_wdata_i = data;
            slv_obi_req_i   = 1;
            slv_obi_we_i    = 1;
            @(posedge clk);
            wait(slv_obi_gnt_o);
            slv_obi_req_i   = 0;
            slv_obi_we_i    = 0;
        end
    endtask

    // Interfaz maestro OBI hacia memoria simulada
    always_ff @(posedge clk) begin
        if (mst_obi_req_o) begin
            mst_obi_gnt_i <= 1;
            if (mst_obi_we_o) begin
                memory[mst_obi_addr_o[ADDR_WIDTH-1:2]] <= mst_obi_wdata_o;
                //memory[mst_obi_addr_o[ADDR_WIDTH-1:0]] <= mst_obi_wdata_o;
                mst_obi_rvalid_i <= 0;
            end else begin
                mst_obi_rdata_i <= memory[mst_obi_addr_o[ADDR_WIDTH-1:2]];
                //mst_obi_rdata_i <= memory[mst_obi_addr_o[ADDR_WIDTH-1:0]];
                mst_obi_rvalid_i <= 1;
            end
        end else begin
            mst_obi_gnt_i <= 0;
            mst_obi_rvalid_i <= 0;
        end
    end

    initial begin
        clk = 0;
        rst_n = 0;
        slv_obi_req_i = 0;
        slv_obi_we_i = 0;
        slv_obi_addr_i = 0;
        slv_obi_wdata_i = 0;
        mst_obi_gnt_i = 0;
        mst_obi_rdata_i = 0;
        mst_obi_rvalid_i = 0;

        // Inicialización de memoria
        for (int i = 0; i < MEM_DEPTH; i++) begin
            //memory[i] = 32'hFFFFFFFF;
            memory[i] = 0;
        end
        
        //Vector A
        memory[0] = 32'hABCDEEFF;
        memory[1] = 32'h4848ABCD;

        #20;
        rst_n = 1;

        // Configurar registros
        write_reg(32'h00000000, 32'h00000000); // addr_A
        write_reg(32'h00000004, 32'h0000000C); // addr_B
        write_reg(32'h00000008, 32'h00000010); // addr_C
        write_reg(32'h0000000C, 32'h00000040); // vector_size
        write_reg(32'h00000010, 32'h00000040); // vector_B_size
        write_reg(32'h00000014, 32'h00000001); // sel_op
        write_reg(32'h00000018, 32'h00000001); // start

        // Esperar a que done se active
        wait (dut.done);

        // Mostrar datos escritos en C
        $display("Resultado vector C:");
        for (int i = 0; i < MEM_DEPTH; i++) begin
            $display("C[%0d] = %h", i, memory[12'h30 + i]);
        end
        
        #10

        $finish;
    end

endmodule
