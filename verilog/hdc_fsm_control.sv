//NECESITA MUCHA MODIFICACION


module hdc_fsm_control #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter FIFO_DATA_WIDTH = 8,
    parameter FIFO_SIZE = 32,
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
    input  logic [ADDR_WIDTH-1:0]  vector_size,
    input  logic [ADDR_WIDTH-1:0]  vector_B_size,
    input  logic [1:0]             sel_op,
    output logic                   busy,
    output logic                   done,
    
    //OBI Master Signals
    output  logic                  obi_transference_start,         // Señal para iniciar una transacción
    output  logic                  obi_transference_rw,            // 0 = read, 1 = write
    output  logic [ADDR_WIDTH-1:0] obi_transference_addr,
    output  logic [DATA_WIDTH-1:0] obi_transference_wdata,
    input logic [DATA_WIDTH-1:0] obi_transference_rdata,
    input logic                  obi_transference_done,          // Operación finalizada
    input logic                  obi_transference_busy,          // Operación en curso
    
    //FIFOS Sizes
    input wire  [$clog2(FIFO_SIZE):0]  A_size,
    input wire  [$clog2(FIFO_SIZE):0]  B_size,
    input wire  [$clog2(FIFO_SIZE):0]  C_size,
    
    //Serializador A
    output  wire                 ser_A_start,
    output  reg [DATA_WIDTH-1:0]  ser_A_data_in,
    input wire                  ser_A_busy,
    input wire                  ser_A_done,
    
    //Serializador B
    output  wire                 ser_B_start,
    output  reg [DATA_WIDTH-1:0]  ser_B_data_in,
    input wire                  ser_B_busy,
    input wire                  ser_B_done,
    
    //Deserializador C
    output  wire                 des_C_start,
    input  wire [DATA_WIDTH-1:0]  des_C_data_out,
    input reg                  des_C_busy,
    input reg                  des_C_done
    

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
    
    typedef enum logic [2:0] {
        A,
        B,
        C
    } fifo_id_t;

    state_t state, next_state;
    fifo_id_t fifo, next_fifo;
    
    //Vectors memory signals
    logic [ADDR_WIDTH-1:0] counter [1:0];
    logic [ADDR_WIDTH-1:0] addr [1:0];
    logic [ADDR_WIDTH-1:0] size [1:0];
    logic vector_finish [1:0];
    
    
    logic data_movement;
    
    //Señal de lectura o escritura
    assign rw = (fifo == C);
    
    always @(*) begin
        
        next_state = state;
        next_fifo = fifo;
        data_movement = 0;
        
        ser_A_start = 0;
        ser_B_start = 0;
        des_C_start = 0;
        
        obi_transference_start = 0;
        obi_transference_rw = rw;
        
        busy = !(state == IDLE);
        done = 0;
        
        case(state)
            IDLE:
                if(start)
                    next_state = LOAD;
                    
            LOAD: begin
                next_state = CHECK_FIFO;
            end
            
            CHECK_FIFO: begin
                //Comprueba si las fifos han llegado al umbral de accion (r/w en memoria)
                case(fifo)
                    A:
                        data_movement = A_size <= READ_THRESHOLD;
                    B:
                        data_movement = B_size <= READ_THRESHOLD;
                    C:
                        data_movement = C_size >= READ_THRESHOLD;
                endcase
                
                //Movimiento de datos
                if(data_movement) begin
                    if(fifo==C)
                        next_state = REQUEST_SER_DES;
                    else
                        next_state = RW_OBI;
                        
                end else
                    //No hay movimiento de datos, se calcula la siguiente fifo a checkear
                    case(fifo)
                        A:
                            if(vector_finish[B]) next_fifo = C;
                            else next_fifo = B;
                        B:
                            if(vector_finish[C]) next_fifo = A;
                            else next_fifo = C;
                        C:  
                            if(vector_finish[A]) 
                                if (vector_finish[B]) next_fifo = C;
                                else next_fifo = B;
                            else next_fifo = A;
                    endcase
                 
                 //En caso de que todas las fifos hayan terminado el siguiente estado es finalizar
                 if(vector_finish[A] && vector_finish[B] && vector_finish[C])
                    next_state = FINISHED;
            end
            
            RW_OBI: begin
                next_state = WAIT_OBI;
                obi_transference_start = 0;
            end
                
            WAIT_OBI:
                if(obi_transference_done)
                    if(fifo == C) begin
                        next_state = CHECK_FIFO;
                        
                        //Calcular la siguiente fifo
                        if(vector_finish[A]) 
                            if (vector_finish[B]) next_fifo = C;
                            else next_fifo = B;
                        else next_fifo = A;
                        
                    end else begin
                        next_state = REQUEST_SER_DES;
                        
                        //En caso de que el serializador/deserializador este libre, salta directamente a el
                        case(fifo)
                            A:
                                if(!ser_A_busy) next_state = SER_DES;
                            B:
                                if(!ser_B_busy) next_state = SER_DES;
                            C:
                                if(!des_C_busy) next_state = SER_DES;
                        endcase
                    end
                    
            REQUEST_SER_DES:
                //Se mantiene en el estado hasta que el recurso esta libre
                case(fifo)
                    A:
                        if(!ser_A_busy) next_state = SER_DES;
                    B:
                        if(!ser_B_busy) next_state = SER_DES;
                    C:
                        if(!des_C_busy) next_state = SER_DES;
                endcase
                
            WAIT_DES:
                if(!des_C_busy) next_state = RW_OBI;
                
            SER_DES:begin
                
                //Señal de start a los recursos
                case(fifo)
                    A:
                        ser_A_start = 1;
                    B:
                        ser_B_start = 1;
                    C:
                        des_C_start = 1;
                endcase
                
                if(fifo==C) next_state = WAIT_DES;
                else begin
                    next_state = CHECK_FIFO;
                    
                    //Calcular siguiente fifo
                    case(fifo)
                        A:
                            if(vector_finish[B]) next_fifo = C;
                            else next_fifo = B;
                        B:
                            if(vector_finish[C]) next_fifo = A;
                            else next_fifo = C;
                    endcase
                end
            end
            FINISHED: begin
                next_state = IDLE;
                done = 1;
            end
        endcase
    end
    
    always_ff @(posedge clk) begin
        if (rst) begin 
            state <= IDLE;
            fifo <= A;
        end else begin
            state <= next_state;
            fifo <= next_fifo;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            counter[A] <= 0;
            counter[B] <= 0;
            counter[C] <= 0;
            addr[A] <= 0;
            addr[B] <= 0;
            addr[C] <= 0;
            size[A] <= 0;
            size[B] <= 0;
            size[C] <= 0;
            vector_finish[A] <= 0;
            vector_finish[B] <= 0;
            vector_finish[C] <= 0;
        end else begin
            case(state)
                
                LOAD: begin
                    counter[A] <= 0;
                    counter[B] <= 0;
                    counter[C] <= 0;
                    addr[A] <= addr_A;
                    addr[B] <= addr_B;
                    addr[C] <= addr_C;
                    size[A] <= vector_size;
                    size[B] <= vector_B_size;
                    size[C] <= vector_size;
                    vector_finish[A] <= 0;
                    vector_finish[B] <= 0;
                    vector_finish[C] <= 0;
                end
                
                RW_OBI: begin
                    case(fifo)
                        A: begin
                            obi_transference_addr <= addr[A];
                            addr[A] <= addr[A] + 1; //REVISAR DE CUANTO SON LOS SALTOS DE MEMORIA EN LAS DIRECCIONES
                            counter[A] <= counter[A] + DATA_WIDTH;
                        end
                        B: begin
                           obi_transference_addr <= addr[B];
                           addr[A] <= addr[B] + 1; //REVISAR DE CUANTO SON LOS SALTOS DE MEMORIA EN LAS DIRECCIONES
                           counter[B] <= counter[B] + DATA_WIDTH;
                        end
                        C: begin
                           obi_transference_addr <= addr[C];
                           obi_transference_wdata <= des_C_data_out;
                           addr[C] <= addr[C] + 1; //REVISAR DE CUANTO SON LOS SALTOS DE MEMORIA EN LAS DIRECCIONES
                           counter[C] <= counter[C] + DATA_WIDTH;
                        end     
                    endcase
                end         
                
                SER_DES: begin
                    case (fifo)
                        A:
                            ser_A_data_in <= obi_transference_rdata;
                        B:
                            ser_B_data_in <= obi_transference_rdata;
                    endcase
                end
                    
            endcase
        end
    end
endmodule
