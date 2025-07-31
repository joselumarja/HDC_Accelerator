//NECESITA MUCHA MODIFICACION


module hdc_fsm_control #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter VECTOR_SIZE = 64,
    parameter READ_THRESHOLD = 4
)(
    input  logic                   clk,
    input  logic                   rst,
    input  logic                   start,
    input  logic [ADDR_WIDTH-1:0]  addr_A,
    input  logic [ADDR_WIDTH-1:0]  addr_B,
    input  logic [ADDR_WIDTH-1:0]  addr_C,
    input  logic [ADDR_WIDTH:0]    fifo_A_size,
    input  logic [ADDR_WIDTH:0]    fifo_B_size,

    // Señales a la FIFO A y B (escritura)
    output logic                   fifo_A_wr_en,
    output logic [DATA_WIDTH-1:0] fifo_A_din,
    output logic                   fifo_B_wr_en,
    output logic [DATA_WIDTH-1:0] fifo_B_din,

    // Señales desde FIFO C (lectura)
    input  logic                   fifo_C_empty,
    input  logic [DATA_WIDTH-1:0] fifo_C_dout,
    output logic                  fifo_C_rd_en,

    // Señales de estado
    output logic                  done,

    // Señales al maestro OBI
    output logic                  obi_start,
    output logic                  obi_rw,
    output logic [ADDR_WIDTH-1:0] obi_addr,
    output logic [DATA_WIDTH-1:0] obi_wdata,
    input  logic [DATA_WIDTH-1:0] obi_rdata,
    input  logic                  obi_done
);

    typedef enum logic [2:0] {
        IDLE,
        READ_A,
        WAIT_A,
        READ_B,
        WAIT_B,
        WRITE_C,
        WAIT_C,
        FINISHED
    } state_t;

    state_t state, next_state;
    logic [ADDR_WIDTH-1:0] counter;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            counter <= 0;
        end else begin
            state <= next_state;
            if ((state == WAIT_A || state == WAIT_B || state == WAIT_C) && obi_done)
                counter <= counter + 1;
        end
    end

    always_comb begin
        // Defaults
        fifo_A_wr_en = 0;
        fifo_A_din   = 0;
        fifo_B_wr_en = 0;
        fifo_B_din   = 0;
        fifo_C_rd_en = 0;
        obi_start    = 0;
        obi_rw       = 0;
        obi_addr     = 0;
        obi_wdata    = 0;
        done         = 0;

        next_state = state;

        case (state)
            IDLE: begin
                if (start && fifo_A_size < READ_THRESHOLD)
                    next_state = READ_A;
            end

            READ_A: begin
                obi_start = 1;
                obi_rw    = 0; // read
                obi_addr  = addr_A + counter * (DATA_WIDTH / 8);
                next_state = WAIT_A;
            end

            WAIT_A: begin
                if (obi_done) begin
                    fifo_A_wr_en = 1;
                    fifo_A_din   = obi_rdata;
                    if (counter + 1 < VECTOR_SIZE && fifo_A_size < READ_THRESHOLD)
                        next_state = READ_A;
                    else if (fifo_B_size < READ_THRESHOLD)
                        next_state = READ_B;
                    else
                        next_state = WAIT_B;
                end
            end

            READ_B: begin
                obi_start = 1;
                obi_rw    = 0; // read
                obi_addr  = addr_B + counter * (DATA_WIDTH / 8);
                next_state = WAIT_B;
            end

            WAIT_B: begin
                if (obi_done) begin
                    fifo_B_wr_en = 1;
                    fifo_B_din   = obi_rdata;
                    if (counter + 1 < VECTOR_SIZE && fifo_B_size < READ_THRESHOLD)
                        next_state = READ_B;
                    else
                        next_state = WRITE_C;
                end
            end

            WRITE_C: begin
                if (!fifo_C_empty) begin
                    obi_start = 1;
                    obi_rw    = 1; // write
                    obi_addr  = addr_C + counter * (DATA_WIDTH / 8);
                    obi_wdata = fifo_C_dout;
                    fifo_C_rd_en = 1;
                    next_state = WAIT_C;
                end else begin
                    next_state = FINISHED;
                end
            end

            WAIT_C: begin
                if (obi_done)
                    next_state = WRITE_C;
            end

            FINISHED: begin
                done = 1;
                next_state = IDLE;
            end
        endcase
    end

endmodule
