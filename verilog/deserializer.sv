module deserializer #(
    parameter IN_WIDTH  = 8,
    parameter OUT_WIDTH = 32,
    parameter SEGMENTS  = OUT_WIDTH / IN_WIDTH
)(
    input  wire                 clk,
    input  wire                 rst,
    input  wire                 start,
    output reg  [OUT_WIDTH-1:0]  data_out,
    output reg                  busy,
    output reg                  done,
    input  wire [IN_WIDTH-1:0] fifo_dout,
    output reg                  rd_en,
    input  wire                 fifo_empty,
    output wire [2:0] state_debug,
    output wire [$clog2(SEGMENTS):0] segment_cnt_debug
);

    typedef enum logic [2:0] {
        IDLE,
        LOAD,
        READY,
        PROCESS,
        COMPLETE
    } state_t;

    state_t state = IDLE, next_state = IDLE;
    
    reg [$clog2(SEGMENTS):0] segment_cnt = 0;
    reg [OUT_WIDTH-1:0] data = 0;
    
    //debug
    assign state_debug = state;
    assign segment_cnt_debug = segment_cnt;
    
    //output logic
    assign data_out = data;

    
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
            IDLE: 
                if (start) next_state = READY;
            LOAD:
                next_state = READY;
            READY: begin
                if (fifo_empty)
                    next_state = READY;
                else
                    next_state = PROCESS;
            end
            PROCESS: begin
                if (!fifo_empty) begin
                    rd_en = 1;
                    
                    if (segment_cnt == SEGMENTS - 1)
                        next_state = COMPLETE;

                end else
                    next_state = READY;
                
            end
            COMPLETE: begin
                busy = 0;
                done = 1;
                
                if(start)
                    next_state = LOAD;
                else
                    next_state = IDLE;
            end
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            segment_cnt <= 0;
            data    <= 0;
        end else begin
            case (state)
                LOAD: begin
                    segment_cnt <= 0;
                    data    <= 0;
                end
                PROCESS: if (!fifo_empty) begin
                    //data <= (data << IN_WIDTH) | fifo_dout;
                    data <= data | (fifo_dout << (IN_WIDTH * segment_cnt));
                    segment_cnt <= segment_cnt + 1;
                end
            endcase
        end
    end

endmodule
