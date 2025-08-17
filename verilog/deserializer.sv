module deserializer #(
    parameter IN_WIDTH  = 32,
    parameter OUT_WIDTH = 8,
    parameter SEGMENTS  = IN_WIDTH / OUT_WIDTH
)(
    input  wire                 clk,
    input  wire                 rst,
    input  wire                 start,
    output reg  [IN_WIDTH-1:0]  data_out,
    output reg                  busy,
    output reg                  done,
    input  wire [OUT_WIDTH-1:0] fifo_dout,
    output reg                  rd_en,
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

    always @(posedge clk) begin
        if (rst) state <= IDLE;
        else     state <= next_state;
    end

    always @(*) begin
        rd_en      = 0;
        busy       = (state != IDLE);
        done       = 0;
        next_state = state;

        case (state)
            IDLE: if (start) next_state = LOAD;
            LOAD: next_state = PROCESS;
            PROCESS: begin
                if (!fifo_empty) begin
                    rd_en = 1;
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
            data_out    <= 0;
        end else begin
            case (state)
                LOAD: begin
                    segment_cnt <= 0;
                    data_out    <= 0;
                end
                PROCESS: if (!fifo_empty) begin
                    data_out <= data_out | ({{(IN_WIDTH-OUT_WIDTH){1'b0}}, fifo_dout} << (OUT_WIDTH * segment_cnt));
                    segment_cnt <= segment_cnt + 1;
                end
            endcase
        end
    end

endmodule
