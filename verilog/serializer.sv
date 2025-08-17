module serializer #(
    parameter IN_WIDTH  = 32,
    parameter OUT_WIDTH = 8,
    parameter SEGMENTS  = IN_WIDTH / OUT_WIDTH
)(
    input  wire                 clk,
    input  wire                 rst,
    input  wire                 start,
    input  wire [IN_WIDTH-1:0]  data_in,
    output reg                  busy,
    output reg                  done,
    output reg  [OUT_WIDTH-1:0] fifo_din,
    output reg                  wr_en,
    input  wire                 fifo_full
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

    always @(posedge clk) begin
        if (rst) state <= IDLE;
        else     state <= next_state;
    end

    always @(*) begin
        wr_en      = 0;
        fifo_din   = 0;
        busy       = (state != IDLE);
        done       = 0;
        next_state = state;

        case (state)
            IDLE: if (start) next_state = LOAD;
            LOAD: next_state = PROCESS;
            PROCESS: begin
                if (!fifo_full) begin
                    wr_en    = 1;
                    fifo_din = shift_reg[OUT_WIDTH-1:0];
                    if (segment_cnt == SEGMENTS - 1)
                        next_state = COMPLETE;
                end
            end
            COMPLETE: begin
                done = 1;
                next_state = IDLE;
            end
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            segment_cnt <= 0;
            shift_reg   <= 0;
        end else begin
            case (state)
                LOAD: begin
                    segment_cnt <= 0;
                    shift_reg   <= data_in;
                end
                PROCESS: if (!fifo_full) begin
                    shift_reg   <= shift_reg >> OUT_WIDTH;
                    segment_cnt <= segment_cnt + 1;
                end
            endcase
        end
    end

endmodule
