// ============================================================
// hdc_accelerator_obi_wrapper.sv
// ============================================================

module hdc_accelerator_obi_wrapper #(
    parameter int FIFO_DEPTH      = 32
)(
    input logic clk_i,
    input logic rst_ni,

    // --------------------------------------------------------
    // OBI slave del acelerador
    // CPU/interconnect -> HDC
    // --------------------------------------------------------
    input  obi_pkg::obi_req_t  hdc_slave_req_i,
    output obi_pkg::obi_resp_t hdc_slave_resp_o,

    // --------------------------------------------------------
    // OBI master del acelerador
    // HDC -> memoria/interconnect
    // --------------------------------------------------------
    output obi_pkg::obi_req_t  hdc_master_req_o,
    input  obi_pkg::obi_resp_t hdc_master_resp_i,

    // --------------------------------------------------------
    // Debug opcional
    // --------------------------------------------------------
    output logic       done_debug_o,
    output logic [3:0] state_debug_o
);

    // ========================================================
    // Señales planas hacia hdc_accelerator_top
    // ========================================================

    logic                  slv_obi_req;
    logic                  slv_obi_we;
    logic [31:0] slv_obi_addr;
    logic [31:0] slv_obi_wdata;
    logic [31:0] slv_obi_rdata;
    logic                  slv_obi_gnt;
    logic                  slv_obi_rvalid;

    logic                  mst_obi_req;
    logic                  mst_obi_we;
    logic [31:0] mst_obi_addr;
    logic [31:0] mst_obi_wdata;
    logic [3:0] mst_obi_be;
    logic                  mst_obi_gnt;
    logic [31:0] mst_obi_rdata;
    logic                  mst_obi_rvalid;

    // ========================================================
    // Adaptación OBI slave struct -> señales planas
    // ========================================================

    assign slv_obi_req   = hdc_slave_req_i.req;
    assign slv_obi_we    = hdc_slave_req_i.we;
    assign slv_obi_addr  = hdc_slave_req_i.addr[31:0];
    assign slv_obi_wdata = hdc_slave_req_i.wdata[31:0];

    assign hdc_slave_resp_o.gnt    = slv_obi_gnt;
    assign hdc_slave_resp_o.rvalid = slv_obi_rvalid;
    assign hdc_slave_resp_o.rdata  = slv_obi_rdata;

    // ========================================================
    // Adaptación OBI master señales planas -> struct
    // ========================================================

    assign hdc_master_req_o.req   = mst_obi_req;
    assign hdc_master_req_o.we    = mst_obi_we;
    assign hdc_master_req_o.be    = mst_obi_be;
    assign hdc_master_req_o.addr  = mst_obi_addr;
    assign hdc_master_req_o.wdata = mst_obi_wdata;

    assign mst_obi_gnt    = hdc_master_resp_i.gnt;
    assign mst_obi_rvalid = hdc_master_resp_i.rvalid;
    assign mst_obi_rdata  = hdc_master_resp_i.rdata[31:0];

    // ========================================================
    // Instancia del acelerador original
    // ========================================================

    hdc_accelerator_top #(
        .ADDR_WIDTH     (32),
        .DATA_WIDTH     (32),
        .FIFO_DEPTH     (FIFO_DEPTH),
        .FIFO_DATA_WIDTH(8)
    ) hdc_accelerator_top_i (
        .clk  (clk_i),
        .rst_n(rst_ni),

        // ----------------------------------------------------
        // Interfaz OBI esclava plana
        // ----------------------------------------------------
        .slv_obi_req_i   (slv_obi_req),
        .slv_obi_we_i    (slv_obi_we),
        .slv_obi_addr_i  (slv_obi_addr),
        .slv_obi_wdata_i (slv_obi_wdata),
        .slv_obi_rdata_o (slv_obi_rdata),
        .slv_obi_gnt_o   (slv_obi_gnt),
        .slv_obi_rvalid_o(slv_obi_rvalid),

        // ----------------------------------------------------
        // Interfaz OBI maestra plana
        // ----------------------------------------------------
        .mst_obi_req_o   (mst_obi_req),
        .mst_obi_we_o    (mst_obi_we),
        .mst_obi_addr_o  (mst_obi_addr),
        .mst_obi_wdata_o (mst_obi_wdata),
        .mst_obi_be_o    (mst_obi_be),
        .mst_obi_gnt_i   (mst_obi_gnt),
        .mst_obi_rdata_i (mst_obi_rdata),
        .mst_obi_rvalid_i(mst_obi_rvalid)
    );

endmodule