module hdc_fsm_control #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter FIFO_DEPTH = 32,
    parameter READ_THRESHOLD = 4
)(
    //General signals
    input  logic                   clk,
    input  logic                   rst,
    
    //Operation signals
    input  logic                   start,
    input  logic [ADDR_WIDTH-1:0]  addr_A,
    input  logic [ADDR_WIDTH-1:0]  addr_B,
    input  logic [ADDR_WIDTH-1:0]  addr_C,
    input  logic [ADDR_WIDTH-1:0]  vector_A_size,
    input  logic [ADDR_WIDTH-1:0]  vector_B_size,
    input  logic [ADDR_WIDTH-1:0]  vector_C_size,
    output logic                   busy,
    output logic                   done,
    
    //OBI Master Signals
    output  reg                  obi_transference_start,         // Señal para iniciar una transacción
    output  reg                  obi_transference_rw,            // 0 = read, 1 = write
    output  reg [ADDR_WIDTH-1:0] obi_transference_addr,
    output  reg [DATA_WIDTH-1:0] obi_transference_wdata,
    input logic [DATA_WIDTH-1:0] obi_transference_rdata,
    input logic                  obi_transference_done,          // Operación finalizada
    input logic                  obi_transference_busy,          // Operación en curso
    
    //FIFOS Sizes
    input wire  [$clog2(FIFO_DEPTH):0]  fifo_A_size,
    input wire  [$clog2(FIFO_DEPTH):0]  fifo_B_size,
    input wire  [$clog2(FIFO_DEPTH):0]  fifo_C_size,

    //Fifo round robin arbiter
    output reg [2:0] fifo_data_movement_request,
    output reg  [1:0] rr_priority_base,
    input wire  [1:0] fifo_grant,
    
    //Serializador A
    output  reg                 serializer_A_start,
    output  reg [DATA_WIDTH-1:0]  serializer_A_data_in,
    input wire                  serializer_A_busy,
    input wire                  serializer_A_done,
    
    //Serializador B
    output  reg                 serializer_B_start,
    output  reg [DATA_WIDTH-1:0]  serializer_B_data_in,
    input wire                  serializer_B_busy,
    input wire                  serializer_B_done,
    
    //Deserializador C
    output  reg                 deserializer_C_start,
    input  wire [DATA_WIDTH-1:0]  deserializer_C_data_out,
    input reg                  deserializer_C_busy,
    input reg                  deserializer_C_done,
    
    //debug
    output reg [3:0] state_debug,
    output reg [2:0] fifo_debug,
    output reg [2:0] vector_finish_debug
    
    

);

    typedef enum logic [3:0] {
        IDLE,
        LOAD,
        CHECK_FIFO,
        RW_OBI,
        WAIT_OBI,
        REQUEST_SER_DES,
        SER_DES,
        WAIT_DES,
        FINISHED
    } state_t;
    
    typedef enum logic [1:0] {
        A,
        B,
        C
    } fifo_id_t;

    state_t state = IDLE, next_state = IDLE;
    fifo_id_t fifo;
    
    //Vectors memory signals
    logic [ADDR_WIDTH-1:0] counter [2:0];
    logic [ADDR_WIDTH-1:0] addr [2:0];
    logic [ADDR_WIDTH-1:0] size [2:0];
    logic vector_finish [2:0];
    
    //Señal de acceso a memoria principal
    logic data_movement;
    
    //Señal de lectura o escritura
    assign rw = (fifo == C);
    
    //Control de las señales de finalizacion
    assign vector_finish[A] = counter[A] >= size[A];
    assign vector_finish[B] = counter[B] >= size[B];
    assign vector_finish[C] = counter[C] >= size[C];

    //Data movement requests
    assign fifo_data_movement_request[0] = fifo_A_size <= READ_THRESHOLD && !vector_finish[A];
    assign fifo_data_movement_request[1] = fifo_B_size <= READ_THRESHOLD && !vector_finish[B];
    assign fifo_data_movement_request[2] = fifo_C_size >= READ_THRESHOLD && !vector_finish[C];
    assign fifo_data_movement_request[3] = 0;
    
    //Señales de estado
    assign busy = !(state == IDLE);
    assign done = (state == FINISHED);
    
    //debug
    assign state_debug = state;
    assign fifo_debug = fifo;
    assign vector_finish_debug[A] = vector_finish[A];
    assign vector_finish_debug[B] = vector_finish[B];
    assign vector_finish_debug[C] = vector_finish[C];
   
    
    always @(*) begin
        
        next_state = state;
        data_movement = |fifo_data_movement_request;
        
        obi_transference_rw = rw;

        serializer_A_start = 0;
        serializer_B_start = 0;
        deserializer_C_start = 0;

        obi_transference_start = 0;
        
        case(state)
            IDLE:
                if(start)
                    next_state = LOAD;
                    
            LOAD: begin
                next_state = CHECK_FIFO;
            end
            
            CHECK_FIFO: begin
                
                //Movimiento de datos
                if(data_movement) begin
                    if(fifo_grant==C)
                        next_state = REQUEST_SER_DES;
                    else
                        next_state = RW_OBI;
                end
                 
                 //En caso de que todas las fifos hayan terminado el siguiente estado es finalizar
                 if(vector_finish[A] && vector_finish[B] && vector_finish[C])
                    next_state = FINISHED;
            end
            
            RW_OBI: begin
                obi_transference_start = 1;

                next_state = WAIT_OBI;
            end
                
            WAIT_OBI: begin
                if(obi_transference_done) begin
                    if(fifo == C) begin
                        next_state = CHECK_FIFO;
                        
                    end else begin
                        next_state = REQUEST_SER_DES;
                        
                        //En caso de que el serializador/deserializador este libre, salta directamente a el
                        case(fifo)
                            A:
                                if(!serializer_A_busy) next_state = SER_DES;
                            B:
                                if(!serializer_B_busy) next_state = SER_DES;
                            C:
                                if(!deserializer_C_busy) next_state = SER_DES;
                        endcase
                    end
                end
            end   

            REQUEST_SER_DES: begin
                //Se mantiene en el estado hasta que el recurso esta libre
                case(fifo)
                    A:
                        if(!serializer_A_busy) next_state = SER_DES;
                    B:
                        if(!serializer_B_busy) next_state = SER_DES;
                    C:
                        if(!deserializer_C_busy) next_state = SER_DES;
                endcase
            end

            WAIT_DES:
                if(deserializer_C_done) next_state = RW_OBI;
                
            SER_DES: begin

                case (fifo)
                    A: begin
                        serializer_A_data_in = obi_transference_rdata;
                        serializer_A_start = 1;
                        next_state = CHECK_FIFO;
                    end
                    B: begin
                        serializer_B_data_in = obi_transference_rdata;
                        serializer_B_start = 1;
                        next_state = CHECK_FIFO;
                    end
                    C: begin
                        deserializer_C_start = 1;
                        next_state = WAIT_DES;
                    end
                        
                endcase
            end

            FINISHED: begin
                next_state = IDLE;
            end

        endcase
    end
    
    always_ff @(posedge clk) begin
        if (rst) begin 
            state <= IDLE;
            fifo <= A;
        end else begin
            state <= next_state;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            fifo <= A;
            rr_priority_base <= A;
            counter[A] <= 0;
            counter[B] <= 0;
            counter[C] <= 0;
            addr[A] <= 0;
            addr[B] <= 0;
            addr[C] <= 0;
            size[A] <= 0;
            size[B] <= 0;
            size[C] <= 0;
        end else begin
            case(state)
                
                LOAD: begin
                    //fifo <= fifo_id_t'(fifo_grant);
                    rr_priority_base <= A;
                    counter[A] <= 0;
                    counter[B] <= 0;
                    counter[C] <= 0;
                    addr[A] <= addr_A;
                    addr[B] <= addr_B;
                    addr[C] <= addr_C;
                    size[A] <= vector_A_size;
                    size[B] <= vector_B_size;
                    size[C] <= vector_C_size;
                end

                CHECK_FIFO: begin
                    fifo <= fifo_id_t'(fifo_grant);
                end
                
                RW_OBI: begin
                    case(fifo)
                        A: begin
                            obi_transference_addr <= addr[A];
                            addr[A] <= addr[A] + (DATA_WIDTH/8);
                            counter[A] <= counter[A] + DATA_WIDTH;
                        end
                        B: begin
                           obi_transference_addr <= addr[B];
                           addr[B] <= addr[B] + (DATA_WIDTH/8);
                           counter[B] <= counter[B] + DATA_WIDTH;
                        end
                        C: begin
                           obi_transference_addr <= addr[C];
                           obi_transference_wdata <= deserializer_C_data_out;
                           addr[C] <= addr[C] + (DATA_WIDTH/8);
                           counter[C] <= counter[C] + DATA_WIDTH;
                        end     
                    endcase
                end
                
                WAIT_OBI: begin
                    
                    if(obi_transference_done) begin
                        rr_priority_base <= fifo_grant + 1;
                    end
                end         
                    
            endcase
        end
    end
endmodule
