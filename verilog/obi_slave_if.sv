module obi_slave_if #(
    parameter ADDR_WIDTH,
    parameter DATA_WIDTH
)(
    input  logic                  clk,
    input  logic                  rst,

    // OBI slave interface
    input  logic                  slv_obi_req_i,
    input  logic [ADDR_WIDTH-1:0] slv_obi_addr_i,
    input  logic                  slv_obi_we_i,
    input  logic [DATA_WIDTH/8-1:0] slv_obi_be_i,
    input  logic [DATA_WIDTH-1:0] slv_obi_wdata_i,
    output logic                  slv_obi_gnt_o,
    output logic [DATA_WIDTH-1:0] slv_obi_rdata_o,
    output logic                  slv_obi_rvalid_o,

    // Registro de configuración (salida)
    output logic [ADDR_WIDTH-1:0] addr_A,
    output logic [ADDR_WIDTH-1:0] addr_B,
    output logic [ADDR_WIDTH-1:0] addr_C,
    output logic [ADDR_WIDTH-1:0] vector_size,
    output logic        start,

    // Flags de control (entrada)
    input  logic        busy,
    input  logic        done
);

    logic start_reg;

    // Escritura de registros
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_A      <= ADDR_WIDTH'd0;
            addr_B      <= ADDR_WIDTH'd0;
            addr_C      <= ADDR_WIDTH'd0;
            vector_size <= ADDR_WIDTH'd0;
            start_reg   <= 1'b0;
        end else if (slv_obi_req_i && slv_obi_we_i) begin
            unique case (slv_obi_addr_i[5:2])
                4'h0: addr_A      <= slv_obi_wdata_i;
                4'h1: addr_B      <= slv_obi_wdata_i;
                4'h2: addr_C      <= slv_obi_wdata_i;
                4'h3: vector_size <= slv_obi_wdata_i;
                4'h4: start_reg   <= slv_obi_wdata_i[0];
            endcase
        end else if (done) begin
            start_reg <= 1'b0;
        end
    end

    assign start = start_reg;

    // Lectura de registros
    always_ff @(posedge clk) begin
        if (slv_obi_req_i && !slv_obi_we_i) begin
            unique case (slv_obi_addr_i[5:2])
                4'h0: slv_obi_rdata_o <= addr_A;
                4'h1: slv_obi_rdata_o <= addr_B;
                4'h2: slv_obi_rdata_o <= addr_C;
                4'h3: slv_obi_rdata_o <= {DATA_WIDTH'd0, vector_size};
                4'h4: slv_obi_rdata_o <= {DATA_WIDTH'd0, start_reg};
                4'h5: slv_obi_rdata_o <= {DATA_WIDTH'd0, busy};
                4'h6: slv_obi_rdata_o <= {DATA_WIDTH'd0, done};
                default: slv_obi_rdata_o <= DATA_WIDTH'hFFFFFFFF;
            endcase
        end
    end

    // REVISAR ESTO
    assign slv_obi_gnt_o    = slv_obi_req_i;
    assign slv_obi_rvalid_o = slv_obi_req_i && !slv_obi_we_i;

endmodule
