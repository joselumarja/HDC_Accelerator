module obi_master_simulated_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter MEM_DEPTH  = 256, // Número de palabras
    parameter DELAY_CYCLES = 2  // Ciclos de retardo simulado para acceso
)(
    input  wire                     clk,
    input  wire                     rst,

    // Señales de control desde FSM
    input  wire                     start,         // Señal para iniciar una transacción
    input  wire                     rw,            // 0 = read, 1 = write
    input  wire [ADDR_WIDTH-1:0]    addr,
    input  wire [DATA_WIDTH-1:0]    wdata,
    output reg  [DATA_WIDTH-1:0]    rdata,
    output reg                      done,          // Operación finalizada
    output reg                      busy           // Operación en curso
);

    // Memoria simulada (word-addressable)
    reg [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];

    // FSM
    typedef enum logic [1:0] {
        IDLE,
        WAIT_ACCESS,
        COMPLETE
    } state_t;

    state_t state, next_state;

    // Internos
    reg [1:0] wait_cnt;
    wire [ADDR_WIDTH-3:0] word_addr; // direccion de palabra (si byte-aligned)

    assign word_addr = addr[ADDR_WIDTH-1:2]; // ignorar bits [1:0]

    integer i;

    initial begin
        //Inicializacion con patron
        for (i = 0; i < MEM_DEPTH; i = i + 1) begin
            mem[i] = 32'hFFFFFFFF; // ejemplo: contenido igual a dirección
        end

        //inicializacion con archivo
        //$readmemh("memory_init.hex", mem); // Cargar archivo hexadecimal
        //$readmemb("memory_init.bin", mem); // Para binario
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            wait_cnt <= 0;
        end else begin
            state <= next_state;

            if (state == WAIT_ACCESS)
                wait_cnt <= wait_cnt + 1;
            else
                wait_cnt <= 0;
        end
    end

    // FSM
    always_comb begin
        next_state = state;
        busy = 1'b1;
        done = 1'b0;

        case (state)
            IDLE: begin
                busy = 1'b0;
                if (start)
                    next_state = WAIT_ACCESS;
            end

            WAIT_ACCESS: begin
                if (wait_cnt == DELAY_CYCLES - 1)
                    next_state = COMPLETE;
            end

            COMPLETE: begin
                done = 1'b1;
                next_state = IDLE;
            end
        endcase
    end

    // Lógica de lectura y escritura simulada
    always_ff @(posedge clk) begin
        if (rst) begin
            rdata <= '0;
        end else begin
            if (state == WAIT_ACCESS && wait_cnt == DELAY_CYCLES - 1) begin
                if (rw == 1'b0) begin
                    rdata <= mem[word_addr];       // Read
                end else begin
                    mem[word_addr] <= wdata;       // Write
                end
            end
        end
    end

endmodule
