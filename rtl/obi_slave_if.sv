module obi_slave_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  wire                  clk,
    input  wire                  rst,

    // Señales OBI esclavo
    input  wire                  obi_req,
    input  wire                  obi_we,
    input  wire [ADDR_WIDTH-1:0] obi_addr,
    input  wire [DATA_WIDTH-1:0] obi_wdata,
    output reg  [DATA_WIDTH-1:0] obi_rdata,
    output reg                  obi_gnt,
    output reg                  obi_rvalid,

    // Señales de salida a otros componentes
    output wire                   start_out,
    input  wire                  done_in,

    // Registros configurados
    output reg [ADDR_WIDTH-1:0] addr_A,
    output reg [ADDR_WIDTH-1:0] addr_B,
    output reg [ADDR_WIDTH-1:0] addr_C,
    output reg [ADDR_WIDTH-1:0] vector_A_size,
    output reg [ADDR_WIDTH-1:0] vector_B_size,
    output reg [ADDR_WIDTH-1:0] vector_C_size,
    output reg [1:0]            sel_op,
    
    output wire [1:0] state_debug
);

    // Direcciones de los registros (puedes ajustarlas)
    localparam ADDR_ADDR_A          = 32'h00;
    localparam ADDR_ADDR_B          = 32'h04;
    localparam ADDR_ADDR_C          = 32'h08;
    localparam ADDR_VECTOR_A_SIZE   = 32'h0C;
    localparam ADDR_VECTOR_B_SIZE   = 32'h10;
    localparam ADDR_VECTOR_C_SIZE   = 32'h14;
    localparam ADDR_SEL_OP          = 32'h18;
    localparam ADDR_START           = 32'h1C;
    localparam ADDR_DONE            = 32'h20;
    
    // Peripheral address mask
    localparam ADDR_MASK = 32'h000000FF;

    // Señales internas
    typedef enum logic [1:0] {
        IDLE,
        START_PULSE,
        RUNNING,
        DONE
    } state_t;

    state_t state = IDLE, next_state = IDLE;
    
    logic start, done;
    
    wire [ADDR_WIDTH-1:0] addr;
    
    //debug
    assign state_debug = state;
    
    assign done = (state == DONE);
    assign start_out = (state == START_PULSE);
    
    assign addr = obi_addr & ADDR_MASK;
    
    //Actualizacion de estado
    always @(posedge clk) begin
        if (rst) state <= IDLE;
        else state <= next_state;
    end
    
    // FSM de control
    always @(*) begin
        next_state = state;

        case (state)
            IDLE:
                if(start)
                    next_state = START_PULSE;
            START_PULSE:
                next_state = RUNNING;

            RUNNING: begin
                if(done_in)
                    next_state = DONE;
            end
            DONE: begin
                if (start)
                    next_state = START_PULSE;
            end
        endcase
    end

    // Escritura de registros
    always @(posedge clk) begin
        if (rst) begin
            addr_A        <= 0;
            addr_B        <= 0;
            addr_C        <= 0;
            vector_A_size <= 0;
            vector_B_size <= 0;
            vector_C_size <= 0;
            sel_op        <= 0;
            start         <= 0;
        end else begin
            start <= 1'b0;  // pulso por defecto

            if (obi_req && obi_we) begin
                case (addr)
                    ADDR_ADDR_A:        addr_A        <= obi_wdata;
                    ADDR_ADDR_B:        addr_B        <= obi_wdata;
                    ADDR_ADDR_C:        addr_C        <= obi_wdata;
                    ADDR_VECTOR_A_SIZE: vector_A_size <= obi_wdata;
                    ADDR_VECTOR_B_SIZE: vector_B_size <= obi_wdata;
                    ADDR_VECTOR_C_SIZE: vector_C_size <= obi_wdata;
                    ADDR_SEL_OP:        sel_op        <= obi_wdata[1:0];
                    ADDR_START:         start         <= obi_wdata[0];
                endcase
            end
        end
    end

    // Lectura de registros
    always @(*) begin
        case (addr)
            ADDR_ADDR_A:        obi_rdata = addr_A;
            ADDR_ADDR_B:        obi_rdata = addr_B;
            ADDR_ADDR_C:        obi_rdata = addr_C;
            ADDR_VECTOR_A_SIZE: obi_rdata = vector_A_size;
            ADDR_VECTOR_B_SIZE: obi_rdata = vector_B_size;
            ADDR_VECTOR_C_SIZE: obi_rdata = vector_C_size;
            ADDR_SEL_OP:        obi_rdata = {30'b0, sel_op};
            ADDR_START:         obi_rdata = 32'd0;  // No lectura útil
            ADDR_DONE:          obi_rdata = {31'b0, done};
            default:            obi_rdata = 32'hDEADBEEF;
        endcase
    end
    
    // OBI handshake (simplificado: siempre listo)
    always @(posedge clk) begin
        if (rst) begin
            obi_gnt    <= 1'b0;
            obi_rvalid <= 1'b0;
        end else begin
            obi_gnt    <= obi_req;
            obi_rvalid <= obi_req && !obi_we;
        end
    end

endmodule
