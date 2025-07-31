module hdc_peripheral#(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter FIFO_WIDTH = 8,
    parameter FIFO_SIZE = 64
)(
    input logic clk,
    input logic rst,

    // OBI slave interface
    input logic slv_obi_req_i,
    input logic [ADDR_WIDTH-1:0] slv_obi_addr_i,
    input logic slv_obi_we_i,
    input logic slv_obi_be_i,
    input logic [DATA_WIDTH-1:0] slv_obi_wdata_i,
    output  logic slv_obi_gnt_o,
    output  logic [DATA_WIDTH-1:0] slv_obi_rdata_o,
    output  logic slv_obi_rvalid_o,

    // OBI master interface
    output logic mst_obi_req_o,
    output logic [ADDR_WIDTH-1:0] mst_obi_addr_o,
    output logic mst_obi_we_o,
    output logic mst_obi_be_o,
    output logic [DATA_WIDTH-1:0] mst_obi_wdata_o,
    input  logic mst_obi_gnt_i,
    input  logic [DATA_WIDTH-1:0] mst_obi_rdata_i,
    input  logic mst_obi_rvalid_i,
);

local param SLAVE_ADDRESS 32'h0000_0001;

//ALL COMPONENTS INTERCONECTION LOGIC

endmodule