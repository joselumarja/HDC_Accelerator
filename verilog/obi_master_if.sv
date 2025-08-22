module obi_master_if #(
    parameter ADDR_WIDTH,
    parameter DATA_WIDTH
)(
    input  logic                  clk,
    input  logic                  rst,

    // Señales de control desde FSM
    input  logic                  start,         // Señal para iniciar una transacción
    input  logic                  rw,            // 0 = read, 1 = write
    input  logic [ADDR_WIDTH-1:0] addr,
    input  logic [DATA_WIDTH-1:0] wdata,
    output logic [DATA_WIDTH-1:0] rdata,
    output logic                  done,          // Operación finalizada
    output logic                  busy,          // Operación en curso

    // Interfaz OBI maestro
    output logic                  mst_obi_req_o,
    output logic                  mst_obi_we_o,
    output logic [ADDR_WIDTH-1:0] mst_obi_addr_o,
    output logic [DATA_WIDTH-1:0] mst_obi_wdata_o,
    output logic [DATA_WIDTH/8-1:0] mst_obi_be_o,
    input  logic                  mst_obi_gnt_i,
    input  logic [DATA_WIDTH-1:0] mst_obi_rdata_i,
    input  logic                  mst_obi_rvalid_i
);

    typedef enum logic [2:0] {
        IDLE,
        LOAD,
        REQUEST,
        WAIT_RVALID,
        DONE
    } state_t;

    state_t state, next_state;

    // Señales internas
    logic [DATA_WIDTH-1:0] rdata_reg;
    logic transaction_in_progress;
    logic rw_reg;
    logic [ADDR_WIDTH-1:0] addr_reg;
    logic [DATA_WIDTH-1:0] wdata_reg;

    assign rdata = rdata_reg;
    assign busy  = transaction_in_progress;
    assign done  = (state == DONE);
    
    always_ff @(posedge clk) begin
        if (rst) state <= IDLE;
        else     state <= next_state;
    end

    // Secuencia principal
    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            rdata_reg <= '0;
        end else begin
            case(state)
                LOAD: begin
                    rw_reg <= rw;
                    addr_reg <= addr;
                    wdata_reg <= wdata;
                end
                WAIT_RVALID: begin
                    if (mst_obi_rvalid_i)
                        rdata_reg <= mst_obi_rdata_i;
                end
            endcase
        end
    end

    // FSM de control
    always_comb begin
        next_state = state;
        transaction_in_progress = 1'b1;

        // Por defecto
        mst_obi_req_o   = 1'b0;
        mst_obi_we_o    = rw_reg;
        mst_obi_addr_o  = addr_reg;
        mst_obi_wdata_o = wdata_reg;
        mst_obi_be_o    = {DATA_WIDTH/8{1'b1}};

        case (state)
            IDLE: begin
                transaction_in_progress = 1'b0;
                if (start)
                    next_state = LOAD;
            end
            
            LOAD:
                next_state = REQUEST;

            REQUEST: begin
                mst_obi_req_o = 1'b1;
                if (mst_obi_gnt_i)
                    next_state = (rw == 1'b0) ? WAIT_RVALID : DONE;
            end

            WAIT_RVALID: begin
                mst_obi_req_o = 1'b1;
                if (mst_obi_rvalid_i)
                    next_state = DONE;
            end

            DONE: begin
                mst_obi_req_o = 1'b0;
                next_state = IDLE;
            end
        endcase
    end

endmodule
