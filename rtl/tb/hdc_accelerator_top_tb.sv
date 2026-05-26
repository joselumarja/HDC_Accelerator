`timescale 1ns/1ps

module hdc_accelerator_top_tb;

    // ------------------------------------------------------------
    // Parámetros
    // ------------------------------------------------------------
    localparam int ADDR_WIDTH       = 32;
    localparam int DATA_WIDTH       = 32;
    localparam int FIFO_DEPTH       = 32;
    localparam int FIFO_DATA_WIDTH  = 8;
    localparam int MEM_WORDS        = 1024;
    localparam int READ_LATENCY     = 2;

    // Registros de la interfaz esclava
    localparam logic [ADDR_WIDTH-1:0] REG_ADDR_A        = 32'h00;
    localparam logic [ADDR_WIDTH-1:0] REG_ADDR_B        = 32'h04;
    localparam logic [ADDR_WIDTH-1:0] REG_ADDR_C        = 32'h08;
    localparam logic [ADDR_WIDTH-1:0] REG_VECTOR_A_SIZE = 32'h0C;
    localparam logic [ADDR_WIDTH-1:0] REG_VECTOR_B_SIZE = 32'h10;
    localparam logic [ADDR_WIDTH-1:0] REG_VECTOR_C_SIZE = 32'h14;
    localparam logic [ADDR_WIDTH-1:0] REG_SEL_OP        = 32'h18;
    localparam logic [ADDR_WIDTH-1:0] REG_START         = 32'h1C;
    localparam logic [ADDR_WIDTH-1:0] REG_DONE          = 32'h20;

    // Direcciones base en memoria externa simulada
    localparam logic [ADDR_WIDTH-1:0] BASE_A = 32'h0000_0000;
    localparam logic [ADDR_WIDTH-1:0] BASE_B = 32'h0000_0100;
    localparam logic [ADDR_WIDTH-1:0] BASE_C = 32'h0000_0200;

    // Número de palabras de 32 bits que queremos mover
    localparam int NUM_WORDS = 4;

    // Ojo: tu FSM incrementa los contadores con DATA_WIDTH.
    // Por eso usamos NUM_WORDS * DATA_WIDTH.
    localparam logic [ADDR_WIDTH-1:0] VECTOR_SIZE = NUM_WORDS * DATA_WIDTH;

    // ------------------------------------------------------------
    // Señales generales
    // ------------------------------------------------------------
    logic clk;
    logic rst_n;

    // ------------------------------------------------------------
    // Interfaz OBI esclava
    // ------------------------------------------------------------
    logic                  slv_obi_req_i;
    logic                  slv_obi_we_i;
    logic [ADDR_WIDTH-1:0] slv_obi_addr_i;
    logic [DATA_WIDTH-1:0] slv_obi_wdata_i;
    logic [DATA_WIDTH-1:0] slv_obi_rdata_o;
    logic                  slv_obi_gnt_o;
    logic                  slv_obi_rvalid_o;

    // ------------------------------------------------------------
    // Interfaz OBI maestra
    // ------------------------------------------------------------
    logic                  mst_obi_req_o;
    logic                  mst_obi_we_o;
    logic [ADDR_WIDTH-1:0] mst_obi_addr_o;
    logic [DATA_WIDTH-1:0] mst_obi_wdata_o;
    logic [DATA_WIDTH/8-1:0] mst_obi_be_o;
    logic                  mst_obi_gnt_i;
    logic [DATA_WIDTH-1:0] mst_obi_rdata_i;
    logic                  mst_obi_rvalid_i;

    logic master_req_seen;

    // ------------------------------------------------------------
    // Memoria externa simulada
    // ------------------------------------------------------------
    logic [DATA_WIDTH-1:0] mem [0:MEM_WORDS-1];

    int master_read_A_count;
    int master_read_B_count;
    int master_write_C_count;
    int master_other_count;

    // ------------------------------------------------------------
    // Reloj
    // ------------------------------------------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------
    hdc_accelerator_top #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH),
        .FIFO_DATA_WIDTH(FIFO_DATA_WIDTH)
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

    // ------------------------------------------------------------
    // Función de dirección de palabra
    // ------------------------------------------------------------
    function automatic int word_index(input logic [ADDR_WIDTH-1:0] byte_addr);
        word_index = byte_addr[ADDR_WIDTH-1:2];
    endfunction

    // ------------------------------------------------------------
    // Inicialización de memoria externa
    // ------------------------------------------------------------
    task automatic init_memory();
        int i;
        begin
            for (i = 0; i < MEM_WORDS; i++) begin
                mem[i] = 32'h0000_0000;
            end

            // Región A
            mem[word_index(BASE_A) + 0] = 32'h0403_0201;
            mem[word_index(BASE_A) + 1] = 32'h0807_0605;
            mem[word_index(BASE_A) + 2] = 32'h0C0B_0A09;
            mem[word_index(BASE_A) + 3] = 32'h100F_0E0D;

            // Región B
            mem[word_index(BASE_B) + 0] = 32'h1413_1211;
            mem[word_index(BASE_B) + 1] = 32'h1817_1615;
            mem[word_index(BASE_B) + 2] = 32'h1C1B_1A19;
            mem[word_index(BASE_B) + 3] = 32'h201F_1E1D;

            // Región C inicialmente limpia
            for (i = 0; i < NUM_WORDS; i++) begin
                mem[word_index(BASE_C) + i] = 32'h0000_0000;
            end
        end
    endtask

    // ------------------------------------------------------------
    // Reset
    // ------------------------------------------------------------
    task automatic reset_dut();
        begin
            rst_n = 1'b0;

            slv_obi_req_i   = 1'b0;
            slv_obi_we_i    = 1'b0;
            slv_obi_addr_i  = '0;
            slv_obi_wdata_i = '0;

            mst_obi_gnt_i    = 1'b0;
            mst_obi_rdata_i  = '0;
            mst_obi_rvalid_i = 1'b0;

            master_read_A_count  = 0;
            master_read_B_count  = 0;
            master_write_C_count = 0;
            master_other_count   = 0;

            repeat (6) @(posedge clk);
            rst_n = 1'b1;
            repeat (4) @(posedge clk);
        end
    endtask

    // ------------------------------------------------------------
    // Escritura por OBI esclavo
    // ------------------------------------------------------------
    task automatic slave_write(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH-1:0] data
    );
        begin
            @(negedge clk);
            slv_obi_addr_i  = addr;
            slv_obi_wdata_i = data;
            slv_obi_we_i    = 1'b1;
            slv_obi_req_i   = 1'b1;

            @(posedge clk);
            #1;

            assert(slv_obi_gnt_o == 1'b1)
                else $error("SLAVE WRITE: gnt no activo. addr=%h", addr);

            @(negedge clk);
            slv_obi_req_i   = 1'b0;
            slv_obi_we_i    = 1'b0;
            slv_obi_addr_i  = '0;
            slv_obi_wdata_i = '0;

            @(posedge clk);
            #1;
        end
    endtask

    // ------------------------------------------------------------
    // Lectura por OBI esclavo
    // ------------------------------------------------------------
    task automatic slave_read(
        input  logic [ADDR_WIDTH-1:0] addr,
        output logic [DATA_WIDTH-1:0] data
    );
        begin
            @(negedge clk);
            slv_obi_addr_i  = addr;
            slv_obi_wdata_i = '0;
            slv_obi_we_i    = 1'b0;
            slv_obi_req_i   = 1'b1;

            @(posedge clk);
            #1;

            assert(slv_obi_gnt_o == 1'b1)
                else $error("SLAVE READ: gnt no activo. addr=%h", addr);

            assert(slv_obi_rvalid_o == 1'b1)
                else $error("SLAVE READ: rvalid no activo. addr=%h", addr);

            data = slv_obi_rdata_o;

            @(negedge clk);
            slv_obi_req_i  = 1'b0;
            slv_obi_addr_i = '0;

            @(posedge clk);
            #1;
        end
    endtask

    // ------------------------------------------------------------
    // Configuración del acelerador mediante OBI esclavo
    // ------------------------------------------------------------
    task automatic configure_accelerator();
        begin
            slave_write(REG_ADDR_A,        BASE_A);
            slave_write(REG_ADDR_B,        BASE_B);
            slave_write(REG_ADDR_C,        BASE_C);
            slave_write(REG_VECTOR_A_SIZE, VECTOR_SIZE);
            slave_write(REG_VECTOR_B_SIZE, VECTOR_SIZE);
            slave_write(REG_VECTOR_C_SIZE, VECTOR_SIZE);

            // Ajusta sel_op según la operación real del componente HLS.
            // Para la integración básica solo comprobamos movimiento y finalización.
            slave_write(REG_SEL_OP,        32'd0);
        end
    endtask

    // ------------------------------------------------------------
    // Modelo de memoria para la interfaz OBI maestra
    // ------------------------------------------------------------
    typedef enum logic [1:0] {
        MEM_IDLE,
        MEM_WAIT_READ,
        MEM_RVALID
    } mem_state_t;

    mem_state_t mem_state;

    logic [ADDR_WIDTH-1:0] pending_read_addr;
    int read_wait_counter;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mst_obi_gnt_i    <= 1'b0;
            mst_obi_rvalid_i <= 1'b0;
            mst_obi_rdata_i  <= '0;
            master_req_seen  <= 1'b0;
            mem_state        <= MEM_IDLE;
        end else begin
            mst_obi_gnt_i    <= 1'b0;
            mst_obi_rvalid_i <= 1'b0;

            if (!mst_obi_req_o) begin
                master_req_seen <= 1'b0;
            end

            case (mem_state)

                MEM_IDLE: begin
                    if (mst_obi_req_o && !master_req_seen) begin
                        master_req_seen <= 1'b1;
                        mst_obi_gnt_i   <= 1'b1;

                        if (mst_obi_we_o) begin
                            mem[word_index(mst_obi_addr_o)] <= mst_obi_wdata_o;

                            $display("[%0t] MASTER WRITE addr=%h data=%h",
                                    $time, mst_obi_addr_o, mst_obi_wdata_o);

                            if (mst_obi_addr_o >= BASE_C &&
                                mst_obi_addr_o < BASE_C + NUM_WORDS * (DATA_WIDTH/8)) begin
                                master_write_C_count <= master_write_C_count + 1;
                            end else begin
                                master_other_count <= master_other_count + 1;
                                $error("MASTER WRITE fuera de región C: addr=%h data=%h",
                                    mst_obi_addr_o, mst_obi_wdata_o);
                            end

                        end else begin
                            pending_read_addr <= mst_obi_addr_o;
                            read_wait_counter <= 0;
                            mem_state         <= MEM_WAIT_READ;

                            $display("[%0t] MASTER READ REQ addr=%h",
                                    $time, mst_obi_addr_o);

                            if (mst_obi_addr_o >= BASE_A &&
                                mst_obi_addr_o < BASE_A + NUM_WORDS * (DATA_WIDTH/8)) begin
                                master_read_A_count <= master_read_A_count + 1;
                            end else if (mst_obi_addr_o >= BASE_B &&
                                        mst_obi_addr_o < BASE_B + NUM_WORDS * (DATA_WIDTH/8)) begin
                                master_read_B_count <= master_read_B_count + 1;
                            end else begin
                                master_other_count <= master_other_count + 1;
                                $error("MASTER READ fuera de regiones A/B: addr=%h", mst_obi_addr_o);
                            end
                        end
                    end
                end

                MEM_WAIT_READ: begin
                    if (read_wait_counter == READ_LATENCY - 1) begin
                        mst_obi_rdata_i  <= mem[word_index(pending_read_addr)];
                        mst_obi_rvalid_i <= 1'b1;
                        mem_state        <= MEM_RVALID;

                        $display("[%0t] MASTER READ RVALID addr=%h data=%h",
                                $time,
                                pending_read_addr,
                                mem[word_index(pending_read_addr)]);
                    end else begin
                        read_wait_counter <= read_wait_counter + 1;
                    end
                end

                MEM_RVALID: begin
                    mem_state <= MEM_IDLE;
                end
            endcase
        end
    end

    // ------------------------------------------------------------
    // Comprobar región C
    // ------------------------------------------------------------
    task automatic check_output_region();
        int i;
        bit any_non_zero;
        begin
            any_non_zero = 1'b0;

            $display("Contenido final de región C:");

            for (i = 0; i < NUM_WORDS; i++) begin
                $display("C[%0d] @ %h = %h",
                         i,
                         BASE_C + i * (DATA_WIDTH/8),
                         mem[word_index(BASE_C) + i]);

                if (mem[word_index(BASE_C) + i] != 32'h0000_0000) begin
                    any_non_zero = 1'b1;
                end
            end

            assert(master_write_C_count > 0)
                else $error("No se produjo ninguna escritura en región C");

            // Esta comprobación depende de la operación real del HLS.
            // Si la salida esperada puede ser cero, puedes comentar este assert.
            assert(any_non_zero)
                else $warning("La región C sigue a cero. Puede ser correcto si la operación HLS produce cero.");
        end
    endtask

    // ------------------------------------------------------------
    // Test principal
    // ------------------------------------------------------------
    initial begin
        logic [DATA_WIDTH-1:0] done_reg;

        $display("\n--- TEST INTEGRACIÓN hdc_accelerator_top ---\n");

        init_memory();
        reset_dut();

        configure_accelerator();

        $display("Lanzando acelerador...");
        slave_write(REG_START, 32'd1);

        #1000;

        slave_read(REG_DONE, done_reg);

        assert(done_reg[0] == 1'b1)
            else $error("El registro DONE leído por OBI esclavo no vale 1");

        $display("Resumen de transacciones:");
        $display("  Lecturas A:    %0d", master_read_A_count);
        $display("  Lecturas B:    %0d", master_read_B_count);
        $display("  Escrituras C:  %0d", master_write_C_count);
        $display("  Otras:         %0d", master_other_count);

        assert(master_read_A_count > 0)
            else $error("No se detectaron lecturas desde la región A");

        assert(master_read_B_count > 0)
            else $error("No se detectaron lecturas desde la región B");

        assert(master_write_C_count > 0)
            else $error("No se detectaron escrituras hacia la región C");

        assert(master_other_count == 0)
            else $error("Se detectaron accesos fuera de las regiones esperadas");

        check_output_region();

        $display("\n--- TEST DE INTEGRACIÓN FINALIZADO ---\n");

        #50;
        $finish;
    end

endmodule