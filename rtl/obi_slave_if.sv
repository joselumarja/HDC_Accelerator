module obi_slave_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  logic                  clk,
    input  logic                  rst,

    // Señales OBI esclavo
    input  logic                  obi_req,
    input  logic                  obi_we,
    input  logic [ADDR_WIDTH-1:0] obi_addr,
    input  logic [DATA_WIDTH-1:0] obi_wdata,
    output logic [DATA_WIDTH-1:0] obi_rdata,
    output logic                  obi_gnt,
    output logic                  obi_rvalid,

    // Señales de salida a otros componentes
    output logic                  start_out,
    input  logic                  done_in,

    // Registros configurados
    output logic [ADDR_WIDTH-1:0] addr_A,
    output logic [ADDR_WIDTH-1:0] addr_B,
    output logic [ADDR_WIDTH-1:0] addr_C,
    output logic [ADDR_WIDTH-1:0] vector_A_size,
    output logic [ADDR_WIDTH-1:0] vector_B_size,
    output logic [ADDR_WIDTH-1:0] vector_C_size,
    output logic [1:0]            sel_op
);

    // Direcciones de los registros
    localparam logic [ADDR_WIDTH-1:0] ADDR_ADDR_A        = 32'h00;
    localparam logic [ADDR_WIDTH-1:0] ADDR_ADDR_B        = 32'h04;
    localparam logic [ADDR_WIDTH-1:0] ADDR_ADDR_C        = 32'h08;
    localparam logic [ADDR_WIDTH-1:0] ADDR_VECTOR_A_SIZE = 32'h0C;
    localparam logic [ADDR_WIDTH-1:0] ADDR_VECTOR_B_SIZE = 32'h10;
    localparam logic [ADDR_WIDTH-1:0] ADDR_VECTOR_C_SIZE = 32'h14;
    localparam logic [ADDR_WIDTH-1:0] ADDR_SEL_OP        = 32'h18;
    localparam logic [ADDR_WIDTH-1:0] ADDR_START         = 32'h1C;
    localparam logic [ADDR_WIDTH-1:0] ADDR_DONE          = 32'h20;

    localparam logic [ADDR_WIDTH-1:0] ADDR_MASK          = 32'h000000FF;

    typedef enum logic [1:0] {
        IDLE,
        START_PULSE,
        RUNNING,
        DONE
    } state_t;

    state_t state, next_state;

    logic start;
    logic done;

    logic [ADDR_WIDTH-1:0] addr;
    logic obi_accept;

    assign addr = obi_addr & ADDR_MASK;

    assign done      = (state == DONE);
    assign start_out = (state == START_PULSE);

    // ------------------------------------------------------------
    // OBI request accept
    // ------------------------------------------------------------
    // Esclavo siempre listo: gnt solo está alto mientras req está alto.
    assign obi_gnt = obi_req;

    // Handshake válido de aceptación de petición.
    assign obi_accept = obi_req && obi_gnt;

    // ------------------------------------------------------------
    // FSM de control start/done
    // ------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always_comb begin
        next_state = state;

        unique case (state)

            IDLE: begin
                if (start) begin
                    next_state = START_PULSE;
                end
            end

            START_PULSE: begin
                next_state = RUNNING;
            end

            RUNNING: begin
                if (done_in) begin
                    next_state = DONE;
                end
            end

            DONE: begin
                if (start) begin
                    next_state = START_PULSE;
                end
            end

            default: begin
                next_state = IDLE;
            end

        endcase
    end

    // ------------------------------------------------------------
    // Escritura de registros
    // ------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst) begin
            addr_A        <= '0;
            addr_B        <= '0;
            addr_C        <= '0;
            vector_A_size <= '0;
            vector_B_size <= '0;
            vector_C_size <= '0;
            sel_op        <= '0;
            start         <= 1'b0;
        end else begin
            // start es un pulso interno de un ciclo
            start <= 1'b0;

            if (obi_accept && obi_we) begin
                unique case (addr)

                    ADDR_ADDR_A: begin
                        addr_A <= obi_wdata;
                    end

                    ADDR_ADDR_B: begin
                        addr_B <= obi_wdata;
                    end

                    ADDR_ADDR_C: begin
                        addr_C <= obi_wdata;
                    end

                    ADDR_VECTOR_A_SIZE: begin
                        vector_A_size <= obi_wdata;
                    end

                    ADDR_VECTOR_B_SIZE: begin
                        vector_B_size <= obi_wdata;
                    end

                    ADDR_VECTOR_C_SIZE: begin
                        vector_C_size <= obi_wdata;
                    end

                    ADDR_SEL_OP: begin
                        sel_op <= obi_wdata[1:0];
                    end

                    ADDR_START: begin
                        start <= obi_wdata[0];
                    end

                    default: begin
                        // Dirección no implementada. No modificar registros.
                    end

                endcase
            end
        end
    end

    // ------------------------------------------------------------
    // Lectura de registros con respuesta registrada
    // ------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst) begin
            obi_rvalid <= 1'b0;
            obi_rdata  <= '0;
        end else begin
            obi_rvalid <= 1'b0;

            if (obi_accept) begin
                obi_rvalid <= 1'b1;

                if(!obi_we) begin
                    unique case (addr)

                        ADDR_ADDR_A: begin
                            obi_rdata <= addr_A;
                        end

                        ADDR_ADDR_B: begin
                            obi_rdata <= addr_B;
                        end

                        ADDR_ADDR_C: begin
                            obi_rdata <= addr_C;
                        end

                        ADDR_VECTOR_A_SIZE: begin
                            obi_rdata <= vector_A_size;
                        end

                        ADDR_VECTOR_B_SIZE: begin
                            obi_rdata <= vector_B_size;
                        end

                        ADDR_VECTOR_C_SIZE: begin
                            obi_rdata <= vector_C_size;
                        end

                        ADDR_SEL_OP: begin
                            obi_rdata <= {{(DATA_WIDTH-2){1'b0}}, sel_op};
                        end

                        ADDR_START: begin
                            obi_rdata <= '0;
                        end

                        ADDR_DONE: begin
                            obi_rdata <= {{(DATA_WIDTH-1){1'b0}}, done};
                        end

                        default: begin
                            obi_rdata <= 32'hDEAD_BEEF;
                        end

                    endcase
                end
            end
        end
    end

endmodule
