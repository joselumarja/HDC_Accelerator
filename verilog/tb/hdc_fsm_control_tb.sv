`timescale 1ns/1ps

module hdc_fsm_control_tb;
    // ------------------------------------------------------------
    // Parámetros
    // ------------------------------------------------------------
    localparam int ADDR_WIDTH    = 32;
    localparam int DATA_WIDTH    = 32;
    localparam int FIFO_DEPTH    = 16;
    localparam int READ_THRESHOLD = 4;
    localparam int MEM_DEPTH     = 256;
    localparam int DELAY_CYCLES  = 2;
    localparam int NUM_TRANSFERS = 4;

    // Valores de estado según el orden del enum de hdc_fsm_control
    localparam logic [3:0] ST_IDLE            = 4'd0;
    localparam logic [3:0] ST_LOAD            = 4'd1;
    localparam logic [3:0] ST_CHECK_FIFO      = 4'd2;
    localparam logic [3:0] ST_RW_OBI          = 4'd3;
    localparam logic [3:0] ST_WAIT_OBI        = 4'd4;
    localparam logic [3:0] ST_REQUEST_SER_DES = 4'd5;
    localparam logic [3:0] ST_SER_DES         = 4'd6;
    localparam logic [3:0] ST_WAIT_DES        = 4'd7;
    localparam logic [3:0] ST_FINISHED        = 4'd8;

    // Identificadores de FIFO
    localparam logic [1:0] FIFO_A = 2'd0;
    localparam logic [1:0] FIFO_B = 2'd1;
    localparam logic [1:0] FIFO_C = 2'd2;

    // Direcciones de prueba
    localparam logic [ADDR_WIDTH-1:0] ADDR_A = 32'h0000_0000;
    localparam logic [ADDR_WIDTH-1:0] ADDR_B = 32'h0000_0004;
    localparam logic [ADDR_WIDTH-1:0] ADDR_C = 32'h0000_0008;

    // Datos de prueba
    localparam logic [DATA_WIDTH-1:0] DATA_A = 32'hAAAA_0001;
    localparam logic [DATA_WIDTH-1:0] DATA_B = 32'hBBBB_0002;
    localparam logic [DATA_WIDTH-1:0] DATA_C = 32'hCCCC_0003;

    // ------------------------------------------------------------
    // Señales generales
    // ------------------------------------------------------------
    logic clk;
    logic rst;

    logic start;
    logic [ADDR_WIDTH-1:0] addr_A;
    logic [ADDR_WIDTH-1:0] addr_B;
    logic [ADDR_WIDTH-1:0] addr_C;
    logic [ADDR_WIDTH-1:0] vector_A_size;
    logic [ADDR_WIDTH-1:0] vector_B_size;
    logic [ADDR_WIDTH-1:0] vector_C_size;
    logic busy;
    logic done;

    // ------------------------------------------------------------
    // Señales hacia OBI simulado
    // ------------------------------------------------------------
    logic                  obi_transference_start;
    logic                  obi_transference_rw;
    logic [ADDR_WIDTH-1:0] obi_transference_addr;
    logic [DATA_WIDTH-1:0] obi_transference_wdata;
    logic [DATA_WIDTH-1:0] obi_transference_rdata;
    logic                  obi_transference_done;
    logic                  obi_transference_busy;

    // ------------------------------------------------------------
    // Señales de tamaño de FIFO
    // ------------------------------------------------------------
    logic [$clog2(FIFO_DEPTH):0] fifo_A_size;
    logic [$clog2(FIFO_DEPTH):0] fifo_B_size;
    logic [$clog2(FIFO_DEPTH):0] fifo_C_size;

    // ------------------------------------------------------------
    // Árbitro round-robin simulado
    // ------------------------------------------------------------
    logic [2:0] fifo_data_movement_request;
    logic [1:0] rr_priority_base;
    logic [1:0] fifo_grant;

    // ------------------------------------------------------------
    // Serializadores simulados
    // ------------------------------------------------------------
    logic serializer_A_start;
    logic [DATA_WIDTH-1:0] serializer_A_data_in;
    logic serializer_A_busy;
    logic serializer_A_done;

    logic serializer_B_start;
    logic [DATA_WIDTH-1:0] serializer_B_data_in;
    logic serializer_B_busy;
    logic serializer_B_done;

    // ------------------------------------------------------------
    // Deserializador simulado
    // ------------------------------------------------------------
    logic deserializer_C_start;
    logic [DATA_WIDTH-1:0] deserializer_C_data_out;
    logic deserializer_C_busy;
    logic deserializer_C_done;

    // ------------------------------------------------------------
    // Debug
    // ------------------------------------------------------------
    logic [3:0] state_debug;
    logic [2:0] fifo_debug;
    logic [2:0] vector_finish_debug;

    // ------------------------------------------------------------
    // Contadores de comprobación
    // ------------------------------------------------------------
    int read_A_count;
    int read_B_count;
    int write_C_count;

    int serializer_A_start_count;
    int serializer_B_start_count;
    int deserializer_C_start_count;

    logic [1:0] pending_fifo;
    logic [ADDR_WIDTH-1:0] pending_addr;
    logic [DATA_WIDTH-1:0] pending_wdata;
    logic pending_rw;
    logic pending_valid;

    // ------------------------------------------------------------
    // Reloj
    // ------------------------------------------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // ------------------------------------------------------------
    // DUT: FSM principal
    // ------------------------------------------------------------
    hdc_fsm_control #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH),
        .READ_THRESHOLD(READ_THRESHOLD)
    ) dut (
        .clk(clk),
        .rst(rst),

        .start(start),
        .addr_A(addr_A),
        .addr_B(addr_B),
        .addr_C(addr_C),
        .vector_A_size(vector_A_size),
        .vector_B_size(vector_B_size),
        .vector_C_size(vector_C_size),
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

        .fifo_data_movement_request(fifo_data_movement_request),
        .rr_priority_base(rr_priority_base),
        .fifo_grant(fifo_grant),

        .serializer_A_start(serializer_A_start),
        .serializer_A_data_in(serializer_A_data_in),
        .serializer_A_busy(serializer_A_busy),
        .serializer_A_done(serializer_A_done),

        .serializer_B_start(serializer_B_start),
        .serializer_B_data_in(serializer_B_data_in),
        .serializer_B_busy(serializer_B_busy),
        .serializer_B_done(serializer_B_done),

        .deserializer_C_start(deserializer_C_start),
        .deserializer_C_data_out(deserializer_C_data_out),
        .deserializer_C_busy(deserializer_C_busy),
        .deserializer_C_done(deserializer_C_done),

        .state_debug(state_debug),
        .fifo_debug(fifo_debug),
        .vector_finish_debug(vector_finish_debug)
    );

    // ------------------------------------------------------------
    // Interfaz OBI simulada
    // ------------------------------------------------------------
    obi_master_simulated_if #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .MEM_DEPTH(MEM_DEPTH),
        .DELAY_CYCLES(DELAY_CYCLES)
    ) obi_if (
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

    // ------------------------------------------------------------
    // Árbitro round-robin simulado
    // ------------------------------------------------------------
    function automatic logic [1:0] rr_select(
        input logic [2:0] req,
        input logic [1:0] base
    );
        int k;
        int idx;
        begin
            rr_select = FIFO_A;

            for (k = 0; k < 3; k++) begin
                idx = (base + k) % 3;

                if (req[idx]) begin
                    rr_select = logic'(idx[1:0]);
                    return rr_select;
                end
            end
        end
    endfunction

    always_comb begin
        fifo_grant = rr_select(fifo_data_movement_request, rr_priority_base);
    end

    // ------------------------------------------------------------
    // Modelo simple de serializadores
    // ------------------------------------------------------------
    assign serializer_A_busy = 1'b0;
    assign serializer_B_busy = 1'b0;
    assign serializer_A_done = serializer_A_start;
    assign serializer_B_done = serializer_B_start;

    // ------------------------------------------------------------
    // Modelo simple de deserializador C
    // ------------------------------------------------------------
    assign deserializer_C_data_out = DATA_C;

    logic [1:0] des_cnt;
    logic       des_pending;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            deserializer_C_busy <= 1'b0;
            deserializer_C_done <= 1'b0;
            des_cnt             <= '0;
            des_pending         <= 1'b0;
        end else begin
            deserializer_C_done <= 1'b0;

            if (deserializer_C_start) begin
                deserializer_C_busy <= 1'b1;
                des_pending         <= 1'b1;
                des_cnt             <= 2'd1;
            end else if (des_pending) begin
                if (des_cnt == 0) begin
                    deserializer_C_done <= 1'b1;
                    deserializer_C_busy <= 1'b0;
                    des_pending         <= 1'b0;
                end else begin
                    des_cnt <= des_cnt - 1'b1;
                end
            end
        end
    end

    // ------------------------------------------------------------
    // Monitor de operaciones OBI finalizadas
    // ------------------------------------------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pending_fifo  <= FIFO_A;
            pending_addr  <= '0;
            pending_wdata <= '0;
            pending_rw    <= 1'b0;
            pending_valid <= 1'b0;

            read_A_count  <= 0;
            read_B_count  <= 0;
            write_C_count <= 0;
        end else begin

            // Captura de la transacción en el momento en que la FSM la lanza
            if (obi_transference_start) begin
                pending_fifo  <= fifo_debug[1:0];
                pending_addr  <= obi_transference_addr;
                pending_wdata <= obi_transference_wdata;
                pending_rw    <= obi_transference_rw;
                pending_valid <= 1'b1;

                $display("[%0t] OBI START: fifo=%0d rw=%0d addr=%h wdata=%h",
                        $time,
                        fifo_debug[1:0],
                        obi_transference_rw,
                        obi_transference_addr,
                        obi_transference_wdata);
            end

            // Comprobación cuando el módulo OBI simulado finaliza
            if (obi_transference_done) begin
                assert(pending_valid)
                    else $error("OBI DONE recibido sin transacción pendiente");

                $display("[%0t] OBI DONE : fifo=%0d rw=%0d addr=%h rdata=%h",
                        $time,
                        pending_fifo,
                        pending_rw,
                        pending_addr,
                        obi_transference_rdata);

                case (pending_fifo)

                    FIFO_A: begin
                        read_A_count <= read_A_count + 1;

                        assert(pending_rw == 1'b0)
                            else $error("FIFO A debería generar lectura OBI");

                        assert(pending_addr >= ADDR_A)
                            else $error("Dirección A por debajo de la base");

                        assert(((pending_addr - ADDR_A) % (DATA_WIDTH/8)) == 0)
                            else $error("Dirección A no alineada");
                    end

                    FIFO_B: begin
                        read_B_count <= read_B_count + 1;

                        assert(pending_rw == 1'b0)
                            else $error("FIFO B debería generar lectura OBI");

                        assert(pending_addr >= ADDR_B)
                            else $error("Dirección B por debajo de la base");

                        assert(((pending_addr - ADDR_B) % (DATA_WIDTH/8)) == 0)
                            else $error("Dirección B no alineada");
                    end

                    FIFO_C: begin
                        write_C_count <= write_C_count + 1;

                        assert(pending_rw == 1'b1)
                            else $error("FIFO C debería generar escritura OBI");

                        assert(pending_addr >= ADDR_C)
                            else $error("Dirección C por debajo de la base");

                        assert(((pending_addr - ADDR_C) % (DATA_WIDTH/8)) == 0)
                            else $error("Dirección C no alineada");
                    end

                    default: begin
                        $error("FIFO pendiente no válida: %0d", pending_fifo);
                    end
                endcase

                pending_valid <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------
    // Monitor de serializadores/deserializador
    // ------------------------------------------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            serializer_A_start_count   <= 0;
            serializer_B_start_count   <= 0;
            deserializer_C_start_count <= 0;
        end else begin

            if (serializer_A_start) begin
                serializer_A_start_count <= serializer_A_start_count + 1;

                $display("[%0t] SERIALIZER A START: data=%h",
                        $time,
                        serializer_A_data_in);
            end

            if (serializer_B_start) begin
                serializer_B_start_count <= serializer_B_start_count + 1;

                $display("[%0t] SERIALIZER B START: data=%h",
                        $time,
                        serializer_B_data_in);
            end

            if (deserializer_C_start) begin
                deserializer_C_start_count <= deserializer_C_start_count + 1;

                $display("[%0t] DESERIALIZER C START",
                        $time);
            end
        end
    end

    // ------------------------------------------------------------
    // Timeout
    // ------------------------------------------------------------
    task automatic wait_done_with_timeout(input int max_cycles);
        int c;
        begin
            c = 0;

            while (!done && c < max_cycles) begin
                @(posedge clk);
                c++;
            end

            if (!done) begin
                $fatal(1, "Timeout: la FSM no llegó a done en %0d ciclos", max_cycles);
            end
        end
    endtask

    // ------------------------------------------------------------
    // Reset
    // ------------------------------------------------------------
    task automatic reset_dut();
        begin
            rst   = 1'b1;
            start = 1'b0;

            addr_A = '0;
            addr_B = '0;
            addr_C = '0;

            vector_A_size = '0;
            vector_B_size = '0;
            vector_C_size = '0;

            fifo_A_size = '0;
            fifo_B_size = '0;
            fifo_C_size = '0;

            repeat (4) @(posedge clk);
            rst = 1'b0;
            repeat (2) @(posedge clk);

            assert(busy == 1'b0)
                else $error("Tras reset, busy debería estar a 0");

            assert(done == 1'b0)
                else $error("Tras reset, done debería estar a 0");
        end
    endtask

    // ------------------------------------------------------------
    // Load
    // ------------------------------------------------------------
    always_ff @(posedge clk) begin
    if (state_debug == ST_LOAD) begin
        $display("[%0t] LOAD INPUTS: addr_A=%h addr_B=%h addr_C=%h size_A=%0d size_B=%0d size_C=%0d",
                 $time,
                 addr_A,
                 addr_B,
                 addr_C,
                 vector_A_size,
                 vector_B_size,
                 vector_C_size);
    end

    if (state_debug == ST_CHECK_FIFO) begin
        $display("[%0t] CHECK_FIFO: req=%b grant=%0d rr_base=%0d finish=%b",
                 $time,
                 fifo_data_movement_request,
                 fifo_grant,
                 rr_priority_base,
                 vector_finish_debug);
    end
end

    // ------------------------------------------------------------
    // Test principal
    // ------------------------------------------------------------
    initial begin
        $display("\n--- TEST UNITARIO hdc_fsm_control ---\n");

        reset_dut();

        // Inicialización de memoria simulada OBI.
        // La memoria es word-addressable, por eso se usa addr[31:2].
        obi_if.mem[ADDR_A[ADDR_WIDTH-1:2] + 0] = 32'hAAAA_0001;
        obi_if.mem[ADDR_A[ADDR_WIDTH-1:2] + 1] = 32'hAAAA_0002;
        obi_if.mem[ADDR_A[ADDR_WIDTH-1:2] + 2] = 32'hAAAA_0003;
        obi_if.mem[ADDR_A[ADDR_WIDTH-1:2] + 3] = 32'hAAAA_0004;

        obi_if.mem[ADDR_B[ADDR_WIDTH-1:2] + 0] = 32'hBBBB_0001;
        obi_if.mem[ADDR_B[ADDR_WIDTH-1:2] + 1] = 32'hBBBB_0002;
        obi_if.mem[ADDR_B[ADDR_WIDTH-1:2] + 2] = 32'hBBBB_0003;
        obi_if.mem[ADDR_B[ADDR_WIDTH-1:2] + 3] = 32'hBBBB_0004;

        obi_if.mem[ADDR_C[ADDR_WIDTH-1:2] + 0] = 32'h0000_0000;
        obi_if.mem[ADDR_C[ADDR_WIDTH-1:2] + 1] = 32'h0000_0000;
        obi_if.mem[ADDR_C[ADDR_WIDTH-1:2] + 2] = 32'h0000_0000;
        obi_if.mem[ADDR_C[ADDR_WIDTH-1:2] + 3] = 32'h0000_0000;

        // La FSM incrementa counter[A/B/C] en DATA_WIDTH.
        // Por tanto, con vector_X_size = DATA_WIDTH se fuerza una única transferencia por vector.
        addr_A = ADDR_A;
        addr_B = ADDR_B;
        addr_C = ADDR_C;

        vector_A_size = NUM_TRANSFERS * DATA_WIDTH;
        vector_B_size = NUM_TRANSFERS * DATA_WIDTH;
        vector_C_size = NUM_TRANSFERS * DATA_WIDTH;

        // Forzamos que A y B pidan lectura:
        // fifo_A_size <= READ_THRESHOLD
        // fifo_B_size <= READ_THRESHOLD
        fifo_A_size = 0;
        fifo_B_size = 0;

        // Forzamos que C pida escritura:
        // fifo_C_size >= READ_THRESHOLD
        fifo_C_size = READ_THRESHOLD;

        @(negedge clk);
        start = 1'b1;

        @(negedge clk);
        start = 1'b0;

        wait_done_with_timeout(200);

        @(posedge clk);

        // --------------------------------------------------------
        // Comprobaciones finales
        // --------------------------------------------------------
        assert(read_A_count == NUM_TRANSFERS)
            else $error("Lecturas A incorrectas. Esperadas=%0d Obtenidas=%0d",
                        NUM_TRANSFERS, read_A_count);

        assert(read_B_count == NUM_TRANSFERS)
            else $error("Lecturas B incorrectas. Esperadas=%0d Obtenidas=%0d",
                        NUM_TRANSFERS, read_B_count);

        assert(write_C_count == NUM_TRANSFERS)
            else $error("Escrituras C incorrectas. Esperadas=%0d Obtenidas=%0d",
                        NUM_TRANSFERS, write_C_count);

        assert(serializer_A_start_count == 1)
            else $error("serializer_A_start debería activarse una vez, activaciones=%0d",
                        serializer_A_start_count);

        assert(serializer_B_start_count == 1)
            else $error("serializer_B_start debería activarse una vez, activaciones=%0d",
                        serializer_B_start_count);

        assert(deserializer_C_start_count == 1)
            else $error("deserializer_C_start debería activarse una vez, activaciones=%0d",
                        deserializer_C_start_count);

        assert(obi_if.mem[ADDR_C[ADDR_WIDTH-1:2]] == DATA_C)
            else $error("La memoria OBI no contiene el dato esperado en C. Esperado=%h Obtenido=%h",
                        DATA_C, obi_if.mem[ADDR_C[ADDR_WIDTH-1:2]]);

        assert(vector_finish_debug[0] == 1'b1)
            else $error("vector_finish_debug[A] debería estar activo");

        assert(vector_finish_debug[1] == 1'b1)
            else $error("vector_finish_debug[B] debería estar activo");

        assert(vector_finish_debug[2] == 1'b1)
            else $error("vector_finish_debug[C] debería estar activo");

        $display("Lecturas A:              %0d", read_A_count);
        $display("Lecturas B:              %0d", read_B_count);
        $display("Escrituras C:            %0d", write_C_count);
        $display("serializer_A_start:      %0d", serializer_A_start_count);
        $display("serializer_B_start:      %0d", serializer_B_start_count);
        $display("deserializer_C_start:    %0d", deserializer_C_start_count);
        $display("Memoria C final:         0x%08h", obi_if.mem[ADDR_C[ADDR_WIDTH-1:2]]);

        $display("\n--- TEST FINALIZADO CORRECTAMENTE ---\n");

        #20;
        $stop;
    end

endmodule