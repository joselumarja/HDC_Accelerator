`timescale 1ns/1ps

module obi_slave_if_tb;

    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;

    // Señales del DUT
    logic clk = 0;
    logic rst;

    logic obi_req;
    logic obi_we;
    logic [ADDR_WIDTH-1:0] obi_addr;
    logic [DATA_WIDTH-1:0] obi_wdata;
    logic [DATA_WIDTH-1:0] obi_rdata;
    logic obi_gnt;
    logic obi_rvalid;

    logic start_out;
    logic done_in;

    logic [ADDR_WIDTH-1:0] addr_A, addr_B, addr_C, vector_A_size, vector_B_size, vector_C_size;
    logic [1:0] sel_op;
    
    reg [1:0] state_debug;

    // Reloj
    always #5 clk = ~clk;

    // Instancia del DUT
    obi_slave_if #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .obi_req(obi_req),
        .obi_we(obi_we),
        .obi_addr(obi_addr),
        .obi_wdata(obi_wdata),
        .obi_rdata(obi_rdata),
        .obi_gnt(obi_gnt),
        .obi_rvalid(obi_rvalid),
        .start_out(start_out),
        .done_in(done_in),
        .addr_A(addr_A),
        .addr_B(addr_B),
        .addr_C(addr_C),
        .vector_A_size(vector_A_size),
        .vector_B_size(vector_B_size),
        .vector_C_size(vector_C_size),
        .sel_op(sel_op),
        .state_debug(state_debug)
    );

    // Tareas de escritura y lectura OBI
    task obi_write(input [31:0] addr, input [31:0] data);
        begin
            @(posedge clk);
            obi_addr <= addr;
            obi_wdata <= data;
            obi_we <= 1;
            obi_req <= 1;
            @(posedge clk);
            wait(obi_gnt);
            obi_req <= 0;
            obi_we <= 0;
        end
    endtask

    task obi_read(input [31:0] addr);
        begin
            @(posedge clk);
            obi_addr <= addr;
            obi_we <= 0;
            obi_req <= 1;
            @(posedge clk);
            wait(obi_gnt);
            obi_req <= 0;
        end
    endtask

    // Simulación
    initial begin
        // Inicialización
        rst = 1;
        obi_req = 0;
        obi_we = 0;
        obi_addr = 0;
        obi_wdata = 0;
        done_in = 0;
        
        #10
        
        @(posedge clk);
        rst = 0;

        // Escribir valores en registros
        obi_write(32'h00, 32'hA0000000); // addr_A
        obi_write(32'h04, 32'hB0000000); // addr_B
        obi_write(32'h08, 32'hC0000000); // addr_C
        obi_write(32'h0C, 32'd64);       // vector_A_size
        obi_write(32'h10, 32'd64);       // vector_B_size
        obi_write(32'h14, 32'd64);       // vector_C_size
        obi_write(32'h18, 32'd0);        // sel_op

        // Escribir en start
        obi_write(32'h1C, 32'd1);        // start = 1

        // Esperar un ciclo y observar start_out
        @(posedge clk);
        $display("Start_out = %b (esperado: 1)", start_out);

        // Simular que el componente termina
        repeat (5) @(posedge clk); // espera algunos ciclos
        done_in = 1;
        @(posedge clk);
        done_in = 0;

        // Leer el estado done
        obi_read(32'h1C); // dirección del registro done
        @(posedge clk);
        $display("Done leído = %b (esperado: 1)", obi_rdata[0]);

        // Verificación de valores almacenados
        $display("addr_A        = %h", addr_A);
        $display("addr_B        = %h", addr_B);
        $display("addr_C        = %h", addr_C);
        $display("vector_A_size   = %d", vector_A_size);
        $display("vector_B_size = %d", vector_B_size);
        $display("vector_C_size = %d", vector_C_size);
        $display("sel_op        = %d", sel_op);

        $finish;
    end

    // Simulación sencilla de respuesta OBI
    assign obi_gnt = obi_req;
    assign obi_rvalid = obi_req && !obi_we;

endmodule
