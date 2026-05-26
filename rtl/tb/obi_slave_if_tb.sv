`timescale 1ns/1ps

module obi_slave_if_tb;

    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;

    // Direcciones de registros
    localparam logic [ADDR_WIDTH-1:0] ADDR_ADDR_A        = 32'h00;
    localparam logic [ADDR_WIDTH-1:0] ADDR_ADDR_B        = 32'h04;
    localparam logic [ADDR_WIDTH-1:0] ADDR_ADDR_C        = 32'h08;
    localparam logic [ADDR_WIDTH-1:0] ADDR_VECTOR_A_SIZE = 32'h0C;
    localparam logic [ADDR_WIDTH-1:0] ADDR_VECTOR_B_SIZE = 32'h10;
    localparam logic [ADDR_WIDTH-1:0] ADDR_VECTOR_C_SIZE = 32'h14;
    localparam logic [ADDR_WIDTH-1:0] ADDR_SEL_OP        = 32'h18;
    localparam logic [ADDR_WIDTH-1:0] ADDR_START         = 32'h1C;
    localparam logic [ADDR_WIDTH-1:0] ADDR_DONE          = 32'h20;
    localparam logic [ADDR_WIDTH-1:0] ADDR_INVALID       = 32'h24;

    // Estados internos esperados
    localparam logic [1:0] ST_IDLE        = 2'd0;
    localparam logic [1:0] ST_START_PULSE = 2'd1;
    localparam logic [1:0] ST_RUNNING     = 2'd2;
    localparam logic [1:0] ST_DONE        = 2'd3;

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

    logic [ADDR_WIDTH-1:0] addr_A;
    logic [ADDR_WIDTH-1:0] addr_B;
    logic [ADDR_WIDTH-1:0] addr_C;
    logic [ADDR_WIDTH-1:0] vector_A_size;
    logic [ADDR_WIDTH-1:0] vector_B_size;
    logic [ADDR_WIDTH-1:0] vector_C_size;
    logic [1:0] sel_op;

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
        .sel_op(sel_op)
    );

    // ------------------------------------------------------------
    // Reset
    // ------------------------------------------------------------
    task automatic reset_dut();
        begin
            rst       = 1'b1;
            obi_req   = 1'b0;
            obi_we    = 1'b0;
            obi_addr  = '0;
            obi_wdata = '0;
            done_in   = 1'b0;

            repeat (4) @(posedge clk);
            rst = 1'b0;
            repeat (2) @(posedge clk);

            assert(addr_A == 0)
                else $error("addr_A debería inicializarse a 0");

            assert(addr_B == 0)
                else $error("addr_B debería inicializarse a 0");

            assert(addr_C == 0)
                else $error("addr_C debería inicializarse a 0");

            assert(vector_A_size == 0)
                else $error("vector_A_size debería inicializarse a 0");

            assert(vector_B_size == 0)
                else $error("vector_B_size debería inicializarse a 0");

            assert(vector_C_size == 0)
                else $error("vector_C_size debería inicializarse a 0");

            assert(sel_op == 0)
                else $error("sel_op debería inicializarse a 0");
        end
    endtask

    // ------------------------------------------------------------
    // Escritura OBI
    // ------------------------------------------------------------
    task automatic obi_write(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH-1:0] data
    );
        begin
            @(negedge clk);
            obi_addr  = addr;
            obi_wdata = data;
            obi_we    = 1'b1;
            obi_req   = 1'b1;

            @(posedge clk);
            #1;

            assert(obi_gnt == 1'b1)
                else $error("WRITE: obi_gnt no se activó. addr=%h", addr);

            @(negedge clk);
            obi_req   = 1'b0;
            obi_we    = 1'b0;
            obi_addr  = '0;
            obi_wdata = '0;

            @(posedge clk);
            #1;
        end
    endtask

    // ------------------------------------------------------------
    // Lectura OBI
    // ------------------------------------------------------------
    task automatic obi_read(
        input  logic [ADDR_WIDTH-1:0] addr,
        output logic [DATA_WIDTH-1:0] data
    );
        begin
            @(negedge clk);
            obi_addr  = addr;
            obi_wdata = '0;
            obi_we    = 1'b0;
            obi_req   = 1'b1;

            @(posedge clk);
            #1;

            assert(obi_gnt == 1'b1)
                else $error("READ: obi_gnt no se activó. addr=%h", addr);

            assert(obi_rvalid == 1'b1)
                else $error("READ: obi_rvalid no se activó. addr=%h", addr);

            data = obi_rdata;

            @(negedge clk);
            obi_req  = 1'b0;
            obi_addr = '0;

            @(posedge clk);
            #1;
        end
    endtask

    // ------------------------------------------------------------
    // Lectura con comprobación
    // ------------------------------------------------------------
    task automatic obi_read_check(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH-1:0] expected
    );
        logic [DATA_WIDTH-1:0] data;
        begin
            obi_read(addr, data);

            assert(data == expected)
                else $error("READ CHECK: addr=%h expected=%h got=%h",
                            addr, expected, data);
        end
    endtask

    // ------------------------------------------------------------
    // Test principal
    // ------------------------------------------------------------
    initial begin
        $display("\n--- TEST UNITARIO obi_slave_if ---\n");

        reset_dut();

        // --------------------------------------------------------
        // Escritura de registros
        // --------------------------------------------------------
        $display("Escribiendo registros...");

        obi_write(ADDR_ADDR_A,        32'hA000_0000);
        obi_write(ADDR_ADDR_B,        32'hB000_0000);
        obi_write(ADDR_ADDR_C,        32'hC000_0000);
        obi_write(ADDR_VECTOR_A_SIZE, 32'd64);
        obi_write(ADDR_VECTOR_B_SIZE, 32'd64);
        obi_write(ADDR_VECTOR_C_SIZE, 32'd64);
        obi_write(ADDR_SEL_OP,        32'd0);

        // --------------------------------------------------------
        // Comprobación directa de salidas
        // --------------------------------------------------------
        assert(addr_A == 32'hA000_0000)
            else $error("addr_A incorrecto");

        assert(addr_B == 32'hB000_0000)
            else $error("addr_B incorrecto");

        assert(addr_C == 32'hC000_0000)
            else $error("addr_C incorrecto");

        assert(vector_A_size == 32'd64)
            else $error("vector_A_size incorrecto");

        assert(vector_B_size == 32'd64)
            else $error("vector_B_size incorrecto");

        assert(vector_C_size == 32'd64)
            else $error("vector_C_size incorrecto");

        assert(sel_op == 2'd0)
            else $error("sel_op incorrecto");

        // --------------------------------------------------------
        // Lectura de registros
        // --------------------------------------------------------
        $display("Leyendo registros...");

        obi_read_check(ADDR_ADDR_A,        32'hA000_0000);
        obi_read_check(ADDR_ADDR_B,        32'hB000_0000);
        obi_read_check(ADDR_ADDR_C,        32'hC000_0000);
        obi_read_check(ADDR_VECTOR_A_SIZE, 32'd64);
        obi_read_check(ADDR_VECTOR_B_SIZE, 32'd64);
        obi_read_check(ADDR_VECTOR_C_SIZE, 32'd64);
        obi_read_check(ADDR_SEL_OP,        32'd0);

        // --------------------------------------------------------
        // Dirección inválida
        // --------------------------------------------------------
        obi_read_check(ADDR_INVALID, 32'hDEAD_BEEF);

        // --------------------------------------------------------
        // Escritura START
        // --------------------------------------------------------
        $display("Escribiendo START...");

        obi_write(ADDR_START, 32'd1);

        // Al volver de obi_write, ya estamos justo después del ciclo
        // en el que la FSM ha entrado en START_PULSE.

        assert(start_out == 1'b1)
            else $error("start_out debería estar activo en START_PULSE");

        @(posedge clk);
        #1;

        assert(start_out == 1'b0)
            else $error("start_out debería durar solo un ciclo");

        @(posedge clk);
        #1;

        assert(start_out == 1'b0)
            else $error("start_out debería durar solo un ciclo");

        // --------------------------------------------------------
        // Señal done_in
        // --------------------------------------------------------
        $display("Activando done_in...");

        repeat (5) @(posedge clk);

        @(negedge clk);
        done_in = 1'b1;

        @(posedge clk);
        #1;

        @(negedge clk);
        done_in = 1'b0;

        @(posedge clk);
        #1;

        obi_read_check(ADDR_DONE, 32'h0000_0001);

        $display("addr_A          = %h", addr_A);
        $display("addr_B          = %h", addr_B);
        $display("addr_C          = %h", addr_C);
        $display("vector_A_size   = %d", vector_A_size);
        $display("vector_B_size   = %d", vector_B_size);
        $display("vector_C_size   = %d", vector_C_size);
        $display("sel_op          = %d", sel_op);

        $display("\n--- TEST FINALIZADO CORRECTAMENTE ---\n");

        #20;
        $finish;
    end

endmodule