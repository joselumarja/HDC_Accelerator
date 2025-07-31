module serdes #(
    parameter IN_WIDTH  = 32,
    parameter OUT_WIDTH = 8,
    parameter SEGMENTS  = IN_WIDTH / OUT_WIDTH
)(
    input  wire                 clk,
    input  wire                 rst,
    input  wire                 start,         // Lanza operación
    input  wire                 is_write,      // 1: escribir/serializar, 0: leer/deserializar

    // Interfaz de datos paralelos
    input  wire [IN_WIDTH-1:0]  data_in,       // Solo válido si is_write = 1
    output reg  [IN_WIDTH-1:0]  data_out,      // Solo válido si is_write = 0
    output reg                  busy,          // Operación en curso
    output reg                  done,          // Operación finalizada

    // Interfaz FIFO
    output reg  [OUT_WIDTH-1:0] fifo_din,
    input  wire [OUT_WIDTH-1:0] fifo_dout,
    output reg                  wr_en,
    output reg                  rd_en,
    input  wire                 fifo_full,
    input  wire                 fifo_empty
);

    typedef enum logic [1:0] {
        IDLE,
        LOAD,
        PROCESS,
        COMPLETE
    } state_t;

    state_t state, next_state;

    reg [$clog2(SEGMENTS):0] segment_cnt;
    reg [IN_WIDTH-1:0] shift_reg;

    // Estado de la FSM
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Transiciones de la FSM
    always @(*) begin
        // Defaults
        wr_en      = 0;
        rd_en      = 0;
        fifo_din   = 0;
        busy       = (state != IDLE);
        done       = 0;
        next_state = state;

        case (state)
            IDLE: begin
                if (start)
                    next_state = LOAD;
            end

            LOAD: begin
                next_state = PROCESS;
            end

            PROCESS: begin
                if (is_write) begin
                    if (!fifo_full) begin
                        wr_en    = 1;
                        fifo_din = shift_reg[OUT_WIDTH-1:0];
                    end
                    if (!fifo_full && segment_cnt == SEGMENTS - 1)
                        next_state = COMPLETE;
                end else begin
                    if (!fifo_empty) begin
                        rd_en = 1;
                    end
                    if (!fifo_empty && segment_cnt == SEGMENTS - 1)
                        next_state = COMPLETE;
                end
            end

            COMPLETE: begin
                done = 1;
                next_state = IDLE;
            end
        endcase
    end

    // Datos y contador
    always @(posedge clk) begin
        if (rst) begin
            segment_cnt <= 0;
            shift_reg   <= 0;
            data_out    <= 0;
        end else begin
            case (state)
                LOAD: begin
                    segment_cnt <= 0;
                    shift_reg   <= data_in;
                end

                PROCESS: begin
                    if (is_write && !fifo_full) begin
                        shift_reg   <= shift_reg >> OUT_WIDTH;
                        segment_cnt <= segment_cnt + 1;
                    end else if (!is_write && !fifo_empty) begin
                        data_out    <= data_out | ({{(IN_WIDTH-OUT_WIDTH){1'b0}}, fifo_dout} << (OUT_WIDTH * segment_cnt));
                        segment_cnt <= segment_cnt + 1;
                    end
                end
            endcase
        end
    end

endmodule
